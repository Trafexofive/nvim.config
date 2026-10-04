-- /lua/mlamkadm/core/terminal.lua
-- Terminal float UI over the tmux workspace daemon.
--
-- Architecture (see mlamkadm.core.workspace for the model):
--   * One float per workspace; the float's buffer runs `tmux attach-session`.
--     Terminal instances are tmux windows, cycled/selected via the workspace
--     module. Closing a float (or nvim) merely detaches — the daemon owns the
--     processes and they keep running.
--   * Every consumer-facing entry point (toggle/new_term/cleanup/
--     save_session/restore_session/list_terminals/...) keeps the pre-rework
--     signature: cortex.lua, explorer.lua, session.lua, snacks.lua and the
--     lualine widget call this module without knowing about tmux.
--   * The dots winbar mirrors the workspace's tmux windows (live truth),
--     refreshed on every user action plus a light 2s poll while a float is
--     open, so windows closed from inside tmux fall out of the bar too.

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
    title = "Workspace",
    -- Highlight group for the winbar (top dynamic status bar).
    bar_hl = "TerminalBar",
    close_key = "<C-t>",
    winblend = 0,
    zindex = 50,
    scrollback = 100000,
    -- Dots-bar live sync while a float is open (ms).
    sync_ms = 2000,
}

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
-- Open attach floats: floats[ws_name] = {
--   buf, win, job, position, title, killing/detaching flags }
local floats = {}

local poll_timer = nil

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
local function active_ws_name()
    return W.active_name()
end

--- The workspace whose float is currently visible, or nil.
local function visible_ws_name()
    for name, fl in pairs(floats) do
        if fl.win and vim.api.nvim_win_is_valid(fl.win) then
            return name
        end
    end
    return nil
end

local function active_window_name(ws_name)
    for _, w in ipairs(W.windows(ws_name)) do
        if w.active then
            return w.name
        end
    end
    return nil
end

