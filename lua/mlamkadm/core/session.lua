-- Enhanced session management with full state preservation
-- Handles terminals, widgets, and other persistent state across sessions

local M = {}

-- Store terminal states before session switch
local terminal_states = {}

-- Store widget page states
local widget_states = {}

-- Store dashboard state
local dashboard_state = nil

-- Store additional info about floating windows
local floating_window_states = {}

-- Store all terminal information (both normal and floating)
local all_terminals = {}

---
-- Save terminal states before session operation
---
function M.save_terminals()
    local ok, terminal_module = pcall(require, "mlamkadm.core.terminal")
    local terminal_ok = ok
    
    -- Reset all states
    terminal_states = {}
    floating_window_states = {}
    all_terminals = {}
    
    -- First, handle pop-up terminals
    if terminal_ok then
        for cmd, popup in pairs(terminal_module.popups) do
            if popup and vim.api.nvim_buf_is_valid(popup.buf) then
                table.insert(all_terminals, {
                    type = "popup",
                    cmd = cmd,
                    buf = popup.buf,
                    win = popup.win,
                    win_opts = popup.win_opts,
                    has_window = vim.api.nvim_win_is_valid(popup.win)
                })
            end
        end
    end
    
    -- Next, handle all terminal buffers (including regular terminal buffers)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_option(buf, 'buftype') == 'terminal' then
            local bufname = vim.api.nvim_buf_get_name(buf)
            -- Check if it's already tracked as a popup to avoid duplication
            local is_popup = false
            if terminal_ok then
                for popup_cmd, popup in pairs(terminal_module.popups) do
                    if popup.buf == buf then
                        is_popup = true
                        break
                    end
                end
            end
            
            if not is_popup then
                -- This is a regular terminal buffer (not a popup)
                -- Try to get the job command if available
                local job_info = vim.b[buf].term_title or vim.api.nvim_buf_get_option(buf, 'buftype') 
                -- Attempt to get the actual command running in the terminal
                local command = vim.b[buf].term_title or bufname or tostring(buf)
                
                table.insert(all_terminals, {
                    type = "regular",
                    buf = buf,
                    bufname = bufname,
                    command = command,  -- The command that was running
                    is_open = vim.fn.bufwinid(buf) ~= -1, -- Check if buffer is currently displayed
                    win_id = vim.fn.bufwinid(buf),
                    job_pid = vim.fn.jobpid(vim.b[buf].terminal_job_id) or nil
                })
            end
        end
    end
end

