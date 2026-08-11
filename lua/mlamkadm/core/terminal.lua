-- /lua/mlamkadm/core/terminal.lua
-- Advanced Terminal Management System
-- Handles multiple terminal instances, persistence, and session integration.

local M = {}

-- ----------------------------------------------------------------------------
-- Configuration
-- ----------------------------------------------------------------------------
local config = {
    border = "rounded",
    width = 0.9,   -- unified terminal float width (regular + zellij)
    height = 0.85, -- unified terminal float height (regular + zellij)
    title = "Terminal",
    title_pos = "center", -- center | left | right
    close_key = "<C-t>",
    winblend = 0,
    zindex = 50,
    scrollback = 100000,
    -- Session persistence is DISABLED: zellij owns CLI session persistence
    -- (on_force_close detach) and auto-session owns nvim buffers/windows.
    -- Recreating terminal floats (which run `zellij attach --create`) on restore
    -- would attach duplicate clients to already-live sessions.
    persistence = {
        enabled = false,
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

    local win_opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        border = config.border,
        style = 'minimal',
        zindex = config.zindex,
        title = " " .. title .. " ",
        title_pos = config.title_pos,
    }
    
    return win_opts
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
    term.open = true
    last_active_id = term.id

    -- Start terminal if not running
    if vim.bo[term.buf].buftype ~= "terminal" then
        local cmd = term.cmd
        local use_theme = term.opts.use_theme ~= false
        
        local term_opts = {
            on_exit = function(job_id, code, event)
                -- If process exits, we might want to close the window or keep it open?
                -- Usually close it.
                if code == 0 then
                    -- If clean exit, close window and delete buffer
                    if term.win and vim.api.nvim_win_is_valid(term.win) then
                        vim.api.nvim_win_close(term.win, true)
                        term.win = nil
                        term.open = false
                    end
                    if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
                        vim.api.nvim_buf_delete(term.buf, { force = true })
                        term.buf = nil
                    end
                    terminals[term.id] = nil -- Remove from registry
                end
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

--- Cycle to the next tracked terminal; wrap at end.
-- Reaps dead terminals first, so the cycle only visits live ones. Never
-- spawns a new terminal — use <C-n> for that. No-op when 0 or 1 live
-- terminals remain after reaping.
function M.cycle_next()
    reap_dead()

    local ids = {}
    for id in pairs(terminals) do
        table.insert(ids, id)
    end
    table.sort(ids)
    local n = #ids

    if n == 0 then return end

    local cur = visible_id()
    -- Only cycle between already-visible terminals; never pull one up from a
    -- plain buffer (Ctrl+J/K should not intrude when no terminal is showing).
    if not cur then return end
    if n == 1 then return end

    local cur_idx = index_of(ids, cur) or 0
    local target = ids[(cur_idx % n) + 1]

    if target ~= cur then
        local cur_term = terminals[cur]
        if cur_term and cur_term.win and vim.api.nvim_win_is_valid(cur_term.win) then
            pcall(vim.api.nvim_win_close, cur_term.win, false)
            cur_term.win = nil
            cur_term.open = false
        end
        M.toggle(target, nil, true)
    end
end

--- Cycle to the previous tracked terminal; wrap at start.
-- Reaps dead terminals first. Never spawns a new terminal.
function M.cycle_prev()
    reap_dead()

    local ids = {}
    for id in pairs(terminals) do
        table.insert(ids, id)
    end
    table.sort(ids)
    local n = #ids

    if n == 0 then return end

    local cur = visible_id()
    -- Only cycle between already-visible terminals; never pull one up from a
    -- plain buffer (Ctrl+J/K should not intrude when no terminal is showing).
    if not cur then return end
    if n == 1 then return end

    local cur_idx = index_of(ids, cur) or 0
    local target = ids[((cur_idx - 2) % n) + 1]

    if target ~= cur then
        local cur_term = terminals[cur]
        if cur_term and cur_term.win and vim.api.nvim_win_is_valid(cur_term.win) then
            pcall(vim.api.nvim_win_close, cur_term.win, false)
            cur_term.win = nil
            cur_term.open = false
        end
        M.toggle(target, nil, true)
    end
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
    if last_active_id == id then
        last_active_id = nil
    end
end

--- Kill the currently visible terminal; falls back to the last-active one.
function M.kill_current()
    local target = visible_id() or last_active_id
    if not target or not terminals[target] then
        vim.notify("No terminal to kill", vim.log.levels.INFO)
        return
    end
    M.kill_term(target)
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
    
    -- Clear existing terminals from memory to avoid mixing sessions.
    M.cleanup({ delete_buffers = true })
    terminals = {}
    next_id = 1
    
    local path = get_session_path()
    local file = io.open(path, "r")
    if not file then return end
    
    local content = file:read("*a")
    file:close()
    
    local ok, session_data = pcall(vim.json.decode, content)
    if not ok or type(session_data) ~= "table" then return end
    
    for _, data in ipairs(session_data) do
        local term = M.create_term(data.cmd, data.opts)
        if data.is_open then
            vim.schedule(function()
                if terminals[term.id] then
                    M.toggle(term.id)
                end
            end)
        end
    end
    
    -- Silent restore, no notification to avoid clutter
end

-- ----------------------------------------------------------------------------
-- Setup
-- ----------------------------------------------------------------------------

function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})

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
-- <C-t>  : toggle Zellij for this project (attach --create restores the live
--          CLI session's panes/tabs). In terminal mode the buffer-local <C-t>
--          mapping set in M.toggle() still closes the float, so the same key
--          opens/closes whether you're inside the terminal or not.
-- <C-j>  : cycle to the next tracked terminal (only when a terminal is visible;
--          stays in normal mode).
-- <C-k>  : cycle to the previous tracked terminal (only when a terminal is
--          visible; stays in normal mode).
-- <C-n>  : open a new Zellij session (each new terminal gets its own session).
-- <C-d>  : kill the currently visible terminal (jobstop + delete buffer).
--          NOTE: `<C-d>` is also mapped by smooth-scroll (neoscroll); terminal
--          owns it here, so smooth-scroll's <C-d> is intentionally disabled.
vim.keymap.set('n', '<c-t>', M.open_zellij, { desc = 'Terminal: Toggle Zellij (restores CLI session)' })
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
