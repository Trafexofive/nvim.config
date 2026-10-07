-- /lua/mlamkadm/core/terminal.lua
-- Terminal Management System — the ORIGINAL UX, ported 1:1 onto the tmux
-- daemon (mlamkadm.core.workspace).
--
-- Port contract (pre-zellij-split terminal.lua):
--   * One terminal INSTANCE per registry entry; each instance is its own
--     headless tmux session (nvim-<proj>-<hash>-term-<key>). The float's
--     buffer runs `tmux attach-session` — hiding a terminal closes the
--     WINDOW ONLY; the buffer, the attach job and the instance's process
--     keep running. Re-opening shows the SAME buffer (scrollback intact).
--   * Singleton by command (get_term_by_cmd → get_term_by_key): one
--     lazygit instance per project, forever — reachable from anywhere.
--   * <C-t> strict toggle of the LAST-ACTIVE terminal (never cycles);
--     <C-j>/<C-k> cycle live terminals (never drops the popup);
--     <C-d> kills current then pulls up the next live one (wrapping);
--     <C-n>/<leader>tn spawn a NEW instance (hides current first).
--   * Persistence: journal records each instance's cmd (smart resurrect:
--     dead session respawns the recipe; live session re-attaches).
--
-- The workspace layer (one float attaching to a multi-WINDOW tmux session)
-- stays as a separate "synced terminals" feature: <leader>tw/tN/tK.

local W = require("mlamkadm.core.workspace")

local M = {}

-- ----------------------------------------------------------------------------
-- Configuration
-- ----------------------------------------------------------------------------
local config = {
    -- No border: the popup is a clean rectangle with a winbar (top status bar)
    -- instead of a titled outline. This removes all "|" / "-" border glyphs.
    border = "none",
    width = 0.9,
    height = 0.85,
    title = "Terminal",
    title_pos = "center", -- center | left | right
    bar_hl = "TerminalBar",
    close_key = "<C-t>",
    winblend = 0,
    zindex = 50,
    scrollback = 100000,
    -- Winbar sync poll while a float is open (workspace window dots).
    sync_ms = 2000,
}

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
-- Terminal registry — structure:
--   { id, key, cmd, session, buf, win, opts, open, killing, detaching }
-- `key` is the singleton key (sanitized cmd); `session` the daemon session.
local terminals = {}
local next_id = 1
local last_active_id = nil

-- Workspace ("synced terminals") floats: ws_floats[name] = { buf, win, job, title, killing, detaching }
local ws_floats = {}
local poll_timer = nil

-- Forward declaration: defined in the workspace section below, referenced
-- by registry functions defined earlier (kill_current).
local visible_ws

-- ----------------------------------------------------------------------------
-- Helpers (ported from the old module)
-- ----------------------------------------------------------------------------
-- Is this tracked terminal not a zombie? A terminal is a zombie when it has
-- no buffer AND no window (killed/detached but never removed from the
-- registry). Such entries must not render a bar dot.
local function is_live(term)
    if not term then
        return false
    end
    if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
        return true
    end
    if term.win and vim.api.nvim_win_is_valid(term.win) then
        return true
    end
    -- Just created (open flag true, buffer not yet materialized).
    return term.open == true
end

--- Is the tracked terminal's attach job actually live?
-- Ported from the old is_alive: dead channels keep the handle but the pty
-- becomes an empty string. A detached (jobstopped) buffer reads as dead —
-- the registry entry survives, re-open spawns a fresh attach client.
local function is_alive(term)
    if not term then
        return false
    end
    if not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
        return false
    end
    if vim.bo[term.buf].buftype ~= "terminal" then
        return false
    end
    local chan = vim.b[term.buf].terminal_job_id
    if not chan or chan <= 0 then
        return false
    end
    local ok, info = pcall(vim.api.nvim_get_chan_info, chan)
    if not ok or not info then
        return false
    end
    return info.pty ~= nil and info.pty ~= ""
end

local function get_term_by_id(id)
    return terminals[id]
end

local function get_term_by_key(key)
    for _, term in pairs(terminals) do
        if term.key == key then
            return term
        end
    end
    return nil
end

--- Old get_term_by_cmd: first registry entry whose cmd matches exactly.
--- toggle() falls back to this so singleton toggles re-use new_term
--- instances of the same command (old semantics — no duplicate spawns).
local function get_term_by_cmd(cmd)
    for _, term in pairs(terminals) do
        if term.cmd == cmd then
            return term
        end
    end
    return nil
end

