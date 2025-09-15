local M = {}

-- Default configuration
local config = {
    border = "rounded",
    width = 80,
    height = 20,
    title = "Pop-Up Bin",
    title_pos = "center",
    close_key = "q",
    winblend = 10,
    zindex = 50,
}

-- This will hold the state of the popup for a given command
local popups = {}

---
-- Creates and manages a terminal in a floating window.
-- @param cmd string: The command to execute in the terminal.
--
function M.toggle_popup(cmd)
    -- If a popup for this command exists and is visible, close it.
    if popups[cmd] and vim.api.nvim_win_is_valid(popups[cmd].win) then
        vim.api.nvim_win_close(popups[cmd].win, true)
        -- The TermClose autocmd will handle cleanup
        return
    end

    local screen_width = vim.o.columns
    local screen_height = vim.o.lines

    -- Handle percentage or absolute values for width/height
    local width = config.width
    if width > 0 and width <= 1 then width = math.floor(screen_width * width) end
    local height = config.height
    if height > 0 and height <= 1 then height = math.floor(screen_height * height) end

    local row = math.floor((screen_height - height) / 2)
    local col = math.floor((screen_width - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        border = config.border,
        style = 'minimal',
        zindex = config.zindex,
        title = config.title,
        title_pos = config.title_pos,
    })
    vim.api.nvim_win_set_option(win, 'winblend', config.winblend)

    -- Store window and buffer info
    popups[cmd] = { win = win, buf = buf }

    -- Start terminal
    vim.fn.termopen(cmd)
    vim.cmd("startinsert")

    -- Keymap to close
    vim.api.nvim_buf_set_keymap(buf, 't', config.close_key, '<C-\\%><C-n><cmd>close!<CR>', { noremap = true, silent = true })

    -- Autocmd to clean up when job exits
    local group = vim.api.nvim_create_augroup("PopUpBin_" .. buf, { clear = true })
    vim.api.nvim_create_autocmd("TermClose", {
        group = group,
        buffer = buf,
        callback = function()
            popups[cmd] = nil
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end,
    })
end

---
-- The main setup function.
-- @param opts table: User-provided configuration overrides.
--
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  -- Define the global function to be used across your config
  _G.Poptui = M.toggle_popup
end

return M