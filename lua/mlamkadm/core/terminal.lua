-- /lua/mlamkadm/core/terminal.lua
-- This file combines the pop-up terminal library and its configuration
-- to ensure it is loaded synchronously at startup, avoiding lazy-loading issues.

-- ----------------------------------------------------------------------------
-- Pop-up Terminal Library (from libs/pop-up-bin/init.lua)
-- ----------------------------------------------------------------------------
local M = {}

-- Default configuration
local config = {
    border = "rounded",
    width = 0.8,
    height = 0.8,
    title = "Pop-Up Bin",
    title_pos = "center", -- center | left | right
    close_key = "<C-t>",
    winblend = 10,
    zindex = 50,
    scrollback = 100000,
}

-- This will hold the state of the popup for a given command
local popups = {}

-- Registry of TUI commands for quick access
local tui_registry = {}

---
-- Creates and manages a terminal in a floating window with custom positioning.
-- @param cmd string: The command to execute in the terminal.
-- @param position string: Optional positioning ('right', 'left', 'center'). Defaults to 'center'.
-- @param opts table: Optional overrides (title, width, height, use_theme, etc).
--
function M.toggle_popup(cmd, position, opts)
    position = position or 'center'
    opts = opts or {}
    local use_theme = opts.use_theme ~= false  -- Default to true unless explicitly false
    local existing_popup = popups[cmd]

    -- If a popup for this command is currently open, close its window.
    if existing_popup and vim.api.nvim_win_is_valid(existing_popup.win) then
        vim.api.nvim_win_close(existing_popup.win, false) -- false so bufhidden applies
        return
    end

    -- Get window dimensions
    local screen_width = vim.o.columns
    local screen_height = vim.o.lines
    local width = opts.width or config.width
    if width > 0 and width <= 1 then width = math.floor(screen_width * width) end
    local height = opts.height or config.height
    if height > 0 and height <= 1 then height = math.floor(screen_height * height) end
    local row = math.floor((screen_height - height) / 2)
    local col
    if position == 'right' then
        col = screen_width - width - 2
    elseif position == 'left' then
        col = 2
    else
        col = math.floor((screen_width - width) / 2)
    end

    -- Extract command name for title
    local title = opts.title or config.title
    if title == config.title then
        local cmd_name = cmd:match("^(%S+)") or cmd
        title = cmd_name:gsub("^%l", string.upper)
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

    -- If a popup buffer exists but its window is closed, create a new window for it.
    if existing_popup and existing_popup.buf and vim.api.nvim_buf_is_loaded(existing_popup.buf) then
        local new_win = vim.api.nvim_open_win(existing_popup.buf, true, win_opts)
        vim.api.nvim_win_set_option(new_win, 'winblend', config.winblend)
        popups[cmd].win = new_win -- Update the win id
        vim.cmd("startinsert")    -- Re-enter terminal mode
        return
    end

    -- Otherwise, create a new terminal from scratch.
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide') -- Use 'hide' to persist across sessions

    local win = vim.api.nvim_open_win(buf, true, win_opts)
    vim.api.nvim_win_set_option(win, 'winblend', config.winblend)

    -- Store window and buffer info
    popups[cmd] = { win = win, buf = buf, cmd = cmd, win_opts = vim.deepcopy(win_opts) }

    -- Start terminal with scrollback
    local term_opts = { 
        scrollback = config.scrollback,
        on_exit = function(job, code, event)
            -- Clean up when terminal exits
            if popups[cmd] and popups[cmd].buf == buf then
                popups[cmd] = nil
            end
        end
    }
    
    -- Disable gruvbox colors if use_theme is false
    if not use_theme then
        term_opts.env = { TERM = "xterm-256color" }
    end
    
    vim.fn.termopen(cmd, term_opts)
    vim.cmd("startinsert")

    -- Keymap to close from within the terminal
    vim.api.nvim_buf_set_keymap(buf, 't', config.close_key, [[<C-\><C-n><cmd>close<CR>]],
        { noremap = true, silent = true, desc = "Hide Terminal" })

    -- Keymap to drop to normal mode with ctrl-escape
    vim.api.nvim_buf_set_keymap(buf, 't', '<C-Esc>', [[<C-\><C-n>]],
        { noremap = true, silent = true, desc = "Exit to Normal Mode" })
end

---
-- List all open terminal popups.
-- @return table: A table of terminal commands with their buffer info.
--
function M.list_terminals()
    local terminals = {}
    for cmd, popup in pairs(popups) do
        if popup.buf and vim.api.nvim_buf_is_loaded(popup.buf) then
            table.insert(terminals, {
                cmd = cmd,
                buf = popup.buf,
                is_open = popup.win and vim.api.nvim_win_is_valid(popup.win)
            })
        end
    end
    return terminals
end

---
-- Register a TUI command for quick access.
-- @param name string: Display name for the TUI.
-- @param cmd string: Command to execute.
-- @param position string: Optional positioning ('right', 'left', 'center').
-- @param opts table: Optional overrides (title, width, height, etc).
--
function M.register_tui(name, cmd, position, opts)
    table.insert(tui_registry, {
        name = name,
        cmd = cmd,
        position = position,
        opts = opts or {}
    })
