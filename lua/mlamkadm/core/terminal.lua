-- /lua/mlamkadm/core/terminal.lua
-- Advanced Terminal Management System
-- Handles multiple terminal instances, persistence, and session integration.

local M = {}

-- ----------------------------------------------------------------------------
-- Configuration
-- ----------------------------------------------------------------------------
local config = {
    border = "rounded",
    width = 0.8,
    height = 0.8,
    title = "Terminal",
    title_pos = "center", -- center | left | right
    close_key = "<C-t>",
    winblend = 0,
    zindex = 50,
    scrollback = 100000,
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

-- Registry of TUI commands for quick access
local tui_registry = {}

local function project_session_name()
    local cwd = vim.fn.getcwd()
    local name = vim.fn.fnamemodify(cwd, ":t")
    if name == "" then name = "home" end
    name = name:gsub("[^%w_.-]", "-")
    return "nvim-" .. name .. "-" .. vim.fn.sha256(cwd):sub(1, 8)
end

function M.zellij_cmd()
    return "zellij attach --create " .. vim.fn.shellescape(project_session_name())
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
function M.toggle(id_or_cmd, opts)
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
    
    vim.cmd("startinsert")
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
    M.toggle(M.zellij_cmd(), vim.tbl_deep_extend("force", {
        title = "Zellij: " .. session,
        width = 0.92,
        height = 0.88,
        use_theme = false,
    }, opts))
end

function M.cleanup(opts)
    opts = opts or {}
    if opts.save then
        M.save_session()
    end

    for id, term in pairs(terminals) do
        if term.win and vim.api.nvim_win_is_valid(term.win) then
            pcall(vim.api.nvim_win_close, term.win, true)
        end
        if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
            pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
        end
        terminals[id] = nil
    end

    last_active_id = nil
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
    
    -- Clear existing terminals from memory to avoid mixing sessions
    -- But keep the TUI registry or any global config?
    -- Terminals are instances. Yes, clear them.
    for id, term in pairs(terminals) do
        if term.win and vim.api.nvim_win_is_valid(term.win) then
            vim.api.nvim_win_close(term.win, true)
        end
        if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
            vim.api.nvim_buf_delete(term.buf, { force = true })
        end
    end
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
        M.create_term(data.cmd, data.opts)
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
    M.register_tui("Copilot", "copilot --allow-tool write", "right")
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
vim.keymap.set('n', '<c-t>', function() M.toggle(vim.o.shell) end, { desc = 'Toggle shell' })
vim.keymap.set('n', '<leader>tz', M.open_zellij, { desc = 'Open Zellij terminal' })
vim.keymap.set('n', '<leader>ts', M.switch_terminal, { desc = 'Switch Terminal' })
vim.keymap.set('n', '<leader>tt', M.show_tui_registry, { desc = 'TUI Registry' })
vim.keymap.set('n', '<leader>tn', function() M.create_term(vim.o.shell); M.toggle(next_id - 1) end, { desc = 'New Terminal' })

-- Re-bind the specific TUI keys
vim.keymap.set('n', '<leader>jj', function() M.toggle('lazygit') end, { desc = 'Toggle Lazygit' })
vim.keymap.set('n', '<leader>jd', function() M.toggle('lazydocker') end, { desc = 'Toggle Lazydocker' })
vim.keymap.set('n', '<leader>dl', function() M.toggle('docker-compose logs -f') end, { desc = 'Docker Compose Logs' })
vim.keymap.set('n', '<leader>jt', function() M.toggle('btop', { use_theme = false }) end, { desc = 'Toggle Btop' })
vim.keymap.set('n', '<leader>jf', function() M.toggle('yazi') end, { desc = 'Toggle File Manager (Yazi)' })
vim.keymap.set('n', '<leader>jc', function() M.toggle('copilot --allow-tool write', { position = 'right' }) end, { desc = 'Toggle Copilot' })
vim.keymap.set('n', '<leader>mg', function() M.toggle('glow') end, { desc = 'Make: Glow' })
vim.keymap.set('n', '<leader>mr', function() M.toggle('make run') end, { desc = 'Make: Run' })
vim.keymap.set('n', '<leader>mc', function() M.toggle('make clean') end, { desc = 'Make: Clean' })

return M
