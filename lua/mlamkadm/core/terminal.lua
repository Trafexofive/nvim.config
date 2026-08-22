-- /lua/mlamkadm/core/terminal.lua
-- Advanced Terminal Management System
-- Handles multiple terminal instances, persistence, and session integration.

local M = {}

-- ----------------------------------------------------------------------------
-- Configuration
-- ----------------------------------------------------------------------------
local config = {
    -- No border: the popup is a clean rectangle with a winbar (top status bar)
    -- instead of a titled outline. This removes all "|" / "-" border glyphs.
    border = "none",
    width = 0.9,   -- unified terminal float width (regular + zellij)
    height = 0.85, -- unified terminal float height (regular + zellij)
    title = "Terminal",
    title_pos = "center", -- center | left | right
    -- Highlight group for the winbar (top dynamic status bar).
    bar_hl = "TerminalBar",
    close_key = "<C-t>",
    winblend = 0,
    zindex = 50,
    scrollback = 100000,
    -- Session persistence: save/restore the tracked terminal registry (cmd per
    -- terminal + open flag) so ALL terminals come back on restart, not just the
    -- last one. zellij re-attach is safe: `zellij attach --create` reattaches to
    -- the existing session rather than spawning a duplicate client.
    persistence = {
        enabled = true,
        save_file = vim.fn.stdpath("data") .. "/terminal_session.json",
    }
}

-- ----------------------------------------------------------------------------
-- State
-- ----------------------------------------------------------------------------
-- Store terminal instances
-- structure: { id = number, cmd = string, buf = number, win = number, opts = table, history = table }
local terminals = {}
local next_id = 1
local last_active_id = nil

-- Is this tracked terminal not a zombie? A terminal is a zombie when it has
-- no buffer AND no window (killed/detached but never removed from the
-- registry). Such entries must not render a bar dot.
local function is_live(term)
    if not term then return false end
    if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
        return true
    end
    if term.win and vim.api.nvim_win_is_valid(term.win) then
        return true
    end
    -- Just created (open flag true, buffer not yet materialized).
    return term.open == true
end

-- Registry of TUI commands for quick access
local tui_registry = {}
local new_zellij_counter = 0

local function project_session_name()
    local cwd = vim.fn.getcwd()
    local name = vim.fn.fnamemodify(cwd, ":t")
    if name == "" then name = "home" end
    name = name:gsub("[^%w_.-]", "-")
    return "nvim-" .. name .. "-" .. vim.fn.sha256(cwd):sub(1, 8)
end

function M.zellij_cmd(session)
    session = session or project_session_name()
    return "zellij attach --create " .. vim.fn.shellescape(session)
end

-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------

local function get_term_by_buf(buf)
    for _, term in pairs(terminals) do
        if term.buf == buf then return term end
    end
    return nil
end

local function get_term_by_cmd(cmd)
    for _, term in pairs(terminals) do
        if term.cmd == cmd then return term end
    end
    return nil
end

local function create_float(term)
    local screen_width = vim.o.columns
    local screen_height = vim.o.lines
    
    local width_ratio = term.opts.width or config.width
    local height_ratio = term.opts.height or config.height
    
    local width = math.floor(screen_width * width_ratio)
    local height = math.floor(screen_height * height_ratio)
    
    local row = math.floor((screen_height - height) / 2)
    local col = math.floor((screen_width - width) / 2)
    
    local position = term.opts.position or 'center'
    if position == 'right' then
        col = screen_width - width - 2
    elseif position == 'left' then
        col = 2
    end
    
    local title = term.opts.title or config.title
    -- If title is default, try to derive from command
    if title == config.title and term.cmd then
         local cmd_name = term.cmd:match("^(%S+)") or term.cmd
         title = cmd_name:gsub("^%l", string.upper) .. " (" .. term.id .. ")"
    end
    -- Store the bar title on the term so M.toggle can render the winbar.
    term._bar_title = title

    local win_opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        border = config.border, -- "none": no outline, no "|" / "-"
        style = 'minimal',
        zindex = config.zindex,
    }
    
    return win_opts
end

