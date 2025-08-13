-- Markdown utilities
local M = {}

-- Function to insert a markdown link with the clipboard content as URL
function M.paste_markdown_link()
  -- Get text from clipboard
  local clipboard_text = vim.fn.getreg("+")
  
  -- Check if it looks like a URL
  if clipboard_text:match("^https?://") then
    -- Get the current line and cursor position
    local line = vim.api.nvim_get_current_line()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    
    -- Insert the markdown link format
    local new_line = line:sub(1, col) .. "[](" .. clipboard_text .. ")" .. line:sub(col + 1)
    vim.api.nvim_set_current_line(new_line)
    
    -- Move cursor to the middle of the brackets for text input
    vim.api.nvim_win_set_cursor(0, {row, col + 1})
  else
    -- If not a URL, just paste normally
    vim.api.nvim_paste(clipboard_text, true, -1)
  end
end

-- Function to create a markdown table
function M.create_markdown_table(rows, cols)
  if not rows or not cols then
    print("Usage: create_markdown_table(rows, cols)")
    return
  end
  
  local lines = {}
  
  -- Create header row
  local header = {}
  for i = 1, cols do
    table.insert(header, "Header " .. i)
  end
  table.insert(lines, "| " .. table.concat(header, " | ") .. " |")
  
  -- Create separator row
  local separator = {}
  for i = 1, cols do
    table.insert(separator, "---")
  end
  table.insert(lines, "| " .. table.concat(separator, " | ") .. " |")
  
  -- Create data rows
  for i = 1, rows do
    local row = {}
    for j = 1, cols do
      table.insert(row, "Data " .. i .. "." .. j)
    end
    table.insert(lines, "| " .. table.concat(row, " | ") .. " |")
  end
  
  -- Insert the table at the current cursor position
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end

-- Function to toggle checkbox in markdown task lists
function M.toggle_checkbox()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  
  if line:match("^%s*%* %[[ ]%]") then
    -- Checkbox is unchecked, check it
    line = line:gsub("(%* %[)%s(%]%])", "%1x%2")
  elseif line:match("^%s*%* %[[x]%]") then
    -- Checkbox is checked, uncheck it
    line = line:gsub("(%* %[)x(%]%])", "%1 %2")
  elseif line:match("^%s*%* %[[X]%]") then
    -- Checkbox is checked (capital X), uncheck it
    line = line:gsub("(%* %[)X(%]%])", "%1 %2")
  elseif line:match("^%s*%* .+") then
    -- No checkbox, add one
    line = line:gsub("^(%s*%*) (.+)$", "%1 [ ] %2")
  else
    -- Not a list item, create a new one with checkbox
    line = "* [ ] " .. line
  end
  
  vim.api.nvim_set_current_line(line)
end

-- Function to insert a markdown code block
function M.insert_code_block()
  local filetype = vim.api.nvim_buf_get_option(0, "filetype")
  local lang = "txt"
  
  if filetype == "python" then
    lang = "python"
  elseif filetype == "javascript" or filetype == "js" then
    lang = "javascript"
  elseif filetype == "typescript" or filetype == "ts" then
    lang = "typescript"
  elseif filetype == "lua" then
    lang = "lua"
  elseif filetype == "bash" or filetype == "sh" then
    lang = "bash"
  elseif filetype == "html" then
    lang = "html"
  elseif filetype == "css" then
    lang = "css"
  end
  
  local lines = {"```" .. lang, "", "```"}
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
  
  -- Move cursor to the middle line
  vim.api.nvim_win_set_cursor(0, {row + 2, 0})
end

return M