---
-- Restore terminal states after session operation
---
function M.restore_terminals()
    if vim.tbl_isempty(all_terminals) then
        return
    end
    
    local ok, terminal_module = pcall(require, "mlamkadm.core.terminal")
    local terminal_ok = ok
    
    -- Schedule restoration after session load completes
    vim.schedule(function()
        -- Process each saved terminal state
        for _, term_data in ipairs(all_terminals) do
            if term_data.type == "popup" then
                -- Handle popup terminals
                if terminal_ok and vim.api.nvim_buf_is_valid(term_data.buf) then
                    -- Check if popup exists in current popups
                    local popup_exists = terminal_module.popups[term_data.cmd] and 
                                        terminal_module.popups[term_data.cmd].buf == term_data.buf
                    
                    if not popup_exists or not vim.api.nvim_win_is_valid(terminal_module.popups[term_data.cmd].win) then
                        -- Popup doesn't exist or window is invalid, recreate it
                        terminal_module.toggle_popup(term_data.cmd)
                    end
                elseif terminal_ok then
                    -- Buffer doesn't exist anymore, restart the terminal
                    terminal_module.toggle_popup(term_data.cmd)
                end
            elseif term_data.type == "regular" then
                -- Handle regular terminal buffers
                if vim.api.nvim_buf_is_valid(term_data.buf) then
                    -- If the terminal buffer exists but wasn't visible, we might want to show it
                    -- (This part depends on the user's preference)
                    if term_data.is_open and vim.fn.bufwinid(term_data.buf) == -1 then
                        -- Terminal was open before but isn't now, might want to reopen
                        -- Try to switch to the buffer
                        vim.api.nvim_command('b' .. term_data.buf)
                    end
                else
                    -- Terminal buffer is gone, need to recreate it if we have the command
                    if term_data.command and term_data.command ~= "" and term_data.command ~= tostring(term_data.buf) then
                        -- Try to recreate the terminal with the original command
                        -- This is complex and may not be possible in all cases
                        -- For now, we'll skip recreating vanished terminal buffers
                        -- because the process is already gone and creating a new terminal
                        -- would start a new process, not restore the old one
                    end
                end
            end
        end
        -- Clear stored state after restoration
        all_terminals = {}
    end)
end

---
-- Save widget states before session operation
---
function M.save_widgets()
    -- Save current widget page if any
    local ok, widgets = pcall(require, "mlamkadm.core.widgets")
    if not ok then
        return
    end
    if widgets.page and widgets.page.current_page then
        widget_states.current_page = widgets.page.current_page.name
    end
end

---
-- Restore widget states after session operation
---
function M.restore_widgets()
    if widget_states.current_page then
        local ok, widgets = pcall(require, "mlamkadm.core.widgets")
        if not ok then
            return
        end
        vim.schedule(function()
            widgets.open(widget_states.current_page)
            widget_states = {}
        end)
    end
end

---
-- Save dashboard state before session operation
---
function M.save_dashboard()
    -- Store if we're currently on dashboard
    if vim.bo.filetype == "snacks_dashboard" then
        dashboard_state = "dashboard"
    else
        dashboard_state = vim.fn.getcwd()
    end
end

---
-- Restore dashboard state after session operation
---
function M.restore_dashboard()
    if dashboard_state == "dashboard" then
        local ok, snacks = pcall(require, "snacks")
        if not ok then
            return
        end
        vim.schedule(function()
            snacks.dashboard.open()
        end)
    end
    dashboard_state = nil
end

---
-- Save all states before session operation
---
function M.save_all_states()
    M.save_terminals()
    M.save_widgets()
    M.save_dashboard()
end

---
-- Restore all states after session operation
---
function M.restore_all_states()
    M.restore_terminals()
    M.restore_widgets()
    M.restore_dashboard()
end

---
-- Enhanced session save with state preservation
---
function M.save_session()
    M.save_all_states()
    vim.cmd("SessionSave")
end

---
-- Enhanced session restore with state preservation
---
function M.restore_session()
    -- First, save current state that we want to preserve
    M.save_all_states()
    -- Then restore the session
    vim.cmd("SessionRestore")
    -- Finally, restore the preserved state
    M.restore_all_states()
end

---
-- Enhanced session switch with state preservation
---
function M.switch_session()
    -- First, save the current session with all states preserved
    M.save_all_states()
    vim.cmd("SessionSave")
    
    -- Then switch to session selection
    vim.defer_fn(function()
        vim.cmd("Telescope session-lens")
    end, 100)  -- Small delay to ensure session is fully saved
end

---
-- Setup functions and keymaps
---
function M.setup()
    -- Don't set up global autocommands that might interfere with Neovim's session management
    -- The save/restore functions are called explicitly by our enhanced session commands
    
    -- Keymaps for enhanced session management
    vim.keymap.set("n", "<leader>sS", function() M.save_session() end, { desc = "Enhanced Session: Save" })
    vim.keymap.set("n", "<leader>sr", function() M.restore_session() end, { desc = "Enhanced Session: Restore" })
    vim.keymap.set("n", "<leader>ss", function() M.switch_session() end, { desc = "Enhanced Session: Switch" })
    vim.keymap.set("n", "<leader>sw", function() M.restore_session() end, { desc = "Enhanced Session: Switch" })
end

return M