--- Render the top status bar for one terminal: pagination dots, one per
-- tracked terminal (in id order), with the ACTIVE one highlighted and the
-- rest dimmed. No name — the zellij HUD shows the session.
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
        if i < #ids then bar = bar .. " " end
    end
    if bar == "" then
        bar = term._bar_title or config.title -- fallback (no tracked terminals)
    end
    return string.format("%%#%s#  %s  %%*", config.bar_hl, bar)
end

--- Re-render the winbar on every open terminal window so the dots stay in
-- sync as terminals are created/closed/cycled.
local function refresh_bars()
    for _, t in pairs(terminals) do
        if t.win and vim.api.nvim_win_is_valid(t.win) then
            vim.wo[t.win].winbar = render_bar(t)
        end
    end
end

--- Set the winbar on a newly-opened terminal window and sync all others.
local function set_terminal_bar(term)
    refresh_bars()
end

-- ----------------------------------------------------------------------------
-- Core Terminal Management
-- ----------------------------------------------------------------------------

--- Create a new terminal instance
-- @param cmd string: Command to run
-- @param opts table: Options
function M.create_term(cmd, opts)
    opts = opts or {}
    local id = next_id
    next_id = next_id + 1
    
    local term = {
        id = id,
        cmd = cmd or vim.o.shell,
        opts = opts,
        buf = nil,
        win = nil,
        open = false
    }
    
    terminals[id] = term
    return term
end

--- Toggle a terminal window
-- @param id_or_cmd: Terminal ID or command string
-- @param opts: Options if creating a new one
function M.toggle(id_or_cmd, opts, stay_normal)
    local term
    opts = opts or {}

    -- Find terminal
    if type(id_or_cmd) == "number" then
        term = terminals[id_or_cmd]
    else
        -- Try to find by command (singleton behavior for named commands)
        term = get_term_by_cmd(id_or_cmd)
        if not term then
            term = M.create_term(id_or_cmd, opts)
        end
    end

    if not term then return end

    -- Determine position from args or stored opts
    if opts.position then term.opts.position = opts.position end

    -- If open, hide it
    if term.win and vim.api.nvim_win_is_valid(term.win) then
        vim.api.nvim_win_close(term.win, false) -- Hide
        term.win = nil
        term.open = false
        last_active_id = term.id
        refresh_bars()
        return
    end

    -- Create buffer if needed
    if not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
        term.buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(term.buf, 'bufhidden', 'hide')
        
        -- Setup keymaps for this buffer
        local close_key = term.opts.close_key or config.close_key
        local opts_map = { noremap = true, silent = true }
        
        vim.api.nvim_buf_set_keymap(term.buf, 't', close_key, [[<C-\><C-n><cmd>lua require("mlamkadm.core.terminal").toggle(]] .. term.id .. [[)<CR>]], opts_map)
        vim.api.nvim_buf_set_keymap(term.buf, 't', '<C-Esc>', [[<C-\><C-n>]], opts_map)
        -- We don't map <C-d> to close automatically, let the shell handle it, or exit
    end

    -- Create window
    local win_opts = create_float(term)
    term.win = vim.api.nvim_open_win(term.buf, true, win_opts)
    vim.api.nvim_win_set_option(term.win, 'winblend', config.winblend)
    set_terminal_bar(term) -- top dynamic status bar (no outline)
    term.open = true
    last_active_id = term.id

    -- Start terminal if not running
    if vim.bo[term.buf].buftype ~= "terminal" then
        local cmd = term.cmd
        local use_theme = term.opts.use_theme ~= false
        
        local term_opts = {
            on_exit = function(job_id, code, event)
                -- Always clear the registry entry on exit (clean or not), so
                -- detached/killed zellij sessions don't linger as zombie dots.
                if term.win and vim.api.nvim_win_is_valid(term.win) then
                    pcall(vim.api.nvim_win_close, term.win, true)
                    term.win = nil
                    term.open = false
                end
                if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
                    pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
                    term.buf = nil
                end
                if terminals[term.id] then
                    terminals[term.id] = nil -- Remove from registry
                end
                if last_active_id == term.id then
                    last_active_id = nil
                end
                refresh_bars()
            end
        }
        
        if not use_theme then
            term_opts.env = { TERM = "xterm-256color" }
        end
        
        vim.fn.termopen(cmd, term_opts)
    end
    
    if not stay_normal then
        vim.cmd("startinsert")
    end