--- The id of the currently visible registry terminal, or nil.
local function visible_id()
    for id, term in pairs(terminals) do
        if term.win and vim.api.nvim_win_is_valid(term.win) then
            return id
        end
    end
    return nil
end

--- Sorted ids of live tracked terminals only.
local function alive_ids()
    local ids = {}
    for id, term in pairs(terminals) do
        if is_alive(term) then
            table.insert(ids, id)
        end
    end
    table.sort(ids)
    return ids
end

local function index_of(ids, id)
    for i, v in ipairs(ids) do
        if v == id then
            return i
        end
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- Winbar (dots: one per live terminal, active highlighted) — old port
-- ----------------------------------------------------------------------------
local function render_bar(term)
    local ids = {}
    for id in pairs(terminals) do
        if is_live(terminals[id]) then
            table.insert(ids, id)
        end
    end
    table.sort(ids)

    local bar = ""
    for i, id in ipairs(ids) do
        local active = (id == term.id)
        local hl = active and "TerminalBarActive" or "TerminalBarInactive"
        local dot = active and "●" or "○"
        bar = bar .. string.format("%%#%s#%s", hl, dot)
        if i < #ids then
            bar = bar .. " "
        end
    end
    if bar == "" then
        bar = term._bar_title or config.title -- fallback (no tracked terminals)
    end
    return string.format("%%#%s#  %s  %%*", config.bar_hl, bar)
end

