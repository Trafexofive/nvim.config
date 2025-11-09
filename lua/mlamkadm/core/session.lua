-- Enhanced session management with full state preservation
-- Handles terminals, widgets, and other persistent state across sessions

local M = {}

-- Store terminal states before session switch
local terminal_states = {}

-- Store widget page states
local widget_states = {}

-- Store dashboard state
local dashboard_state = nil

---
-- Save terminal states before session operation
---
function M.save_terminals()
    local ok, terminal_module = pcall(require, "mlamkadm.core.terminal")
    if not ok then
        return
    end
    
    local terminals = terminal_module.list_terminals()
    
    terminal_states = {}
    for _, terminal in ipairs(terminals) do
        if terminal.is_open then
            -- Store terminal info for later restoration
            table.insert(terminal_states, {
                cmd = terminal.cmd,
                buf = terminal.buf,
                is_open = terminal.is_open
            })
            -- Hide the terminal to avoid issues during session save
            if vim.api.nvim_win_is_valid(terminal.win) then
                vim.api.nvim_win_close(terminal.win, false)
            end
        end
    end
end

---
-- Restore terminal states after session operation
---
function M.restore_terminals()
    if vim.tbl_isempty(terminal_states) then
        return
    end
    
    local ok, terminal_module = pcall(require, "mlamkadm.core.terminal")
    if not ok then
        return
    end
    
    -- Schedule restoration after session load completes
    vim.schedule(function()
        for _, term_data in ipairs(terminal_states) do
            -- Only restore if terminal was open when saved
            if term_data.is_open then
                -- Instead of restarting the command, try to reconnect to existing buffer
                local existing_popup = terminal_module.popups and terminal_module.popups[term_data.cmd]
                if existing_popup and existing_popup.buf and vim.api.nvim_buf_is_loaded(existing_popup.buf) then
                    -- Terminal already exists, just hide/show it as needed
                    if vim.api.nvim_buf_is_valid(existing_popup.buf) then
                        -- The buffer exists, but we need to check if window needs to be reopened
                        if not (existing_popup.win and vim.api.nvim_win_is_valid(existing_popup.win)) then
                            -- Buffer exists but window is closed, reopen it
                            terminal_module.toggle_popup(term_data.cmd)
                        end
                    end
                else
                    -- Terminal doesn't exist, start it
                    terminal_module.toggle_popup(term_data.cmd)
                end
            end
        end
        -- Clear stored state after restoration
        terminal_states = {}
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
    -- Set up autocommands to handle state preservation
    vim.api.nvim_create_autocmd("User", {
        pattern = "SessionSavePre",
        callback = function()
            M.save_all_states()
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "SessionLoadPost",
        callback = function()
            M.restore_all_states()
        end,
    })
    
    -- Keymaps for enhanced session management
    vim.keymap.set("n", "<leader>sS", function() M.save_session() end, { desc = "Enhanced Session: Save" })
    vim.keymap.set("n", "<leader>sr", function() M.restore_session() end, { desc = "Enhanced Session: Restore" })
    vim.keymap.set("n", "<leader>ss", function() M.switch_session() end, { desc = "Enhanced Session: Switch" })
    vim.keymap.set("n", "<leader>sw", function() M.restore_session() end, { desc = "Enhanced Session: Switch" })
end

return M