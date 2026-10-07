-- /lua/mlamkadm/core/workspace.lua
-- Terminal Workspaces backed by an invisible tmux daemon.
--
-- Architecture:
--   * A "workspace" is a named group of terminal instances. Each workspace
--     maps 1:1 to a headless tmux session; each terminal instance is a tmux
--     window inside it. nvim floats only ever run `tmux attach-session`,
--     so the tmux server (the daemon) owns every process. nvim exit or a
--     closed float merely detaches — processes survive.
--   * Kill semantics are real: kill_window/kill_workspace first collect the
--     process groups (pgid) behind each pane, then tear the tmux object
--     down, then SIGKILL any surviving group. Nothing zombies.
--   * Smart resurrect: the journal is *live-synced* from tmux on save
--     (window name + pane_start_command + pane_current_path per window), so
--     a dead workspace resurrects exactly what was actually running — even
--     windows created manually inside tmux. Live sessions are never touched
--     by resurrect; live truth always wins.
--
-- Layering: this module is pure model + tmux CLI. It never imports the
-- terminal float UI (mlamkadm.core.terminal). terminal.lua orchestrates us.

local M = {}

-- ----------------------------------------------------------------------------
-- Configuration
-- ----------------------------------------------------------------------------
local config = {
    -- Every session we own is prefixed with this, so namespace-scoped
    -- kills and listings never touch the user's own tmux sessions.
    namespace = "nvim-",
    -- Journal: one JSON per project (keyed by cwd hash), stdpath("data").
    journal_dir = nil, -- defaults to stdpath("data") .. "/term_workspaces"
    -- tmux copy-mode scrollback per pane (nvim buffer scrollback is separate).
    history_limit = 50000,
    -- Rigid kill: grace (seconds) between tmux teardown and the SIGKILL sweep.
    kill_grace = 0,
}

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
-- Journal cache: { version, cwd, last_active, workspaces = { {name, session, terms = {...}} } }
local journal_cache = nil
local journal_loaded = false
-- Name of the currently fronted workspace (display name, e.g. "primary").
local active_ws_name = nil

-- ----------------------------------------------------------------------------
-- Small helpers
-- ----------------------------------------------------------------------------
-- Run a command via argv list (no shell, no escaping bugs). Returns
-- { ok = bool, out = string }.
local function run(argv)
    local ok, out = pcall(vim.fn.system, argv)
    if not ok then
        return { ok = false, out = "" }
    end
    local rc = vim.v.shell_error
    -- has-session exit 1 on "no server running" is normal, not an error state.
    return { ok = rc == 0, out = out or "", rc = rc }
end

local function lines_of(str)
    local t = {}
    for line in (str or ""):gmatch("[^\r\n]+") do
        table.insert(t, line)
    end
    return t
end

