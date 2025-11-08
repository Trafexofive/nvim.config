-- Buffer management for widget pages
local M = {}

-- Create a new widget buffer
function M.create(name)
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer options
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "dashboard_widgets"
  vim.bo[buf].modifiable = false
  
  -- Set buffer name
  vim.api.nvim_buf_set_name(buf, "dashboard://widgets/" .. name)
  
  return buf
end

-- Open buffer in current window
function M.open(buf)
  vim.api.nvim_set_current_buf(buf)
end

-- Clear buffer content
function M.clear(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.bo[buf].modifiable = false
end

-- Write lines to buffer
function M.write(buf, lines, start_line)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  start_line = start_line or 0
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, start_line, start_line, false, lines)
  vim.bo[buf].modifiable = false
end

-- Set entire buffer content
function M.set_content(buf, lines)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

-- Add highlighting
function M.highlight(buf, ns, hl_group, line, col_start, col_end)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_add_highlight(buf, ns, hl_group, line, col_start, col_end or -1)
end

-- Clear highlights
function M.clear_highlights(buf, ns)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

return M