end

-- Wrapper for _G.Poptui compatibility
function M.toggle_popup(cmd, position, opts)
    opts = opts or {}
    if position then opts.position = position end
    M.toggle(cmd, opts)
end

function M.open_zellij(opts)
    opts = opts or {}
    if vim.fn.executable("zellij") ~= 1 then
        vim.notify("zellij is not installed or not in PATH", vim.log.levels.ERROR)
        return
    end

    local session = project_session_name()
    local cmd = M.zellij_cmd()

    -- Strict toggle of the primary zellij terminal: if it's already visible,
    -- close it. Otherwise hide any other visible terminal floats and open it, so
    -- Ctrl+T always shows exactly the zellij terminal (never "cycles").
    local term = get_term_by_cmd(cmd)
    if term and term.win and vim.api.nvim_win_is_valid(term.win) then
        pcall(vim.api.nvim_win_close, term.win, false)
        term.win = nil
        term.open = false
        last_active_id = term.id
        return
    end

    for _, t in pairs(terminals) do
        if t ~= term and t.win and vim.api.nvim_win_is_valid(t.win) then
            pcall(vim.api.nvim_win_close, t.win, false)
            t.win = nil
            t.open = false
        end
    end

    M.toggle(cmd, vim.tbl_deep_extend("force", {
        title = "Zellij: " .. session,
        use_theme = false,
    }, opts))
end

-- Open a NEW zellij session (a fresh zellij terminal), unlike Ctrl+T which
-- toggles the project's primary session. Each new terminal gets its own
-- zellij session so CLI state persists independently.
function M.open_new_zellij(opts)
    opts = opts or {}
    if vim.fn.executable("zellij") ~= 1 then
        vim.notify("zellij is not installed or not in PATH", vim.log.levels.ERROR)
        return
    end
    -- Avoid stacking popups: hide any currently-visible terminal first so only
    -- the new one shows. Without this, <C-t> then <C-n> leaves two floats
    -- visible, and the next <C-j> closes both (it sees the other float as
    -- "open" and toggles it shut) → the popup "drops".
    for _, t in pairs(terminals) do
        if t.win and vim.api.nvim_win_is_valid(t.win) then
            pcall(vim.api.nvim_win_close, t.win, false)
            t.win = nil
            t.open = false
        end
    end
    new_zellij_counter = new_zellij_counter + 1
    local session = project_session_name() .. "-" .. new_zellij_counter
    M.toggle(M.zellij_cmd(session), vim.tbl_deep_extend("force", {
        title = "Zellij: " .. session,
        use_theme = false,
    }, opts))
end

-- Kill all running (headless/detached) zellij sessions.
-- Running sessions show no status suffix in `zellij list-sessions`; EXITED
-- snapshots ("attach to resurrect") are left alone. Safe to run from the alpha
-- dashboard at nvim startup when nothing is attached to a zellij client.
function M.kill_all_zellij_sessions()
    if vim.fn.executable("zellij") ~= 1 then
        vim.notify("zellij is not installed or not in PATH", vim.log.levels.ERROR)
        return
    end

    local out = vim.fn.system("zellij list-sessions")
    -- Strip ANSI color escape sequences.
    local plain = out:gsub("\27%[[0-9;]*m", "")
    local killed = 0
    for line in plain:gmatch("[^\n]+") do
        if not line:find("EXITED", 1, true) then
            local name = line:match("^%s*(%S+)")
            if name and name ~= "" then
                vim.fn.system("zellij kill-session " .. vim.fn.shellescape(name))
                killed = killed + 1
            end
        end
    end
    vim.notify((killed == 0 and "No headless zellij sessions to kill" or (killed .. " headless zellij session(s) killed")), vim.log.levels.INFO)
end

function M.cleanup(opts)
    opts = opts or {}
    local delete_buffers = opts.delete_buffers == true

    if opts.save then
        M.save_session()
    end

    for id, term in pairs(terminals) do
        if term.win and vim.api.nvim_win_is_valid(term.win) then
            pcall(vim.api.nvim_win_close, term.win, true)
        end
        term.win = nil
        term.open = false

        if delete_buffers and term.buf and vim.api.nvim_buf_is_valid(term.buf) then
            pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
            terminals[id] = nil
        end
    end

    if delete_buffers then
        last_active_id = nil
    end