end

---
-- Telescope picker to launch registered TUI commands.
--
function M.show_tui_registry()
    if #tui_registry == 0 then
        vim.notify("No TUI commands registered", vim.log.levels.INFO)
        return
    end

    -- Check if telescope is available
    local has_telescope, telescope = pcall(require, 'telescope')
    if not has_telescope then
        vim.notify("Telescope not available", vim.log.levels.WARN)
        return
    end

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
                    M.toggle_popup(selection.value.cmd, selection.value.position, selection.value.opts)
                end
            end)
            return true
        end,
    }):find()
end

---
-- Telescope picker to switch between terminal popups.
--
function M.switch_terminal()
    local terminals = M.list_terminals()
    if #terminals == 0 then
        vim.notify("No terminal popups available", vim.log.levels.INFO)
        return
    end

    -- Check if telescope is available
    local has_telescope, telescope = pcall(require, 'telescope')
    if not has_telescope then
        vim.notify("Telescope not available", vim.log.levels.WARN)
        return
    end

    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    pickers.new({}, {
        prompt_title = 'Terminal Popups',
        finder = finders.new_table {
            results = terminals,
            entry_maker = function(entry)
                local status = entry.is_open and "[Open]" or "[Hidden]"
                return {
                    value = entry,
                    display = string.format("%-10s %s", status, entry.cmd),
                    ordinal = entry.cmd,
                }
            end,
        },
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    M.toggle_popup(selection.value.cmd)
                end
            end)
            return true
        end,
    }):find()
end

---
-- The main setup function.
-- @param opts table: User-provided configuration overrides.
--
function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})

    -- Define the global function to be used across your config
    _G.Poptui = M.toggle_popup

    -- Add an autocommand to close all pop-up terminals when Neovim is about to exit.
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            for _, popup in pairs(popups) do
                if popup and vim.api.nvim_win_is_valid(popup.win) then
                    -- Force-close the window, which should terminate the job
                    vim.api.nvim_win_close(popup.win, true)
                end
            end
        end,
        desc = "Close all pop-up bins before exiting Neovim"
    })
    

end

-- ----------------------------------------------------------------------------
-- Configuration and Keymaps
-- ----------------------------------------------------------------------------

-- Setup the terminal with desired options
M.setup({
    border = "rounded",
    width = 0.8,
    height = 0.8,
    title = "Terminal",
    title_pos = "center",
    -- ratio = 0.8, -- implement later
    winblend = 5,
    zindex = 50,
    scrollback = 100000,
})


-- Register TUI commands
M.register_tui("Terminal", vim.o.shell)
M.register_tui("Lazygit", "lazygit")
M.register_tui("Glow", "glow")
M.register_tui("Noter", "noter")
M.register_tui("Aart", "aart")
M.register_tui("Lazydocker", "lazydocker")
M.register_tui("Docker Logs", "docker-compose logs -f")
M.register_tui("Btop", "btop", nil, { use_theme = false })  -- Btop has its own theme
M.register_tui("File Manager", "yazi")
M.register_tui("Copilot", "copilot --allow-tool write", "right")
M.register_tui("Make Run", "make run")
M.register_tui("Make Clean", "make clean")

M.register_tui("Qwen Full", "qwen -a -y") -- we will feed in custom sys prompts from core.LLM.prompts later

-- Define keymaps now that _G.Poptui is guaranteed to exist
vim.keymap.set('n', '<c-t>', function() _G.Poptui(vim.o.shell) end, { desc = 'Toggle floating terminal' })
vim.keymap.set('n', '<leader>jj', function() _G.Poptui('lazygit') end, { desc = 'Toggle Lazygit' })
vim.keymap.set('n', '<leader>jd', function() _G.Poptui('lazydocker') end, { desc = 'Toggle Lazydocker' })
vim.keymap.set('n', '<leader>dl', function() _G.Poptui('docker-compose logs -f') end, { desc = 'Docker Compose Logs' })
vim.keymap.set('n', '<leader>jt', function() _G.Poptui('btop', nil, { use_theme = false }) end, { desc = 'Toggle Btop' })
vim.keymap.set('n', '<leader>jf', function() _G.Poptui('yazi') end, { desc = 'Toggle File Manager (Yazi)' })
vim.keymap.set('n', '<leader>jc', function() _G.Poptui('copilot --allow-tool write', 'right') end,
    { desc = 'Toggle Copilot' })
vim.keymap.set('n', '<leader>mg', function() _G.Poptui('glow') end, { desc = 'Make: Glow' })
vim.keymap.set('n', '<leader>mr', function() _G.Poptui('make run') end, { desc = 'Make: Run' })
vim.keymap.set('n', '<leader>mc', function() _G.Poptui('make clean') end, { desc = 'Make: Clean' })
vim.keymap.set('n', '<leader>ts', M.switch_terminal, { desc = 'Switch Terminal' })
vim.keymap.set('n', '<leader>tt', M.show_tui_registry, { desc = 'Show TUI Registry' })

M.popups = popups  -- Make popups accessible to other modules
return M