local function trim(s)
    return ((s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Sanitize a string for use as a tmux *session* name: [%w-] only
--- (dots/colons/brackets all interfere with tmux target parsing).
local function safe_session_name(s)
    s = (s or ""):gsub("[^%w%-]", "-"):gsub("%-+", "-"):gsub("^%-+", "")
    if s == "" then
        s = "ws"
    end
    return s
end

--- Sanitize a string for use as a tmux *window* name (our singleton key).
--- Window names may contain dots and dashes, but no colons.
local function safe_window_name(s)
    s = (s or ""):gsub("[^%w%._%-]", "-"):gsub("%-+", "-"):gsub("^%-+", "")
    if s == "" then
        s = "term"
    end
    return s:sub(1, 24)
end

--- The project-unique session name for a workspace display name.
--- Mirrors the legacy zellij scheme (nvim-<proj>-<hash>) so the mental model
--- and per-project keying stay identical.
function M.project_session_name(ws_name)
    local cwd = vim.fn.getcwd()
    local proj = vim.fn.fnamemodify(cwd, ":t")
    if proj == "" then
        proj = "home"
    end
    proj = safe_session_name(proj)
    local hash = vim.fn.sha256(cwd):sub(1, 8)
    local base = config.namespace .. proj .. "-" .. hash
    ws_name = safe_session_name(ws_name or "")
    if ws_name == "" or ws_name == "primary" then
        return base
    end
    return base .. "-" .. ws_name
end

--- Session name for a terminal instance (flat registry — the OLD terminal
--- model: one session per terminal). The "-term-" marker keeps them out of
--- the workspace feature's pickers and kills.
function M.terminal_session_name(key)
    local cwd = vim.fn.getcwd()
    local proj = vim.fn.fnamemodify(cwd, ":t")
    if proj == "" then
        proj = "home"
    end
    proj = safe_session_name(proj)
    local hash = vim.fn.sha256(cwd):sub(1, 8)
    return config.namespace .. proj .. "-" .. hash .. "-term-" .. safe_session_name(key)
end

-- ----------------------------------------------------------------------------
-- tmux adapter
-- ----------------------------------------------------------------------------
local tmux = {}

function tmux.available()
    return vim.fn.executable("tmux") == 1
end

function tmux.session_exists(sess)
    local r = run({ "tmux", "has-session", "-t", "=" .. sess })
    return r.ok
end

--- List sessions in our namespace. Returns array of names.
function tmux.list_sessions()
    local r = run({ "tmux", "list-sessions", "-F", "#{session_name}" })
    if not r.ok then
        return {}
    end
    local out = {}
    for _, line in ipairs(lines_of(r.out)) do
        if vim.startswith(line, config.namespace) then
            table.insert(out, line)
        end
    end
    return out
end

--- Idempotent server/session option setup applied to every session we own.
local function session_opts(sess)
    run({ "tmux", "set-option", "-q", "-t", "=" .. sess, "status", "off" })
    run({ "tmux", "set-option", "-q", "-t", "=" .. sess, "escape-time", "10" })
    run({ "tmux", "set-option", "-q", "-t", "=" .. sess, "mouse", "on" })
    run({ "tmux", "set-option", "-q", "-t", "=" .. sess, "remain-on-exit", "off" })
    run({ "tmux", "set-option", "-q", "-t", "=" .. sess, "detach-on-destroy", "on" })
    -- Sensible server-wide defaults (idempotent; only our daemon anyway).
    run({ "tmux", "set-option", "-q", "-g", "default-terminal", "tmux-256color" })
    run({ "tmux", "set-option", "-q", "-g", "history-limit", tostring(config.history_limit) })
    -- The operator's shell expects this (see its own "extended-keys is off"
    -- warning); keeps Enter/modified keys working inside our panes.
    run({ "tmux", "set-option", "-q", "-g", "extended-keys", "on" })
end

--- Create a session headless. `first` = optional first window:
--- { name = w, cwd = dir, cmd = string or nil (shell) }. A session always
--- gets a locked-name first window (default "main" shell) so the journal
--- never sees an auto-renamed, start_command-less drifter.
local function create_session(sess, first)
    first = first or {}
    if not first.name then
        first.name = "main"
    end
    if not first.cwd or first.cwd == "" then
        first.cwd = vim.fn.getcwd()
    end
    local argv = { "tmux", "new-session", "-d", "-s", sess }
    if first.cwd then
        table.insert(argv, "-c")
        table.insert(argv, first.cwd)
    end
    if first.name then
        table.insert(argv, "-n")
        table.insert(argv, first.name)
    end
    if first.cmd and first.cmd ~= "" then
        table.insert(argv, first.cmd)
    end
    local r = run(argv)
    if not r.ok then
        return false
    end
    session_opts(sess)
    -- Lock the first window's name too, so journal keys never drift.
    if first.name then
        run({ "tmux", "set-window-option", "-q", "-t", "=" .. sess .. ":" .. first.name, "automatic-rename", "off" })
        run({ "tmux", "set-window-option", "-q", "-t", "=" .. sess .. ":" .. first.name, "allow-rename", "off" })
    end
    return true
end

--- List windows of a session (live truth). Each entry:
--- { index, name, active, cmd, cwd }
function tmux.windows(sess)
    local fmt = "#{window_index}|||#{window_name}|||#{window_active}|||#{pane_start_command}|||#{pane_current_path}"
    local r = run({ "tmux", "list-windows", "-t", "=" .. sess, "-F", fmt })
    if not r.ok then
        return {}
    end
    local out = {}
    for _, line in ipairs(lines_of(r.out)) do
        local index, name, active, cmd, cwd = line:match("^(.-)|||(.-)|||(.-)|||(.-)|||(.-)$")
        if index then
            table.insert(out, {
                index = tonumber(index) or 0,
                name = name,
                active = active == "1",
                cmd = trim(cmd),
                cwd = trim(cwd),
            })
        end
    end
    return out
end

function tmux.select_window(sess, name)
    return run({ "tmux", "select-window", "-t", "=" .. sess .. ":" .. name }).ok
end

function tmux.next_window(sess)
    return run({ "tmux", "next-window", "-t", "=" .. sess }).ok
end

function tmux.prev_window(sess)
    return run({ "tmux", "previous-window", "-t", "=" .. sess }).ok
end

--- Create a window. Locks the name (no auto-rename) so it stays a stable
--- singleton key. `cmd` nil/empty = interactive shell.
local function create_window(sess, name, cwd, cmd)
    local argv = { "tmux", "new-window", "-t", "=" .. sess, "-n", name }
    if cwd and cwd ~= "" then
        table.insert(argv, "-c")
        table.insert(argv, cwd)
    end
    if cmd and cmd ~= "" then
        table.insert(argv, cmd)
    end
    if not run(argv).ok then
        return nil
    end
    -- Lock the name: apps/shells must not be able to rename our key away.
    run({ "tmux", "set-window-option", "-q", "-t", "=" .. sess .. ":" .. name, "automatic-rename", "off" })
    run({ "tmux", "set-window-option", "-q", "-t", "=" .. sess .. ":" .. name, "allow-rename", "off" })
    -- new-window selects it in the session; an attached client follows.
    return name
end

-- ----------------------------------------------------------------------------
-- Rigid kill: collect process groups, tear down tmux object, SIGKILL strays
-- ----------------------------------------------------------------------------
-- A terminal instance must die WITH its process tree. tmux teardown sends
-- SIGHUP via pty close, but a process that ignores HUP would survive as an
-- orphan. We therefore record each pane's process group first, then verify:
-- any group still alive after teardown gets SIGKILL'd. This is the
-- "actually KILL workspaces along with their term instances" guarantee.

--- pgids (process group ids) behind every pane of every window in a
--- session. Window-exhaustive: misses nothing, splits included.
local function session_pgids(sess)
    local pgids = {}
    for _, w in ipairs(tmux.windows(sess)) do
        local r = run({ "tmux", "list-panes", "-t", "=" .. sess .. ":" .. w.name, "-F", "#{pane_pid}" })
        if r.ok then
            for _, line in ipairs(lines_of(r.out)) do
                local pid = tonumber(trim(line))
                if pid and pid > 0 then
                    local g = run({ "sh", "-c", "ps -o pgid= -p " .. pid .. " 2>/dev/null" })
                    local pgid = tonumber(trim(g.out))
                    if pgid and pgid > 0 then
                        pgids[pgid] = true
                    end
                end
            end
        end
    end
    return pgids
end

--- pgids behind every pane of ONE window.
local function window_pgids(sess, name)
    local pgids = {}
    local r = run({ "tmux", "list-panes", "-t", "=" .. sess .. ":" .. name, "-F", "#{pane_pid}" })
    if not r.ok then
        return pgids
    end
    for _, line in ipairs(lines_of(r.out)) do
        local pid = tonumber(trim(line))
        if pid and pid > 0 then
            local g = run({ "sh", "-c", "ps -o pgid= -p " .. pid .. " 2>/dev/null" })
            local pgid = tonumber(trim(g.out))
            if pgid and pgid > 0 then
                pgids[pgid] = true
            end
        end
    end
    return pgids
end

local function group_alive(pgid)
    -- kill -0 -PGID: rc 0 while any member of the group exists.
    return run({ "sh", "-c", "kill -0 -" .. pgid .. " 2>/dev/null" }).ok
end

local function sigkill_groups(pgids)
    local swept = 0
    for pgid in pairs(pgids) do
        if group_alive(pgid) then
            run({ "sh", "-c", "kill -9 -" .. pgid .. " 2>/dev/null" })
            swept = swept + 1
        end
    end
    return swept
end

function tmux.kill_window(sess, name)
    local pgids = window_pgids(sess, name)
    run({ "tmux", "kill-window", "-t", "=" .. sess .. ":" .. name })
    sigkill_groups(pgids)
end

function tmux.kill_session(sess)
    local pgids = session_pgids(sess)
    run({ "tmux", "kill-session", "-t", "=" .. sess })
    return sigkill_groups(pgids)
end

-- Attach command for a termopen job. Runs via sh so we can unset TMUX
-- (nvim may itself be running inside tmux; nesting protection would refuse).
function M.attach_cmd(sess)
    return { "sh", "-c", "exec env -u TMUX tmux attach-session -t =" .. sess }
end

-- ----------------------------------------------------------------------------
-- Journal (persistence + smart resurrect)
-- ----------------------------------------------------------------------------
local J = {}

local function journal_dir()
    return config.journal_dir or (vim.fn.stdpath("data") .. "/term_workspaces")
end

local function project_key()
    return vim.fn.sha256(vim.fn.getcwd()):sub(1, 8)
end

local function journal_path()
    return journal_dir() .. "/" .. project_key() .. ".json"
end

--- Legacy (zellij era) journal paths for this cwd, if any.
local function legacy_paths()
    local old_dir = vim.fn.stdpath("data") .. "/term_sessions"
    local encoded = vim.fn.getcwd():gsub("/", "%%") .. ".json"
    return {
        old_dir .. "/" .. encoded,
        vim.fn.stdpath("data") .. "/terminal_session.json",
    }
end

local function default_journal()
    return {
        version = 3,
        cwd = vim.fn.getcwd(),
        -- Flat terminal registry (the old terminal.lua model): each terminal
        -- instance is its own daemon session.
        terminals = {},
        last_active_terminal = nil,
        -- Workspace ("synced terminals") feature.
        last_active = "primary",
        workspaces = {
            { name = "primary", session = M.project_session_name("primary"), terms = {} },
        },
    }
end

local function ensure_journal_dir()
    local d = journal_dir()
    if vim.fn.isdirectory(d) == 0 then
        vim.fn.mkdir(d, "p")
    end
end

--- One-shot migration from the zellij-era journal: zellij attach commands
--- are dropped (the old sessions are not coming back); everything else was a
--- registry terminal instance, so it becomes one. Old files kept as .bak.
local function migrate_legacy()
    local j = default_journal()
    for _, path in ipairs(legacy_paths()) do
        local f = io.open(path, "r")
        if f then
            local content = f:read("*a")
            f:close()
            local ok, decoded = pcall(vim.json.decode, content)
            if ok and type(decoded) == "table" then
                local entries = decoded.terminals or decoded
                if type(entries) == "table" then
                    for _, e in ipairs(entries) do
                        if type(e) == "table" and e.cmd and e.cmd ~= "" then
                            if not vim.startswith(e.cmd, "zellij") then
                                local key = safe_window_name(e.cmd)
                                table.insert(j.terminals, {
                                    key = key,
                                    cmd = e.cmd,
                                    session = M.terminal_session_name(key),
                                    cwd = vim.fn.getcwd(),
                                    position = (type(e.opts) == "table" and e.opts.position) or nil,
                                    title = nil,
                                    is_open = e.is_open == true,
                                })
                            end
                        end
                    end
                end
            end
            -- Keep the old file for inspection; the new format owns the truth.
            pcall(os.rename, path, path .. ".bak")
        end
    end
    return j
end

function J.load()
    if journal_loaded then
        return journal_cache
    end
    journal_loaded = true
    ensure_journal_dir()
    local path = journal_path()
    local f = io.open(path, "r")
    if not f then
        journal_cache = migrate_legacy()
        J.save(journal_cache)
        return journal_cache
    end
    local content = f:read("*a")
    f:close()
    local ok, decoded = pcall(vim.json.decode, content)
    if not ok or type(decoded) ~= "table" or not decoded.workspaces then
        journal_cache = migrate_legacy()
        J.save(journal_cache)
        return journal_cache
    end
    -- v2 (workspace-only) journals gain the v3 terminal fields in place.
    decoded.terminals = decoded.terminals or {}
    decoded.last_active_terminal = decoded.last_active_terminal or nil
    decoded.last_active = decoded.last_active or "primary"
    decoded.cwd = decoded.cwd or vim.fn.getcwd()
    journal_cache = decoded
    if not journal_cache.workspaces or #journal_cache.workspaces == 0 then
        journal_cache = default_journal()
    end
    return journal_cache
end

--- Atomic write: tmp file + rename (same filesystem → atomic replace).
function J.save(data)
    journal_cache = data
    journal_loaded = true
    ensure_journal_dir()
    local path = journal_path()
    local tmp = path .. ".tmp"
    local f = io.open(tmp, "w")
    if not f then
        return false
    end
    f:write(vim.json.encode(data))
    f:close()
    return os.rename(tmp, path)
end

local function find_ws(j, name)
    for _, ws in ipairs(j.workspaces) do
        if ws.name == name then
            return ws
        end
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- Live-sync: the journal's terms mirror what tmux is actually running
-- ----------------------------------------------------------------------------
--- Rebuild ws.terms from the live session windows (name/cmd/cwd). Dead
--- sessions keep their saved terms — that IS the resurrect recipe.
--- NOTE: tmux emits pane_start_command shell-quoted when it contains
--- spaces (e.g. '"sleep 400"'), so strip the wrapping pair before storing —
--- otherwise the respawn would run `sh -c '"sleep 400"'` and die instantly.
local function sync_terms(ws)
    if not tmux.session_exists(ws.session) then
        return
    end
    local terms = {}
    for _, w in ipairs(tmux.windows(ws.session)) do
        local cmd = w.cmd
        if cmd ~= "" then
            cmd = cmd:match('^"(.*)"$') or cmd
        end
        table.insert(terms, {
            name = w.name,
            cmd = (cmd ~= "" and cmd) or vim.o.shell,
            cwd = (w.cwd ~= "" and w.cwd) or vim.fn.getcwd(),
        })
    end
    ws.terms = terms
end

--- Persist current truth: sync every live workspace from tmux, then write.
function M.save()
    if not tmux.available() then
        return
    end
    local j = J.load()
    for _, ws in ipairs(j.workspaces) do
        sync_terms(ws)
    end
    j.last_active = active_ws_name or j.last_active or "primary"
    j.cwd = vim.fn.getcwd()
    J.save(j)
end

-- ----------------------------------------------------------------------------
-- Workspace operations
-- ----------------------------------------------------------------------------

--- Ensure the workspace exists (journal record + live session). A dead
--- session is resurrected by respawning its journal terms; a LIVE session is
--- never touched (live truth wins).
-- @return ws record { name, session, terms }
function M.ensure(name)
    local j = J.load()
    local ws = find_ws(j, name) or { name = name, session = M.project_session_name(name), terms = {} }
    if not find_ws(j, name) then
        table.insert(j.workspaces, ws)
    end
    if not tmux.session_exists(ws.session) then
        -- Dead: create the session and respawn every journal term.
        local first = ws.terms[1]
        if first then
            create_session(ws.session, {
                name = first.name,
                cwd = first.cwd,
                cmd = first.cmd,
            })
            for i = 2, #ws.terms do
                local t = ws.terms[i]
                create_window(ws.session, t.name, t.cwd, t.cmd)
            end
        else
            create_session(ws.session) -- locked "main" shell window
        end
        session_opts(ws.session)
    end
    active_ws_name = ws.name
    return ws
end

--- All workspaces for this project (journal ∪ live namespace sessions).
--- Terminal-instance sessions ("-term-" marker) are excluded — they are
--- managed by the flat terminal registry, not the workspace feature.
--- Each entry: { name, session, live = bool, n_windows = int }
function M.list()
    local j = J.load()
    local out = {}
    local seen = {}
    for _, ws in ipairs(j.workspaces) do
        local live = tmux.session_exists(ws.session)
        local n = live and #tmux.windows(ws.session) or 0
        table.insert(out, { name = ws.name, session = ws.session, live = live, n_windows = n })
        seen[ws.session] = true
    end
    -- Live namespace sessions not known to the journal (e.g. created from
    -- another machine path or an old journal wiped) — surface them too,
    -- except flat terminal instances.
    for _, sess in ipairs(tmux.list_sessions()) do
        if not seen[sess] and not sess:find("-term-", 1, true) then
            table.insert(out, {
                name = sess,
                session = sess,
                live = true,
                n_windows = #tmux.windows(sess),
            })
        end
    end
    return out
end

--- Open (or focus) a terminal window in a workspace. With opts.key this is
--- the singleton contract: an existing window with that key is selected
--- instead of spawning a duplicate. With opts.once, always create a fresh
--- window (no singleton lookup) — e.g. the <C-n> "new terminal" action.
-- @param ws_name string workspace display name
-- @param cmd string command to run ("" = shell)
-- @param opts { key = singleton window key, cwd = working dir, once = bool }
-- @return { name = window name, created = bool } or nil on failure
function M.open_window(ws_name, cmd, opts)
    opts = opts or {}
    local ws = M.ensure(ws_name)
    cmd = cmd or vim.o.shell
    local key = safe_window_name(opts.key or cmd)
    local cwd = opts.cwd or vim.fn.getcwd()

    if not opts.once then
        for _, w in ipairs(tmux.windows(ws.session)) do
            if w.name == key then
                tmux.select_window(ws.session, key)
                return { name = key, created = false }
            end
        end
    end

    -- Resolve a name collision between distinct commands (same base name,
    -- different key) by suffixing -2, -3, …
    local name = key
    local existing = {}
    for _, w in ipairs(tmux.windows(ws.session)) do
        existing[w.name] = true
    end
    local n = 1
    while existing[name] do
        n = n + 1
        name = key .. "-" .. n
    end

    if not create_window(ws.session, name, cwd, cmd) then
        return nil
    end
    M.save()
    return { name = name, created = true }
end

--- Cycle the session's current window forward/backward.
function M.cycle(ws_name, dir)
    local ws = find_ws(J.load(), ws_name)
    if not ws or not tmux.session_exists(ws.session) then
        return false
    end
    if dir == "prev" then
        return tmux.prev_window(ws.session)
    end
    return tmux.next_window(ws.session)
end

--- Kill ONE terminal window (process group enforced). Returns true if the
--- workspace session died with it (last window).
function M.kill_window(ws_name, win_name)
    local ws = find_ws(J.load(), ws_name)
    if not ws or not tmux.session_exists(ws.session) then
        return false
    end
    tmux.kill_window(ws.session, win_name)
    local session_dead = not tmux.session_exists(ws.session)
    if session_dead then
        -- Last window: workspace dies with it.
        M.remove(ws_name)
    else
        M.save()
    end
    return session_dead
end

--- Kill a workspace: SIGTERM (tmux teardown) then SIGKILL sweep of every
--- process group, journal entry removed. True kill — nothing respawns.
function M.remove(ws_name)
    local j = J.load()
    local ws = find_ws(j, ws_name)
    local swept = 0
    if ws and tmux.session_exists(ws.session) then
        swept = tmux.kill_session(ws.session)
    end
    local kept = {}
    for _, w in ipairs(j.workspaces) do
        if w.name ~= ws_name then
            table.insert(kept, w)
        end
    end
    j.workspaces = kept
    if active_ws_name == ws_name then
        active_ws_name = #kept > 0 and kept[1].name or nil
    end
    if j.last_active == ws_name then
        -- Never leave last_active pointing at the corpse — active_name()
        -- would otherwise resurrect it via ensure().
        j.last_active = #kept > 0 and kept[1].name or nil
    end
    J.save(j)
    return swept
end

--- Kill ALL workspaces: every namespace session torn down (rigid) and every
--- project journal purged. Global clean slate — same contract the old alpha
--- dashboard button had with zellij, but it actually kills the processes.
--- Every namespace session belonging to THIS project (its base prefix:
--- the primary workspace session name, under which workspaces and terminal
--- instances live). Machine-global by default is a live grenade when any
--- other nvim / pi instance owns sessions in the namespace.
function M.project_sessions()
    local base = M.project_session_name("primary") -- exactly the base name
    local out = {}
    for _, sess in ipairs(tmux.list_sessions()) do
        if vim.startswith(sess, base) then
            table.insert(out, sess)
        end
    end
    return out
end

--- Kill workspaces + terminal instances. PROJECT-SCOPED by default: only
--- this project's sessions and journal die — other projects' terminals
--- (including any live pi/agent sessions) survive. opts.all = true gives
--- the old machine-wide clean slate (every namespace session + journal).
function M.kill_all(opts)
    opts = opts or {}
    local targets
    if opts.all then
        targets = tmux.list_sessions()
    else
        targets = M.project_sessions()
    end

    local n = 0
    for _, sess in ipairs(targets) do
        tmux.kill_session(sess)
        n = n + 1
    end

    -- Purge journals so nothing resurrects — scoped like the kills.
    if opts.all then
        local dir = journal_dir()
        for _, f in ipairs(vim.fn.readdir(dir) or {}) do
            if vim.endswith(f, ".json") then
                pcall(os.remove, dir .. "/" .. f)
            end
        end
    else
        pcall(os.remove, journal_path())
    end

    journal_cache = nil
    journal_loaded = false
    active_ws_name = nil
    return n
end

--- Resurrect: ensure every journal workspace has a live session (respawning
--- dead ones from the recipe), set the active workspace from the journal,
--- and return the active ws record. Called on session-restore.
function M.resurrect()
    local j = J.load()
    local target = j.last_active or "primary"
    if not find_ws(j, target) then
        target = (j.workspaces and j.workspaces[1] and j.workspaces[1].name) or "primary"
    end
    for _, ws in ipairs(j.workspaces) do
        if not tmux.session_exists(ws.session) then
            M.ensure(ws.name)
        end
    end
    return M.ensure(target)
end

--- Active workspace record (creating if needed).
function M.active()
    return M.ensure(active_ws_name or J.load().last_active or "primary")
end

function M.active_name()
    return (M.active()).name
end

function M.set_active(name)
    active_ws_name = name
    local j = J.load()
    j.last_active = name
    J.save(j)
end

--- Windows of a workspace (live truth), for pickers / dots bar / counts.
function M.windows(ws_name)
    local ws = find_ws(J.load(), ws_name)
    if not ws or not tmux.session_exists(ws.session) then
        return {}
    end
    return tmux.windows(ws.session)
end

--- Session name for a workspace display name (creating the journal record).
function M.session_of(ws_name)
    return (M.ensure(ws_name)).session
end

--- Peek at a workspace record WITHOUT creating anything.
-- @return { name, session, live } or nil if unknown to the journal.
function M.lookup(ws_name)
    local j = J.load()
    for _, ws in ipairs(j.workspaces) do
        if ws.name == ws_name then
            return { name = ws.name, session = ws.session, live = tmux.session_exists(ws.session) }
        end
    end
    return nil
end

--- Count of live workspace sessions in the namespace (statusline widget).
function M.live_session_count()
    return #tmux.list_sessions()
end

-- ----------------------------------------------------------------------------
-- Flat terminal registry (OLD terminal.lua model: one session per terminal)
-- ----------------------------------------------------------------------------

--- Ensure a terminal instance session exists (respawning a dead one from
--- its recipe — that IS smart resurrect for a singleton terminal). Returns
--- the session name, or nil if the session can't be created.
function M.ensure_terminal(key, cmd, cwd)
    local sess = M.terminal_session_name(key)
    if not tmux.session_exists(sess) then
        if not create_session(sess, { name = "main", cwd = cwd or vim.fn.getcwd(), cmd = cmd }) then
            return nil
        end
    end
    return sess
end

--- Rigid-kill a raw session name (pgid collection → kill-session → SIGKILL
--- sweep). Returns number of surviving groups that had to be SIGKILL'd.
function M.rigid_kill_session(sess)
    return tmux.kill_session(sess)
end

--- Get a journal terminal record by key (nil if unknown).
function M.get_terminal(key)
    local j = J.load()
    for _, t in ipairs(j.terminals) do
        if t.key == key then
            return t
        end
    end
    return nil
end

--- Upsert a terminal record into the journal.
function M.upsert_terminal(rec)
    local j = J.load()
    local found = false
    for i, t in ipairs(j.terminals) do
        if t.key == rec.key then
            j.terminals[i] = rec
            found = true
            break
        end
    end
    if not found then
        table.insert(j.terminals, rec)
    end
    J.save(j)
end

--- Remove a terminal record from the journal (kill is permanent).
function M.remove_terminal(key)
    local j = J.load()
    local kept = {}
    for _, t in ipairs(j.terminals) do
        if t.key ~= key then
            table.insert(kept, t)
        end
    end
    j.terminals = kept
    if j.last_active_terminal == key then
        j.last_active_terminal = #kept > 0 and kept[1].key or nil
    end
    J.save(j)
end

--- Persist the last-active terminal key.
function M.set_last_active_terminal(key)
    local j = J.load()
    j.last_active_terminal = key
    J.save(j)
end

--- Terminal records from the journal (sorted by key for stable dots).
function M.journal_terminals()
    local j = J.load()
    local out = vim.list_extend({}, j.terminals)
    table.sort(out, function(a, b)
        return a.key < b.key
    end)
    return out
end

--- Last-active terminal key persisted in the journal (nil if none).
function M.last_active_terminal()
    local j = J.load()
    return j.last_active_terminal
end

-- ----------------------------------------------------------------------------
-- Telescope picker helper (lazy-required; mirrors terminal.lua's layout)
-- ----------------------------------------------------------------------------
function M.portrait_picker(title, results, entry_maker, on_select)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers
        .new({}, {
            prompt_title = title,
            finder = finders.new_table({
                results = results,
                entry_maker = entry_maker,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, _map)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection then
                        on_select(selection.value)
                    end
                end)
                return true
            end,
        })
        :find()
end

--- Picker: choose a workspace (live first). on_select(ws_name).
function M.pick_workspace(on_select)
    local list = M.list()
    table.sort(list, function(a, b)
        return a.name < b.name
    end)
    M.portrait_picker("Workspaces", list, function(entry)
        return {
            value = entry.name,
            display = string.format(
                "%s %-14s %s",
                entry.live and "●" or "○",
                entry.name,
                entry.n_windows .. " win"
            ),
            ordinal = entry.name,
        }
    end, on_select)
end

-- ----------------------------------------------------------------------------
-- Setup
-- ----------------------------------------------------------------------------
function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
end

M._tmux = tmux -- exposed for tests / smoke checks
M._run = run
M._safe_window_name = safe_window_name
M._journal_path = journal_path

return M