end

-- ----------------------------------------------------------------------------
-- Navigation & Management
-- ----------------------------------------------------------------------------

function M.list_terminals()
    local list = {}
    for id, term in pairs(terminals) do
        table.insert(list, {
            id = id,
            cmd = term.cmd,
            buf = term.buf,
            open = term.open,
            name = "Term " .. id .. ": " .. term.cmd
        })
    end
    return list
end

--- Create a fresh terminal instance (no singleton) and open it
-- @param cmd string: command to run (defaults to $SHELL)
-- @param opts table: options
-- @return term: the newly created terminal entry
function M.new_term(cmd, opts)
    local term = M.create_term(cmd or vim.o.shell, opts)
    -- Avoid stacking popups: hide any currently visible terminal first, so only
    -- one float is shown at a time (cycle with <C-j>/<C-k> to move between them).
    for _, t in pairs(terminals) do
        if t.win and vim.api.nvim_win_is_valid(t.win) then
            pcall(vim.api.nvim_win_close, t.win, false)
            t.win = nil
            t.open = false
        end
    end
    M.toggle(term.id)
    return term
end

--- Find the currently visible terminal id, or nil if none is open.
local function visible_id()
    for id, term in pairs(terminals) do
        if term.win and vim.api.nvim_win_is_valid(term.win) then
            return id
        end
    end
    return nil
end

--- Toggle the LAST-ACTIVE terminal float, remembering which one before hiding.
--
-- Behavior:
--   * A terminal float is visible  → close it and remember it as the
--     last-active, so the next <C-t> restores THIS one, not the primary.
--   * Nothing is visible           → reopen the remembered last-active terminal
--     (falling back to the first tracked one if none was remembered).
--   * No tracked terminals at all  → open the primary zellij session.
--
-- This is the strict toggle the user wants from <C-t>: it never "cycles" to
-- the first session — it always comes back to the one you were last using.
--- Sorted ids of live (running) tracked terminals only.
--- Find the index of `id` in the sorted ids list, or nil.
local function index_of(ids, id)
    for i, v in ipairs(ids) do
        if v == id then return i end
    end
    return nil
end

--- Is the tracked terminal's process actually live?
-- Returns false if the buf was never a terminal, was deleted, or the job died
-- (channel closed). Used to filter dead entries out of the cycle.
local function is_alive(term)
    if not term then return false end
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
    -- Alive terminals have a real pty path. Dead/jobstop-ed channels
    -- keep the channel handle but pty becomes an empty string.
    return info.pty ~= nil and info.pty ~= ""
end

--- Remove dead tracked terminals from the registry.
-- A terminal is dead if its buf is invalid, no longer a terminal buffer, or
-- its job channel is closed. We close the float and stop the job before
-- dropping the entry so we don't leave orphan windows/jobs behind.
local function reap_dead()
    for id, term in pairs(terminals) do
        if not is_alive(term) then
            if term.win and vim.api.nvim_win_is_valid(term.win) then
                pcall(vim.api.nvim_win_close, term.win, true)
                term.win = nil
                term.open = false
            end
            if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
                pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
                term.buf = nil
            end
            terminals[id] = nil
            if last_active_id == id then
                last_active_id = nil
            end
        end
    end
end

--- Sorted ids of live (running) tracked terminals only.
local function alive_ids()
    local ids = {}
    for id, term in pairs(terminals) do
        if is_alive(term) then table.insert(ids, id) end
    end
    table.sort(ids)
    return ids
end

--- Strict toggle for <C-t>: pull the terminal popup DOWN if it's showing,
-- or pull it UP (restore the last-active live terminal, else the primary
-- zellij session) if nothing is showing. Never cycles, never drops.
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

    -- Nothing visible: restore the last-active live terminal if possible.
    if last_active_id and terminals[last_active_id] and is_alive(terminals[last_active_id]) then
        M.toggle(last_active_id)
        return
    end

    -- Fallback: first live tracked terminal.
    local ids = alive_ids()
    if #ids > 0 then
        M.toggle(ids[1])
        return
    end

    -- No tracked live terminals at all → open the primary zellij session.
    M.open_zellij()