--- Re-render the winbar on every open terminal window so the dots stay in
-- sync as terminals are created/closed/cycled. Also refreshes workspace
--- float bars (window dots) so both features read consistently.
local function refresh_bars()
    for _, t in pairs(terminals) do
        if t.win and vim.api.nvim_win_is_valid(t.win) then
            vim.wo[t.win].winbar = render_bar(t)
        end
    end
    for name, fl in pairs(ws_floats) do
        if fl.win and vim.api.nvim_win_is_valid(fl.win) then
            local wins = W.windows(name)
            local dots = ""
            for i, w in ipairs(wins) do
                local hl = w.active and "TerminalBarActive" or "TerminalBarInactive"
                local dot = w.active and "●" or "○"
                dots = dots .. string.format("%%#%s#%s", hl, dot)
                if i < #wins then
                    dots = dots .. " "
                end
            end
            local label = (#wins > 0) and (dots .. "  " .. (#wins .. " win")) or (fl.title or "Workspace")
            vim.wo[fl.win].winbar = string.format("%%#%s#  %s  %%*", config.bar_hl, label)
        end
    end
end

-- Light poll while any float is open: keeps workspace window dots truthful.
local function sync_poll_start()
    if poll_timer then
        return
    end
    poll_timer = vim.loop.new_timer()
    poll_timer:start(config.sync_ms, config.sync_ms, function()
        vim.schedule(function()
            local any = visible_id() ~= nil
            if not any then
                for _, fl in pairs(ws_floats) do
                    if fl.win and vim.api.nvim_win_is_valid(fl.win) then
                        any = true
                    end
                end
            end
            if not any then
                if poll_timer then
                    poll_timer:stop()
                    poll_timer:close()
                    poll_timer = nil
                end
                return
            end
            refresh_bars()
        end)
    end)
end

-- ----------------------------------------------------------------------------
-- Float machinery
-- ----------------------------------------------------------------------------
local function create_float(term)
    local screen_width = vim.o.columns
    local screen_height = vim.o.lines

    local width = math.floor(screen_width * (term.opts.width or config.width))
    local height = math.floor(screen_height * (term.opts.height or config.height))
    local row = math.floor((screen_height - height) / 2)
    local col = math.floor((screen_width - width) / 2)

    local position = term.opts.position or "center"
    if position == "right" then
        col = screen_width - width - 2
    elseif position == "left" then
        col = 2
    end

    local title = term.opts.title or config.title
    -- If title is default, derive from command (old behavior).
    if title == config.title and term.cmd then
        local cmd_name = term.cmd:match("^(%S+)") or term.cmd
        title = cmd_name:gsub("^%l", string.upper) .. " (" .. term.id .. ")"
    end
    term._bar_title = title

    return {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = config.border, -- "none": no outline, no "|" / "-"
        style = "minimal",
        zindex = config.zindex,
    }
end

--- Prepare the terminal's buffer: fresh (unmodified) buffer + options +
--- buffer-local keymaps + session ensure (respawn if dead IS the
--- smart-resurrect). The attach client is launched separately, AFTER the
--- window has made this buffer current (old ordering: nvim_open_win with
--- enter=true BEFORE termopen — termopen attaches to the current buffer).
local function prepare_term(term)
    -- A stale (detached/dead) buffer must not leak; termopen also refuses
    -- modified buffers, so always materialize a fresh one.
    if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
        pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
    end
    term.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(term.buf, "bufhidden", "hide")
    pcall(function()
        vim.bo[term.buf].scrollback = config.scrollback
    end)

    local close_key = term.opts.close_key or config.close_key
    local map_opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(
        term.buf,
        "t",
        close_key,
        [[<C-\><C-n><cmd>lua require("mlamkadm.core.terminal").toggle(]] .. term.id .. [[)<CR>]],
        map_opts
    )
    vim.api.nvim_buf_set_keymap(term.buf, "t", "<C-Esc>", [[<C-\><C-n>]], map_opts)

    local sess = W.ensure_terminal(term.key, term.cmd, term.opts.cwd)
    if not sess then
        vim.notify("failed to start terminal '" .. term.key .. "'", vim.log.levels.ERROR)
        return false
    end
    term.session = sess
    return true
end

--- Launch the attach client on the CURRENT buffer — only valid when the
--- terminal's window has been opened with enter=true (term.buf is current).
local function launch_attach(term)
    local id = term.id
    local key = term.key
    return vim.fn.termopen(W.attach_cmd(term.session), {
        on_exit = function(_job_id, _code, _event)
            local t = terminals[id]
            if not t then
                return -- already reaped
            end
            if t.killing or t.detaching then
                -- Intentional teardown/detach: buffer dies, the instance
                -- (daemon session) lives on. No journal purge.
                if t.win and vim.api.nvim_win_is_valid(t.win) then
                    pcall(vim.api.nvim_win_close, t.win, true)
                    t.win = nil
                end
                if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
                    pcall(vim.api.nvim_buf_delete, t.buf, { force = true })
                    t.buf = nil
                end
                return
            end
            -- Genuine exit (process ended inside tmux / session died):
            -- old behavior — always clear the registry entry on exit.
            if t.win and vim.api.nvim_win_is_valid(t.win) then
                pcall(vim.api.nvim_win_close, t.win, true)
                t.win = nil
            end
            if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
                pcall(vim.api.nvim_buf_delete, t.buf, { force = true })
                t.buf = nil
            end
            terminals[id] = nil
            W.remove_terminal(key)
            if last_active_id == id then
                last_active_id = nil
            end
            refresh_bars()
        end,
    })
end

-- ----------------------------------------------------------------------------
-- Core Terminal Management (old semantics, daemon-backed)
-- ----------------------------------------------------------------------------

--- Create a new terminal registry entry (no spawn yet).
function M.create_term(cmd, opts)
    opts = opts or {}
    local id = next_id
    next_id = next_id + 1

    local key = opts.key or W._safe_window_name(cmd or "term")
    -- New instances (not singleton toggles) get a unique key.
    if opts.unique then
        key = key .. "-" .. id
    end

    local term = {
        id = id,
        key = key,
        cmd = cmd or vim.o.shell,
        opts = opts,
        session = opts.session or W.terminal_session_name(key),
        buf = nil,
        win = nil,
        open = false,
    }
    terminals[id] = term
    return term
end

--- Toggle a terminal: visible → hide (WINDOW ONLY — buffer, client and the
--- instance keep running); hidden → show the SAME buffer (old contract).
-- @param id_or_cmd: terminal ID or command string (singleton by key)
function M.toggle(id_or_cmd, opts, stay_normal)
    local term
    opts = opts or {}

    if type(id_or_cmd) == "number" then
        term = terminals[id_or_cmd]
    else
        -- Singleton: by key first, then by exact cmd (old get_term_by_cmd —
        -- new_term instances of the same cmd are re-used, not duplicated).
        local key = opts.key or W._safe_window_name(id_or_cmd)
        term = get_term_by_key(key) or get_term_by_cmd(id_or_cmd)
        if not term then
            term = M.create_term(id_or_cmd, vim.tbl_deep_extend("force", { key = key }, opts))
        end
    end

    if not term then
        return
    end

    if opts.position then
        term.opts.position = opts.position
    end

    -- If open, hide it — close the window ONLY. The buffer and the attach
    -- client keep running; scrollback survives; re-open is a pure window show.
    if term.win and vim.api.nvim_win_is_valid(term.win) then
        vim.api.nvim_win_close(term.win, false) -- hide
        term.win = nil
        term.open = false
        last_active_id = term.id
        refresh_bars()
        return
    end

    -- Reuse the live buffer if the client is still attached (hidden float);
    -- otherwise prepare a fresh buffer (session ensured — resurrect if the
    -- instance died) and launch the attach client AFTER the window makes
    -- the buffer current (termopen binds to the current buffer).
    local needs_start = not is_alive(term)
    if needs_start then
        if not prepare_term(term) then
            return
        end
    end

    local win_opts = create_float(term)
    term.win = vim.api.nvim_open_win(term.buf, true, win_opts)
    vim.api.nvim_win_set_option(term.win, "winblend", config.winblend)
    term.open = true
    last_active_id = term.id
    refresh_bars()
    sync_poll_start()

    if needs_start then
        launch_attach(term)
    end

    if not stay_normal then
        vim.cmd("startinsert")
    end
end

-- Wrapper for _G.Poptui compatibility
function M.toggle_popup(cmd, position, opts)
    opts = opts or {}
    if position then
        opts.position = position
    end
    M.toggle(cmd, opts)
end

--- Create a fresh terminal instance (no singleton) and open it, hiding the
--- current popup first (old M.new_term).
function M.new_term(cmd, opts)
    opts = opts or {}
    local term = M.create_term(cmd or vim.o.shell, vim.tbl_deep_extend("force", { unique = true }, opts))
    for _, t in pairs(terminals) do
        if t ~= term and t.win and vim.api.nvim_win_is_valid(t.win) then
            pcall(vim.api.nvim_win_close, t.win, false)
            t.win = nil
            t.open = false
        end
    end
    M.toggle(term.id, nil, false)
    return term
end

-- ----------------------------------------------------------------------------
-- Navigation & Management (old logic, 1:1)
-- ----------------------------------------------------------------------------

--- <C-t>: strict toggle of the LAST-ACTIVE terminal. Never cycles, never
--- drops: a visible terminal hides and is remembered; nothing visible →
--- the remembered one comes back (fallback: first live, else primary).
function M.toggle_last_active()
    local visible = visible_id()
    if visible then
        local term = terminals[visible]
        if term.win and vim.api.nvim_win_is_valid(term.win) then
            pcall(vim.api.nvim_win_close, term.win, false)
            term.win = nil
            term.open = false
        end
        last_active_id = visible
        return
    end

    if last_active_id and terminals[last_active_id] and is_alive(terminals[last_active_id]) then
        M.toggle(last_active_id)
        return
    end

    local ids = alive_ids()
    if #ids > 0 then
        M.toggle(ids[1])
        return
    end

    -- No live tracked terminals → open the primary terminal (old open_zellij
    -- fallback: the project's main persistent session).
    M.open_primary()
end

--- <leader>tz: strict toggle of the project's PRIMARY terminal — if it is
--- visible, close it; otherwise hide any other visible floats and open it,
--- so it always shows exactly the primary terminal (never cycles).
function M.open_primary()
    local term = get_term_by_key("primary")
    if not term then
        term = M.create_term(vim.o.shell, { key = "primary", title = "Terminal" })
    end

    if term.win and vim.api.nvim_win_is_valid(term.win) then
        pcall(vim.api.nvim_win_close, term.win, false)
        term.win = nil
        term.open = false
        last_active_id = term.id
        refresh_bars()
        return
    end

    for _, t in pairs(terminals) do
        if t ~= term and t.win and vim.api.nvim_win_is_valid(t.win) then
            pcall(vim.api.nvim_win_close, t.win, false)
            t.win = nil
            t.open = false
        end
    end
    M.toggle(term.id)
end

--- Cycle to the next live terminal; wrap at end. Only cycles when a
--- terminal is actually showing and there are 2+ live ones. Never drops
--- the popup: closes the current AFTER picking a confirmed-live target.
function M.cycle_next()
    local cur = visible_id()
    if not cur then
        -- Workspace float visible? Cycle its windows (synced terminals).
        M.cycle_ws_windows("next")
        return
    end

    local ids = alive_ids()
    local n = #ids
    if n < 2 then
        return
    end

    local cur_idx = index_of(ids, cur)
    if not cur_idx then
        return
    end

    local target = ids[(cur_idx % n) + 1]
    if not terminals[target] then
        return
    end

    local cur_term = terminals[cur]
    if cur_term.win and vim.api.nvim_win_is_valid(cur_term.win) then
        pcall(vim.api.nvim_win_close, cur_term.win, false)
        cur_term.win = nil
        cur_term.open = false
    end
    M.toggle(target, nil, true)
end

function M.cycle_prev()
    local cur = visible_id()
    if not cur then
        M.cycle_ws_windows("prev")
        return
    end

    local ids = alive_ids()
    local n = #ids
    if n < 2 then
        return
    end

    local cur_idx = index_of(ids, cur)
    if not cur_idx then
        return
    end

    local target = ids[((cur_idx - 2) % n) + 1]
    if not terminals[target] then
        return
    end

    local cur_term = terminals[cur]
    if cur_term.win and vim.api.nvim_win_is_valid(cur_term.win) then
        pcall(vim.api.nvim_win_close, cur_term.win, false)
        cur_term.win = nil
        cur_term.open = false
    end
    M.toggle(target, nil, true)
end

--- Kill a terminal by id: rigid session kill (SIGTERM→SIGKILL group sweep),
--- buffer teardown, registry + journal removal.
function M.kill_term(id)
    local term = terminals[id]
    if not term then
        return
    end

    term.killing = true
    if term.win and vim.api.nvim_win_is_valid(term.win) then
        pcall(vim.api.nvim_win_close, term.win, true)
        term.win = nil
        term.open = false
    end

    -- Rigid: the process group dies with the instance. Nothing resurrects.
    if term.session then
        W.rigid_kill_session(term.session)
    end
    if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
        pcall(vim.fn.jobstop, vim.b[term.buf].terminal_job_id or 0)
        pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
        term.buf = nil
    end

    terminals[id] = nil
    W.remove_terminal(term.key)
    refresh_bars()
    if last_active_id == id then
        last_active_id = nil
    end
end

--- <C-d>: kill the currently visible terminal (falls back to last-active),
--- then pull up the next live one (wrapping) so the float stays focused.
function M.kill_current()
    -- Workspace float visible → kill its active window (synced terminals).
    local ws_name = visible_ws()
    if ws_name then
        M.kill_ws_window(ws_name)
        return
    end

    local target = visible_id() or last_active_id
    if not target or not terminals[target] then
        vim.notify("No terminal to kill", vim.log.levels.INFO)
        return
    end

    -- Pick the next live terminal to show AFTER the kill (wrap at end).
    local ids = alive_ids()
    local n = #ids
    local next_target = nil
    local t_idx = index_of(ids, target)
    if t_idx and n > 1 then
        next_target = ids[(t_idx % n) + 1]
    elseif n > 1 then
        next_target = ids[1]
    end

    M.kill_term(target)

    -- Keep the popup up with the next terminal (stay in normal mode, like
    -- cycling). If nothing is left, the popup naturally drops.
    if next_target and terminals[next_target] then
        M.toggle(next_target, nil, true)
    end
end

function M.list_terminals()
    local list = {}
    for id, term in pairs(terminals) do
        table.insert(list, {
            id = id,
            key = term.key,
            cmd = term.cmd,
            buf = term.buf,
            open = term.open,
            name = "Term " .. id .. ": " .. term.cmd,
        })
    end
    table.sort(list, function(a, b)
        return a.id < b.id
    end)
    return list
end

function M.switch_terminal()
    local terms = M.list_terminals()
    if #terms == 0 then
        vim.notify("No active terminals", vim.log.levels.INFO)
        return
    end

    W.portrait_picker("Switch Terminal", terms, function(entry)
        return {
            value = entry,
            display = (entry.open and "[*] " or "[ ] ") .. entry.name,
            ordinal = entry.name,
        }
    end, function(term)
        M.toggle(term.id)
    end)
end

-- ----------------------------------------------------------------------------
-- Workspace ("synced terminals") feature — unchanged behavior
-- ----------------------------------------------------------------------------
function visible_ws()
    for name, fl in pairs(ws_floats) do
        if fl.win and vim.api.nvim_win_is_valid(fl.win) then
            return name
        end
    end
    return nil
end
local function ws_active_window(name)
    for _, w in ipairs(W.windows(name)) do
        if w.active then
            return w.name
        end
    end
    return nil
end

local function hide_ws_float(name)
    local fl = ws_floats[name]
    if not fl then
        return
    end
    fl.detaching = true
    if fl.job then
        pcall(vim.fn.jobstop, fl.job) -- clean client detach; session lives on
        fl.job = nil
    end
    if fl.win and vim.api.nvim_win_is_valid(fl.win) then
        pcall(vim.api.nvim_win_close, fl.win, false)
        fl.win = nil
    end
    if fl.buf and vim.api.nvim_buf_is_valid(fl.buf) then
        pcall(vim.api.nvim_buf_delete, fl.buf, { force = true })
    end
    ws_floats[name] = nil
end

local function show_ws_float(name, opts)
    opts = opts or {}
    local ws = W.ensure(name)
    if not ws then
        return
    end
    name = ws.name

    local fl = ws_floats[name]
    if fl and fl.win and vim.api.nvim_win_is_valid(fl.win) then
        vim.api.nvim_set_current_win(fl.win)
        refresh_bars()
        return
    end
    hide_ws_float(name)

    fl = { title = "Workspace: " .. name, killing = false, detaching = false }
    ws_floats[name] = fl

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
    pcall(function()
        vim.bo[buf].scrollback = config.scrollback
    end)
    fl.buf = buf

    local geo = create_float({ id = 0, opts = opts })
    local win = vim.api.nvim_open_win(buf, true, geo)
    vim.api.nvim_win_set_option(win, "winblend", config.winblend)
    fl.win = win
    refresh_bars()

    local job = vim.fn.termopen(W.attach_cmd(ws.session), {
        on_exit = function()
            local cur = ws_floats[name]
            if not cur or cur.job ~= job then
                return
            end
            if cur.killing or cur.detaching then
                ws_floats[name] = nil
                return
            end
            local rec = W.lookup(name)
            if rec and not rec.live then
                W.remove(name)
                vim.notify("Workspace '" .. name .. "' ended (no windows left)", vim.log.levels.INFO)
            end
            hide_ws_float(name)
            refresh_bars()
        end,
    })
    fl.job = job

    sync_poll_start()
    vim.cmd("startinsert")
end

function M.open_workspace(name)
    W.set_active(name)
    show_ws_float(name, {})
end

function M.switch_workspace()
    W.pick_workspace(function(name)
        M.open_workspace(name)
    end)
end

function M.new_workspace()
    vim.ui.input({ prompt = "New workspace name: " }, function(input)
        input = vim.trim(input or "")
        if input == "" then
            return
        end
        M.open_workspace(input)
    end)
end

function M.kill_workspace()
    W.pick_workspace(function(name)
        local n = #W.windows(name)
        vim.ui.select({ "Kill '" .. name .. "' (" .. n .. " windows)", "Cancel" }, {
            prompt = "Rigid kill: SIGTERM→SIGKILL all processes, no resurrect.",
        }, function(choice)
            if not choice or choice == "Cancel" or not vim.startswith(choice, "Kill") then
                return
            end
            local fl = ws_floats[name]
            if fl then
                fl.killing = true
                hide_ws_float(name)
            end
            local swept = W.remove(name)
            vim.notify(
                string.format("Workspace '%s' killed (%d process group(s) SIGKILL'd)", name, swept),
                vim.log.levels.INFO
            )
            refresh_bars()
        end)
    end)
end

--- Cycle windows of the visible workspace float (used when no registry
--- terminal is visible and <C-j>/<C-k> is pressed).
function M.cycle_ws_windows(dir)
    local name = visible_ws()
    if not name then
        return
    end
    if W.cycle(name, dir) then
        refresh_bars()
    end
end

--- Kill the active window of a visible workspace float.
function M.kill_ws_window(name)
    local cur = ws_active_window(name)
    if not cur then
        vim.notify("No workspace window to kill", vim.log.levels.INFO)
        return
    end
    local died = W.kill_window(name, cur)
    if died then
        local fl = ws_floats[name]
        if fl then
            fl.killing = true
            hide_ws_float(name)
        end
    end
    refresh_bars()
end

--- Kill every workspace AND terminal session (all projects' sessions +
--- journals). Global clean slate — the alpha dashboard button.
function M.kill_all_workspaces()
    for id in pairs(terminals) do
        M.kill_term(id)
    end
    for name in pairs(ws_floats) do
        hide_ws_float(name)
    end
    local n = W.kill_all()
    vim.notify(
        (n == 0 and "No sessions to kill" or (n .. " terminal/workspace session(s) killed")),
        vim.log.levels.INFO
    )
    refresh_bars()
end

-- ----------------------------------------------------------------------------
-- TUI Registry (old)
-- ----------------------------------------------------------------------------
local tui_registry = {}

function M.register_tui(name, cmd, position, opts)
    table.insert(tui_registry, {
        name = name,
        cmd = cmd,
        position = position,
        opts = opts or {},
    })
end

function M.show_tui_registry()
    W.portrait_picker("TUI Commands", tui_registry, function(entry)
        return {
            value = entry,
            display = string.format("%-20s → %s", entry.name, entry.cmd),
            ordinal = entry.name .. " " .. entry.cmd,
        }
    end, function(sel)
        -- Singleton per command (registry behavior preserved).
        M.toggle(sel.cmd, { position = sel.position, title = sel.name })
    end)
end

-- ----------------------------------------------------------------------------
-- Persistence (auto-session hooks + exit)
-- ----------------------------------------------------------------------------

function M.save_session()
    -- Upsert the current registry into the journal; untouched entries keep
    -- their recipes (that's the resurrect for instances not yet re-opened).
    for _, term in pairs(terminals) do
        W.upsert_terminal({
            key = term.key,
            cmd = term.cmd,
            session = term.session,
            cwd = term.opts.cwd,
            position = term.opts.position,
            title = term.opts.title,
            is_open = term.open,
        })
    end
    if last_active_id and terminals[last_active_id] then
        W.set_last_active_terminal(terminals[last_active_id].key)
    end
    W.save()
end

function M.restore_session()
    -- Rebuild the registry from the saved snapshot WITHOUT clobbering any
    -- terminals already tracked (guards against double-restore hooks).
    local seen = {}
    for _, t in pairs(terminals) do
        seen[t.key] = true
    end

    local entries = W.journal_terminals()
    local first_id = nil
    for _, rec in ipairs(entries) do
        if rec.key and rec.key ~= "" and not seen[rec.key] then
            local term = M.create_term(rec.cmd, {
                key = rec.key,
                session = rec.session,
                cwd = rec.cwd,
                position = rec.position,
                title = rec.title,
            })
            seen[rec.key] = true
            if not first_id then
                first_id = term.id
            end
        end
    end

    -- Re-open ONE terminal: the last-active one (or the first restored /
    -- single `is_open` entry as fallback). The rest stay in the registry so
    -- <C-j>/<C-k> cycles to them — the old "only one comes back" contract.
    local open_key = W.last_active_terminal()
    if not open_key then
        for _, rec in ipairs(entries) do
            if rec.is_open and rec.key and rec.key ~= "" then
                open_key = rec.key
                break
            end
        end
    end

    local open_id = nil
    if open_key then
        local t = get_term_by_key(open_key)
        if t then
            open_id = t.id
        end
    end
    if not open_id and first_id then
        open_id = first_id
    end

    if open_id then
        last_active_id = open_id
        local id = open_id
        vim.schedule(function()
            if terminals[id] then
                M.toggle(id, nil, true) -- stay in normal mode
            end
        end)
    end
end

function M.cleanup(opts)
    opts = opts or {}

    if opts.save then
        M.save_session()
    end

    -- Close windows and DETACH the attach clients (session-manager /
    -- dashboard flow). The daemon sessions keep running; buffers die with
    -- the client, re-opens re-attach.
    for _, term in pairs(terminals) do
        if term.win and vim.api.nvim_win_is_valid(term.win) then
            pcall(vim.api.nvim_win_close, term.win, false)
        end
        term.win = nil
        term.open = false
        if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
            term.detaching = true
            local chan = vim.b[term.buf].terminal_job_id
            if chan and chan > 0 then
                pcall(vim.fn.jobstop, chan)
            end
            -- on_exit (detaching) wipes the dead buffer; registry survives.
        end
    end

    for name in pairs(ws_floats) do
        hide_ws_float(name)
    end

    if opts.delete_buffers then
        for id, term in pairs(terminals) do
            if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
                pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
                term.buf = nil
            end
            terminals[id] = nil
        end
        last_active_id = nil
    end

    if poll_timer then
        poll_timer:stop()
        poll_timer:close()
        poll_timer = nil
    end
end

-- ----------------------------------------------------------------------------
-- Setup
-- ----------------------------------------------------------------------------
function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
    W.setup({})

    -- Gruvbox-ish top status bar for terminal popups (no border glyphs).
    local function setup_bar_hl()
        vim.api.nvim_set_hl(0, config.bar_hl, { fg = "#282828", bg = "#83a598", bold = true })
        vim.api.nvim_set_hl(0, "TerminalBarActive", { fg = "#fbf1c7", bg = "#83a598", bold = true })
        vim.api.nvim_set_hl(0, "TerminalBarInactive", { fg = "#3c3836", bg = "#83a598" })
    end
    setup_bar_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("TerminalBarHighlight", { clear = true }),
        callback = setup_bar_hl,
        desc = "Re-apply terminal bar highlight on colorscheme change",
    })

    _G.Poptui = M.toggle_popup

    -- Register Default TUIs (old list, Zellij entry kept as manual escape
    -- hatch — it is a plain singleton cmd now, nothing special).
    M.register_tui("Terminal", vim.o.shell)
    M.register_tui("Lazygit", "lazygit")
    M.register_tui("Glow", "glow")
    M.register_tui("Noter", "noter")
    M.register_tui("Aart", "aart")
    M.register_tui("Lazydocker", "lazydocker")
    M.register_tui("Docker Logs", "docker-compose logs -f")
    M.register_tui("Btop", "btop", nil, { use_theme = false })
    M.register_tui("File Manager", "yazi")
    M.register_tui("Make Run", "make run")
    M.register_tui("Make Clean", "make clean")
    M.register_tui("Qwen Full", "qwen -a -y")

    local group = vim.api.nvim_create_augroup("TerminalManager", { clear = true })

    -- Save, then detach (never kill) on exit. Sessions live in the daemon.
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            M.save_session()
            M.cleanup({})
        end,
        desc = "Save terminal registry and detach clients on exit",
    })
