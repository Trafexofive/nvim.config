-- lua/mlamkadm/utils.lua
local M = {}
local api = vim.api

-- Get visual selection content
function M.get_visual_selection()
    local s_start = vim.fn.getpos("'<")
    local s_end = vim.fn.getpos("'>")
    local lines = {}
    if s_start[2] > 0 and s_end[2] > 0 and s_start[2] <= s_end[2] then
        lines = vim.fn.getline(s_start[2], s_end[2])
    else
        return "" -- Invalid range
    end


    if #lines == 0 then return "" end

    -- Trim lines based on column positions
    local start_line = lines[1]
    local end_line = lines[#lines]

    -- Adjust start column (byte index)
    local start_col_byte = vim.fn.col(s_start) - 1 -- getpos gives 1-based byte index, col gives 1-based screen column
    -- We need byte index for string.sub. This approximation works for ASCII/simple UTF-8
    -- A more robust solution might involve converting screen column to byte index.

    lines[1] = string.sub(start_line, start_col_byte + 1) -- Lua strings are 1-based

    if #lines > 1 then
        local end_col_byte = vim.fn.col(s_end)
        lines[#lines] = string.sub(end_line, 1, end_col_byte)
    elseif #lines == 1 then
        -- Handle single-line selection correctly
        local start_col_byte_sl = vim.fn.col(s_start) - 1
        local end_col_byte_sl = vim.fn.col(s_end) - 1
        lines[1] = string.sub(start_line, start_col_byte_sl + 1, end_col_byte_sl + 1)
    end


    return table.concat(lines, "\n")
end

-- Simple popup window
M.popup_win = nil -- Track the popup window
M.popup_buf = nil -- Track the popup buffer

function M.show_popup(content, title)
    -- Close existing popup if open
    if M.popup_win and api.nvim_win_is_valid(M.popup_win) then
        api.nvim_win_close(M.popup_win, true)
    end
    if M.popup_buf and api.nvim_buf_is_valid(M.popup_buf) then
        pcall(api.nvim_buf_delete, M.popup_buf, { force = true })
    end

    M.popup_buf = api.nvim_create_buf(false, true)             -- Create a scratch buffer
    api.nvim_buf_set_option(M.popup_buf, "bufhidden", "wipe")
    api.nvim_buf_set_option(M.popup_buf, "filetype", "markdown") -- Set filetype for syntax highlighting

    -- Calculate dimensions
    local width = math.floor(vim.o.columns * 0.7)
    local height = math.floor(vim.o.lines * 0.7)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    -- Prepare content (split into lines)
    local lines = vim.split(content or "No content.", "\n", { plain = true })

    -- Set buffer content
    api.nvim_buf_set_lines(M.popup_buf, 0, -1, false, lines)
    api.nvim_buf_set_option(M.popup_buf, "modifiable", false) -- Make buffer read-only

    -- Open window
    M.popup_win = api.nvim_open_win(M.popup_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
        title = title or "Information",
        title_pos = "center",
    })

    -- Basic keymaps for the popup
    api.nvim_buf_set_keymap(M.popup_buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
    api.nvim_buf_set_keymap(M.popup_buf, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })
end

return M