-- ----------------------------------------------------------------------------
-- Winbar (dots: one per tmux window, active highlighted)
-- ----------------------------------------------------------------------------
local function render_bar(ws_name)
    local dots = ""
    local wins = W.windows(ws_name)
    for i, w in ipairs(wins) do
        local hl = w.active and "TerminalBarActive" or "TerminalBarInactive"
        local dot = w.active and "●" or "○"
        dots = dots .. string.format("%%#%s#%s", hl, dot)
        if i < #wins then
            dots = dots .. " "
        end
    end
    local label = (#wins > 0) and (dots .. "  " .. (#wins .. " win"))
        or (floats[ws_name] and floats[ws_name].title or config.title)
    return string.format("%%#%s#  %s  %%*", config.bar_hl, label)
end

local function refresh_bar(ws_name)
    local fl = floats[ws_name]
    if fl and fl.win and vim.api.nvim_win_is_valid(fl.win) then
        vim.wo[fl.win].winbar = render_bar(ws_name)
    end
end

local function refresh_all_bars()
    for name in pairs(floats) do
        refresh_bar(name)
    end
end

-- Light poll while a float is open: keeps dots truthful when windows die or
-- get created from inside tmux. Stops as soon as no float is visible.
local function sync_poll_start()
    if poll_timer then
        return
    end
    poll_timer = vim.loop.new_timer()
    poll_timer:start(config.sync_ms, config.sync_ms, function()
        vim.schedule(function()
            if visible_ws_name() == nil then
                if poll_timer then
                    poll_timer:stop()
                    poll_timer:close()
                    poll_timer = nil
                end
                return
            end
            refresh_all_bars()
        end)
    end)
end

-- ----------------------------------------------------------------------------
-- Float machinery (geometry + attach job)
-- ----------------------------------------------------------------------------
local function float_geo(name, opts)
    opts = opts or {}
    local screen_width = vim.o.columns
    local screen_height = vim.o.lines

    local width = math.floor(screen_width * (opts.width or config.width))
    local height = math.floor(screen_height * (opts.height or config.height))
    local row = math.floor((screen_height - height) / 2)
    local col = math.floor((screen_width - width) / 2)

    local position = opts.position or "center"
    if position == "right" then
        col = screen_width - width - 2
    elseif position == "left" then
        col = 2
    end

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

local function hide_float(name)
    local fl = floats[name]
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
    floats[name] = nil
end

local function hide_all_floats()
    for name in pairs(floats) do
        hide_float(name)
    end
end

--- Show (or re-attach) the float for a workspace.
local function show_workspace(name, opts)
    opts = opts or {}
    if not W._tmux.available() then
        vim.notify("tmux is required for terminal workspaces (not in PATH)", vim.log.levels.ERROR)
        return
    end

    local ws = W.ensure(name)
    if not ws then
        return
    end
    name = ws.name

    -- One float at a time: hide anything else visible first.
    for other in pairs(floats) do
        if other ~= name then
            hide_float(other)
        end
    end

    local fl = floats[name]
    if fl and fl.win and vim.api.nvim_win_is_valid(fl.win) then
        vim.api.nvim_set_current_win(fl.win)
        refresh_bar(name)
        if not opts.stay_normal then
            vim.cmd("startinsert")
        end
        return
    end
    hide_float(name)

    fl = {
        title = opts.title or ("Workspace: " .. name),
        position = opts.position,
        killing = false,
        detaching = false,
    }
    floats[name] = fl

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
    pcall(function()
        vim.bo[buf].scrollback = config.scrollback
    end)
    fl.buf = buf

    local close_key = opts.close_key or config.close_key
    vim.api.nvim_buf_set_keymap(
        buf,
        "t",
        close_key,
        string.format([[<C-\><C-n><cmd>lua require("mlamkadm.core.terminal").hide("%s")<CR>]], name),
        { noremap = true, silent = true }
    )
    vim.api.nvim_buf_set_keymap(buf, "t", "<C-Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })

    local geo = float_geo(name, opts)
    local win = vim.api.nvim_open_win(buf, true, geo)
    vim.api.nvim_win_set_option(win, "winblend", config.winblend)
    fl.win = win
    vim.wo[win].winbar = render_bar(name)

    -- Attach to the daemon session. env -u TMUX guards against nesting
    -- refusal when nvim itself runs inside tmux (see W.attach_cmd).
    local job = vim.fn.termopen(W.attach_cmd(ws.session), {
        on_exit = function(_job_id, _code, _event)
            local cur = floats[name]
            if not cur or cur.job ~= job then
                return -- stale callback (float was rebuilt)
            end
            if cur.killing or cur.detaching then
                floats[name] = nil
                return
            end
            -- Unexpected client exit: usually the session died (last window
            -- exited inside tmux). Purge the journal entry if so.
            local rec = W.lookup(name)
            if rec and not rec.live then
                W.remove(name)
                vim.notify("Workspace '" .. name .. "' ended (no windows left)", vim.log.levels.INFO)
            end
            hide_float(name)
            refresh_all_bars()
        end,
    })
    fl.job = job

    sync_poll_start()
    if not opts.stay_normal then
        vim.cmd("startinsert")
    end
end

-- ----------------------------------------------------------------------------
-- Public API (consumer contract — signatures preserved)
-- ----------------------------------------------------------------------------

--- Toggle a cmd-keyed singleton window in the active workspace.
-- Old behavior preserved: same cmd → same window; float showing that
-- window → <key> hides the float (process keeps running in the daemon).
function M.toggle(id_or_cmd, opts, stay_normal)
    if type(id_or_cmd) ~= "string" then
        vim.notify("terminal.toggle expects a command string", vim.log.levels.WARN)
        return
    end
    opts = opts or {}

    local ws_name = active_ws_name()
    local key = W._safe_window_name(opts.key or id_or_cmd)

    -- Strict toggle: visible float already on this singleton → hide it.
    local fl = floats[ws_name]
    if fl and fl.win and vim.api.nvim_win_is_valid(fl.win) then
        if active_window_name(ws_name) == key then
            hide_float(ws_name)
            return
        end
    end

    local r = W.open_window(ws_name, id_or_cmd, { key = key, cwd = opts.cwd })
    if not r then
        vim.notify("failed to open terminal window", vim.log.levels.ERROR)
        return
    end
    show_workspace(ws_name, {
        stay_normal = stay_normal,
        position = opts.position,
        title = opts.title,
        width = opts.width,
        height = opts.height,
    })
end

-- Wrapper for _G.Poptui compatibility
function M.toggle_popup(cmd, position, opts)
    opts = opts or {}
    opts.position = position or opts.position
    M.toggle(cmd, opts)
end

--- Create a fresh terminal window (no singleton) and focus it.
function M.new_term(cmd, opts)
    opts = opts or {}
    local ws_name = active_ws_name()
    local r = W.open_window(ws_name, cmd or vim.o.shell, {
        cwd = opts.cwd,
        once = true, -- always a fresh instance
    })
    if not r then
        return nil
    end
    show_workspace(ws_name, { stay_normal = true, position = opts.position })
    return r
end

--- <C-t>: strict toggle of the active workspace float.
function M.toggle_last_active()
    local name = active_ws_name()
    local fl = floats[name]
    if fl and fl.win and vim.api.nvim_win_is_valid(fl.win) then
        hide_float(name)
        return
    end
    show_workspace(name, { stay_normal = false })
end

--- Explicitly hide a workspace float (terminal-mode <C-t> uses this).
function M.hide(name)
    hide_float(name or visible_ws_name())
end

--- <C-j>/<C-k>: cycle windows of the visible workspace (normal mode only).
function M.cycle_next()
    local name = visible_ws_name()
    if not name then
        return
    end
    if W.cycle(name, "next") then
        refresh_bar(name)
    end
end

function M.cycle_prev()
    local name = visible_ws_name()
    if not name then
        return
    end
    if W.cycle(name, "prev") then
        refresh_bar(name)
    end
end

--- <C-d>: kill the active window of the visible workspace (real teardown —
-- process group SIGTERM→SIGKILL, see workspace.kill_window). If it was the
--- last window the workspace dies and the float drops.
function M.kill_current()
    local name = visible_ws_name() or active_ws_name()
    local cur = active_window_name(name)
    if not cur then
        vim.notify("No terminal window to kill", vim.log.levels.INFO)
        return
    end
    local died = W.kill_window(name, cur)
    if died then
        -- kill_window removed the workspace; drop its float.
        local fl = floats[name]
        if fl then
            fl.killing = true
            hide_float(name)
        end
        refresh_all_bars()
        return
    end
    refresh_bar(name)
end

--- Windows of the active workspace, shaped like the old registry entries so
--- consumers (lualine count, switch picker) work unchanged.
function M.list_terminals()
    local ws_name = active_ws_name()
    local list = {}
    for _, w in ipairs(W.windows(ws_name)) do
        table.insert(list, {
            id = w.index,
            cmd = w.cmd,
            open = w.active,
            name = "Term " .. w.index .. ": " .. w.name,
            win = w.name,
        })
    end
    return list
end

--- <leader>ts: pick a window of the active workspace and select it.
function M.switch_terminal()
    local ws_name = active_ws_name()
    local terms = M.list_terminals()
    if #terms == 0 then
        vim.notify("No terminal windows", vim.log.levels.INFO)
        return
    end

    W.portrait_picker("Switch Terminal", terms, function(entry)
        return {
            value = entry,
            display = (entry.open and "[*] " or "[ ] ") .. entry.name,
            ordinal = entry.name,
        }
    end, function(term)
        W._tmux.select_window(W.session_of(ws_name), term.win)
        show_workspace(ws_name, { stay_normal = true })
    end)
end

-- ----------------------------------------------------------------------------
-- Workspace-level UI
-- ----------------------------------------------------------------------------
function M.open_workspace(name)
    W.set_active(name)
    show_workspace(name, {})
end

--- <leader>tw: pick a workspace and open its float.
function M.switch_workspace()
    W.pick_workspace(function(name)
        M.open_workspace(name)
    end)
end

--- <leader>tN: new named workspace.
function M.new_workspace()
    vim.ui.input({ prompt = "New workspace name: " }, function(input)
        input = vim.trim(input or "")
        if input == "" then
            return
        end
        M.open_workspace(input)
    end)
end

--- <leader>tK: pick a workspace, confirm, then RIGID-kill it (SIGTERM→
--- SIGKILL of every process group + journal purge — nothing resurrects).
function M.kill_workspace()
    W.pick_workspace(function(name)
        local n = #W.windows(name)
        vim.ui.select({ "Kill '" .. name .. "' (" .. n .. " windows)", "Cancel" }, {
            prompt = "Rigid kill: SIGTERM→SIGKILL all processes, no resurrect.",
        }, function(choice)
            if not choice or choice == "Cancel" or not vim.startswith(choice, "Kill") then
                return
            end
            local fl = floats[name]
            if fl then
                fl.killing = true
                hide_float(name)
            end
            local swept = W.remove(name)
            -- Follow post-kill state instead of assuming 'primary'.
            local next_active = W.active_name()
            if next_active and next_active ~= name then
                M.open_workspace(next_active)
            end
            vim.notify(
                string.format("Workspace '%s' killed (%d process group(s) SIGKILL'd)", name, swept),
                vim.log.levels.INFO
            )
            refresh_all_bars()
        end)
    end)
end

--- Kill every workspace (all projects' sessions + journals). Global clean
--- slate — replaces the old alpha-dashboard "Kill Zellij Sessions" button.
function M.kill_all_workspaces()
    hide_all_floats()
    local n = W.kill_all()
    vim.notify(
        (n == 0 and "No workspace sessions to kill" or (n .. " workspace session(s) killed")),
        vim.log.levels.INFO
    )
end

-- ----------------------------------------------------------------------------
-- TUI Registry
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
        -- Singleton per command (stable window key), same as before.
        M.toggle(sel.cmd, { position = sel.position, title = sel.name })
    end)
end

-- ----------------------------------------------------------------------------
-- Persistence (auto-session hooks + exit) — delegates to the journal
-- ----------------------------------------------------------------------------
function M.save_session()
    W.save()
end

function M.restore_session()
    local ws = W.resurrect()
    if not ws then
        return
    end
    -- Re-open the last-active workspace's float (stay in normal mode).
    local name = ws.name
    vim.schedule(function()
        show_workspace(name, { stay_normal = true })
    end)
end

function M.cleanup(opts)
    opts = opts or {}
    if opts.save then
        M.save_session()
    end
    -- Detach every float; the tmux sessions keep running headless and are
    -- re-attachable from anywhere (that IS the persistence story now).
    hide_all_floats()
    if opts.delete_buffers then
        for name in pairs(floats) do
            floats[name] = nil
        end
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

    -- Register default TUIs (all of them become daemon-backed singleton
    -- windows now, so they survive nvim restarts).
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

    -- Detach (never kill) and persist the journal on exit. The tmux daemon
    -- keeps every process running for the next resurrect.
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            M.save_session()
            M.cleanup({})
        end,
        desc = "Save workspace journal and detach terminal floats on exit",
    })