end

-- ----------------------------------------------------------------------------
-- Keymaps (old surface + workspace feature)
-- ----------------------------------------------------------------------------
-- <C-t>  : toggle the LAST-ACTIVE terminal (remembers which one before
--          hiding; reopening always restores the one you were last using,
--          never the first). Hiding closes the WINDOW only — the terminal
--          keeps running and scrollback survives.
-- <C-j>  : cycle to the next live terminal (only when one is visible).
-- <C-k>  : cycle to the previous live terminal.
-- <C-n>  : open a NEW terminal instance (own daemon session).
-- <C-d>  : kill the currently visible terminal + pull up the next one
--          (SIGTERM→SIGKILL group teardown; nothing resurrects).
--          NOTE: `<C-d>` is also mapped by smooth-scroll (neoscroll);
--          terminal owns it here, so smooth-scroll's <C-d> is disabled.
-- <leader>tz : open the project's PRIMARY terminal (strict toggle).
-- <leader>tn : new terminal instance.
-- <leader>ts : switch terminal (telescope).
-- <leader>tt : TUI registry (singleton per command).
-- <leader>tw/tN/tK : workspace ("synced terminals") switch/new/kill.
vim.keymap.set("n", "<C-t>", M.toggle_last_active, { desc = "Terminal: Toggle last-active" })
vim.keymap.set("n", "<C-j>", M.cycle_next, { desc = "Terminal: Next" })
vim.keymap.set("n", "<C-k>", M.cycle_prev, { desc = "Terminal: Prev" })
vim.keymap.set("n", "<C-n>", function()
    M.new_term(vim.o.shell, {})
end, { desc = "Terminal: New instance" })
vim.keymap.set("n", "<C-d>", M.kill_current, { desc = "Terminal: Kill current" })
vim.keymap.set("n", "<leader>tz", M.open_primary, { desc = "Open primary terminal" })
vim.keymap.set("n", "<leader>tn", function()
    M.new_term(vim.o.shell, {})
end, { desc = "New terminal instance" })
vim.keymap.set("n", "<leader>ts", M.switch_terminal, { desc = "Switch Terminal" })
vim.keymap.set("n", "<leader>tt", M.show_tui_registry, { desc = "TUI Registry" })
vim.keymap.set("n", "<leader>tw", M.switch_workspace, { desc = "Workspaces: Switch (synced terminals)" })
vim.keymap.set("n", "<leader>tN", M.new_workspace, { desc = "Workspaces: New" })
vim.keymap.set("n", "<leader>tK", M.kill_workspace, { desc = "Workspaces: Kill (rigid)" })

-- Singleton TUI keys (old)
vim.keymap.set("n", "<leader>jj", function()
    M.toggle("lazygit")
end, { desc = "Toggle Lazygit" })
vim.keymap.set("n", "<leader>jd", function()
    M.toggle("lazydocker")
end, { desc = "Toggle Lazydocker" })
vim.keymap.set("n", "<leader>dl", function()
    M.toggle("docker-compose logs -f")
end, { desc = "Docker Compose Logs" })
vim.keymap.set("n", "<leader>jt", function()
    M.toggle("btop", { use_theme = false })
end, { desc = "Toggle Btop" })
vim.keymap.set("n", "<leader>jf", function()
    M.toggle("yazi")
end, { desc = "Toggle File Manager (Yazi)" })
vim.keymap.set("n", "<leader>mg", function()
    M.toggle("glow")
end, { desc = "Make: Glow" })
vim.keymap.set("n", "<leader>mr", function()
    M.toggle("make run")
end, { desc = "Make: Run" })
vim.keymap.set("n", "<leader>mc", function()
    M.toggle("make clean")
end, { desc = "Make: Clean" })

return M