end

--- Cycle to the next live terminal; wrap at end. Only cycles when a
-- terminal is actually showing and there are 2+ live ones. Never drops the
-- popup: it only closes the current AFTER picking a confirmed-live next
-- target, and only if that target is valid to open. No-op otherwise.
function M.cycle_next()
    local cur = visible_id()
    if not cur then return end -- don't intrude when no terminal is showing

    local ids = alive_ids()
    local n = #ids
    if n < 2 then return end

    local cur_idx = index_of(ids, cur)
    if not cur_idx then return end -- visible one isn't in the live set

    local target = ids[(cur_idx % n) + 1]
    if not terminals[target] then return end

    local cur_term = terminals[cur]
    if cur_term.win and vim.api.nvim_win_is_valid(cur_term.win) then
        pcall(vim.api.nvim_win_close, cur_term.win, false)
        cur_term.win = nil
        cur_term.open = false
    end
    M.toggle(target, nil, true)
end

--- Cycle to the previous live terminal; wrap at start. Same guarantees as
-- cycle_next: only when a terminal is showing and 2+ live ones exist; never
-- drops the popup.
function M.cycle_prev()
    local cur = visible_id()
    if not cur then return end

    local ids = alive_ids()
    local n = #ids
    if n < 2 then return end

    local cur_idx = index_of(ids, cur)
    if not cur_idx then return end

    local target = ids[((cur_idx - 2) % n) + 1]
    if not terminals[target] then return end

    local cur_term = terminals[cur]
    if cur_term.win and vim.api.nvim_win_is_valid(cur_term.win) then
        pcall(vim.api.nvim_win_close, cur_term.win, false)
        cur_term.win = nil
        cur_term.open = false
    end
    M.toggle(target, nil, true)
end

--- Kill a terminal by id: stop the job, close the window, delete the buffer,
-- and remove it from the registry.
function M.kill_term(id)
    local term = terminals[id]
    if not term then return end

    if term.win and vim.api.nvim_win_is_valid(term.win) then
        pcall(vim.api.nvim_win_close, term.win, true)
        term.win = nil
        term.open = false
    end

    if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
        local chan = vim.b[term.buf].terminal_job_id
        if chan and chan > 0 then
            pcall(vim.fn.jobstop, chan)
        end
        pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
    end

    terminals[id] = nil
    refresh_bars()
    if last_active_id == id then
        last_active_id = nil
    end
end

--- Kill the currently visible terminal (falls back to the last-active one).
-- Instead of just dropping the popup, it then pulls up the next live
-- terminal (wrapping) so the terminal window stays focused.
function M.kill_current()
    local target = visible_id() or last_active_id
    if not target or not terminals[target] then
        vim.notify("No terminal to kill", vim.log.levels.INFO)
        return
    end

    -- Pick the next live terminal to show AFTER the kill (wrap at end).
    local ids = alive_ids()
    local n = #ids
    local next_id = nil
    local t_idx = index_of(ids, target)
    if t_idx and n > 1 then
        next_id = ids[(t_idx % n) + 1]
    elseif n > 1 then
        next_id = ids[1]
    end

    M.kill_term(target)

    -- Keep the popup up with the next terminal (stay in normal mode, like
    -- cycling). If nothing is left, the popup naturally drops.
    if next_id and terminals[next_id] then
        M.toggle(next_id, nil, true)
    end
end

function M.switch_terminal()
    local terms = M.list_terminals()
    if #terms == 0 then
        vim.notify("No active terminals", vim.log.levels.INFO)
        return
    end

    -- Use Telescope
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    pickers.new({}, {
        prompt_title = 'Switch Terminal',
        finder = finders.new_table {
            results = terms,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = (entry.open and "[*] " or "[ ] ") .. entry.name,
                    ordinal = entry.name,
                }
            end,
        },
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    M.toggle(selection.value.id)
                end
            end)
            return true
        end,
    }):find()
end

-- ----------------------------------------------------------------------------
-- TUI Registry
-- ----------------------------------------------------------------------------