end

-- ----------------------------------------------------------------------------
-- Keymaps
-- ----------------------------------------------------------------------------
-- <C-t>  : toggle the active workspace float (detach on hide — the daemon
--          keeps the processes; re-open re-attaches to the live session).
-- <C-j>  : cycle to the next terminal window (only while a float is visible).
-- <C-k>  : cycle to the previous terminal window.
-- <C-n>  : open a NEW terminal window in the active workspace (fresh shell).
-- <C-d>  : kill the active terminal window (SIGTERM→SIGKILL group teardown);
--          the last window of a workspace takes the workspace with it.
--          NOTE: `<C-d>` is also mapped by smooth-scroll (neoscroll); terminal
--          owns it here, so smooth-scroll's <C-d> is intentionally disabled.
-- <leader>tw : workspace switcher (telescope picker).
-- <leader>tN : new named workspace.
-- <leader>tK : kill workspace (picker → confirm → rigid kill).
-- <leader>ts : switch terminal window (picker).
-- <leader>tt : TUI registry (each entry = singleton daemon window).
vim.keymap.set("n", "<C-t>", M.toggle_last_active, { desc = "Terminal: Toggle workspace float" })
vim.keymap.set("n", "<C-j>", M.cycle_next, { desc = "Terminal: Next window" })
vim.keymap.set("n", "<C-k>", M.cycle_prev, { desc = "Terminal: Prev window" })
vim.keymap.set("n", "<C-n>", function()
    M.new_term(vim.o.shell, {})
end, { desc = "Terminal: New window in workspace" })
vim.keymap.set("n", "<C-d>", M.kill_current, { desc = "Terminal: Kill current window" })
vim.keymap.set("n", "<leader>tw", M.switch_workspace, { desc = "Workspaces: Switch" })
vim.keymap.set("n", "<leader>tN", M.new_workspace, { desc = "Workspaces: New" })
vim.keymap.set("n", "<leader>tK", M.kill_workspace, { desc = "Workspaces: Kill (rigid)" })
vim.keymap.set("n", "<leader>ts", M.switch_terminal, { desc = "Switch Terminal window" })
vim.keymap.set("n", "<leader>tt", M.show_tui_registry, { desc = "TUI Registry" })

-- Singleton TUI keys (each opens/focuses one daemon-backed window)
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