function M.register_tui(name, cmd, position, opts)
    table.insert(tui_registry, {
        name = name,
        cmd = cmd,
        position = position,
        opts = opts or {}
    })
end

function M.show_tui_registry()
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    pickers.new({}, {
        prompt_title = 'TUI Commands',
        finder = finders.new_table {
            results = tui_registry,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = string.format("%-20s → %s", entry.name, entry.cmd),
                    ordinal = entry.name .. " " .. entry.cmd,
                }
            end,
        },
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    -- Create a new instance for this TUI, or toggle if it's a singleton (based on cmd)
                    -- For TUIs, we generally want singletons per command
                    M.toggle(selection.value.cmd, { 
                        position = selection.value.position,
                        title = selection.value.name,
                        use_theme = selection.value.opts.use_theme
                    })
                end
            end)
            return true
        end,
    }):find()
end

-- Persistence
local function get_session_path()
    local data_dir = vim.fn.stdpath("data") .. "/term_sessions"
    if vim.fn.isdirectory(data_dir) == 0 then
        vim.fn.mkdir(data_dir, "p")
    end
    local cwd = vim.fn.getcwd()
    -- Encode path: replace / with %
    local filename = cwd:gsub("/", "%%") .. ".json"
    return data_dir .. "/" .. filename
end

function M.save_session()
    if not config.persistence.enabled then return end
    
    local session_data = {}
    for id, term in pairs(terminals) do
        if term.cmd then
            table.insert(session_data, {
                cmd = term.cmd,
                opts = term.opts,
                is_open = term.open
            })
        end
    end
    
    local path = get_session_path()
    local file = io.open(path, "w")
    if file then
        file:write(vim.json.encode(session_data))
        file:close()
    end
end

function M.restore_session()
    if not config.persistence.enabled then return end
    
    local path = get_session_path()
    local file = io.open(path, "r")
    if not file then return end
    
    local content = file:read("*a")
    file:close()
    
    local ok, session_data = pcall(vim.json.decode, content)
    if not ok or type(session_data) ~= "table" then return end

    -- Rebuild the registry from the saved snapshot WITHOUT clobbering any
    -- terminals already tracked (guards against double-restore from both
    -- auto-session hooks firing).
    local seen = {}
    for _, t in pairs(terminals) do
        if t.cmd then seen[t.cmd] = true end
    end

    local restored = 0
    local first_id = nil
    for _, data in ipairs(session_data) do
        if not data.cmd or data.cmd == "" then
            goto continue
        end
        -- Dedupe by cmd so a re-run doesn't stack duplicate entries.
        if seen[data.cmd] then
            goto continue
        end
        local term = M.create_term(data.cmd, data.opts)
        seen[data.cmd] = true
        restored = restored + 1
        if not first_id then first_id = term.id end
        ::continue::
    end

    -- Re-open every terminal that was open at save time. This is the fix for
    -- "only the first/last session comes back" — previously only the last
    -- `is_open` entry was being scheduled to an already-reused id.
    for _, data in ipairs(session_data) do
        if data.is_open and data.cmd and data.cmd ~= "" then
            local term = nil
            for id, t in pairs(terminals) do
                if t.cmd == data.cmd and not t.win then term = t; break end
            end
            if term then
                vim.schedule(function()
                    if terminals[term.id] and not terminals[term.id].win then
                        M.toggle(term.id, nil, true) -- stay in normal mode
                    end
                end)
            end
        end
    end

    -- If nothing was flagged open but we restored terminals, set last-active
    -- to the first one so <C-t> brings up the right terminal.
    if first_id then
        last_active_id = first_id
    end

    -- Silent restore, no notification to avoid clutter
end

-- ----------------------------------------------------------------------------
-- Setup
-- ----------------------------------------------------------------------------

function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})

    -- Gruvbox-ish top status bar for terminal popups (no border glyphs).
    -- All three groups share the same bar background so the dots read as one
    -- continuous bar; only the dot glyph/foreground differ (active=bright,
    -- inactive=dim). Re-applied on ColorScheme so it stays themed.
    local function setup_bar_hl()
        vim.api.nvim_set_hl(0, config.bar_hl,          { fg = "#282828", bg = "#83a598", bold = true })
        vim.api.nvim_set_hl(0, "TerminalBarActive",   { fg = "#fbf1c7", bg = "#83a598", bold = true })
        vim.api.nvim_set_hl(0, "TerminalBarInactive", { fg = "#3c3836", bg = "#83a598" })
    end
    setup_bar_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("TerminalBarHighlight", { clear = true }),
        callback = setup_bar_hl,
        desc = "Re-apply terminal bar highlight on colorscheme change",
    })

    _G.Poptui = M.toggle_popup

    -- Register Default TUIs
    M.register_tui("Terminal", vim.o.shell)
    M.register_tui("Zellij", M.zellij_cmd())
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

    -- Autocmds
    local group = vim.api.nvim_create_augroup("TerminalManager", { clear = true })
    
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            M.save_session()
            for _, term in pairs(terminals) do
                if term.win and vim.api.nvim_win_is_valid(term.win) then
                    vim.api.nvim_win_close(term.win, true)
                end
            end
        end,
        desc = "Close terminal windows and save session on exit"
    })
    
    -- Restore on startup?
    -- Maybe explicitly call it or hook into session load.
end

-- Keymaps
-- <C-t>  : toggle the LAST-ACTIVE terminal (remembers which one before hiding,
--          so reopening always restores the one you were last using, never the
--          first). In terminal mode the buffer-local <C-t> mapping set in
--          M.toggle() still closes the float.
-- <C-j>  : cycle to the next tracked terminal (only when a terminal is visible;
--          stays in normal mode).
-- <C-k>  : cycle to the previous tracked terminal (only when a terminal is
--          visible; stays in normal mode).
-- <C-n>  : open a new Zellij session (each new terminal gets its own session).
-- <C-d>  : kill the currently visible terminal (jobstop + delete buffer).
--          NOTE: `<C-d>` is also mapped by smooth-scroll (neoscroll); terminal
--          owns it here, so smooth-scroll's <C-d> is intentionally disabled.
-- <leader>tz : open the project's primary Zellij session (explicit, non-toggle).
vim.keymap.set('n', '<c-t>', M.toggle_last_active, { desc = 'Terminal: Toggle last-active' })
vim.keymap.set('n', '<C-j>', M.cycle_next, { desc = 'Terminal: Next' })
vim.keymap.set('n', '<C-k>', M.cycle_prev, { desc = 'Terminal: Prev' })
vim.keymap.set('n', '<C-n>', M.open_new_zellij, { desc = 'Terminal: New Zellij session' })
vim.keymap.set('n', '<C-d>', M.kill_current, { desc = 'Terminal: Kill current' })
vim.keymap.set('n', '<leader>tz', M.open_zellij, { desc = 'Open Zellij terminal' })
vim.keymap.set('n', '<leader>ts', M.switch_terminal, { desc = 'Switch Terminal' })
vim.keymap.set('n', '<leader>tt', M.show_tui_registry, { desc = 'TUI Registry' })
vim.keymap.set('n', '<leader>tn', M.open_new_zellij, { desc = 'New Zellij session' })

-- Re-bind the specific TUI keys
vim.keymap.set('n', '<leader>jj', function() M.toggle('lazygit') end, { desc = 'Toggle Lazygit' })
vim.keymap.set('n', '<leader>jd', function() M.toggle('lazydocker') end, { desc = 'Toggle Lazydocker' })
vim.keymap.set('n', '<leader>dl', function() M.toggle('docker-compose logs -f') end, { desc = 'Docker Compose Logs' })
vim.keymap.set('n', '<leader>jt', function() M.toggle('btop', { use_theme = false }) end, { desc = 'Toggle Btop' })
vim.keymap.set('n', '<leader>jf', function() M.toggle('yazi') end, { desc = 'Toggle File Manager (Yazi)' })
vim.keymap.set('n', '<leader>mg', function() M.toggle('glow') end, { desc = 'Make: Glow' })
vim.keymap.set('n', '<leader>mr', function() M.toggle('make run') end, { desc = 'Make: Run' })
vim.keymap.set('n', '<leader>mc', function() M.toggle('make clean') end, { desc = 'Make: Clean' })

return M
