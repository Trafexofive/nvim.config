-- Page management for widget system
local buffer = require("mlamkadm.core.widgets.buffer")

local M = {}
M.pages = {}
M.current_page = nil

-- Page class
local Page = {}
Page.__index = Page

function Page:new(name, opts)
  opts = opts or {}
  local page = setmetatable({
    name = name,
    widgets = {},
    buf = nil,
    ns = vim.api.nvim_create_namespace("widgets_" .. name),
    layout = opts.layout or "vertical",  -- vertical, horizontal, grid
  }, Page)
  
  return page
end

function Page:add_widget(widget)
  table.insert(self.widgets, widget)
end

function Page:render()
  -- Validate or create buffer
  if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
    self.buf = buffer.create(self.name)
  end
  
  -- Clear existing content
  buffer.clear(self.buf)
  buffer.clear_highlights(self.buf, self.ns)
  
  local lines = {}
  local current_line = 0
  
  -- Add page title - clean display name without number prefix
  local display_name = self.name:match("^%d+_(.+)$") or self.name
  local page_title = "══════ " .. display_name:upper() .. " ══════"
  table.insert(lines, "")
  table.insert(lines, page_title)
  table.insert(lines, "")
  current_line = 3
  
  -- Render each widget
  for i, widget in ipairs(self.widgets) do
    -- Add spacing between widgets
    if i > 1 then
      table.insert(lines, "")
      current_line = current_line + 1
    end
    
    -- Get widget content
    local widget_lines = widget:render()
    for _, line in ipairs(widget_lines) do
      table.insert(lines, line)
    end
    
    -- Store widget position and metadata for interaction
    widget._start_line = current_line
    widget._end_line = current_line + #widget_lines - 1
    widget._page = self
    current_line = current_line + #widget_lines
  end
  
  -- Add footer with navigation hint
  table.insert(lines, "")
  table.insert(lines, "")
  table.insert(lines, "  Press Ctrl-j/k to navigate pages │ r to refresh │ q to return to dashboard")
  
  buffer.set_content(self.buf, lines)
  return self.buf
end

function Page:open()
  local buf = self:render()
  buffer.open(buf)
  M.current_page = self
  
  -- Set up keymaps
  self:setup_keymaps()
end

function Page:setup_keymaps()
  if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then return end
  
  local opts = { buffer = self.buf, nowait = true, silent = true }
  
  -- Navigation
  vim.keymap.set('n', 'q', function() M.close() end, opts)
  vim.keymap.set('n', '<Esc>', function() M.close() end, opts)
  
  -- Ctrl-j/k navigation
  vim.keymap.set('n', '<C-j>', function() M.next() end, opts)
  vim.keymap.set('n', '<C-k>', function() M.prev() end, opts)
  
  -- Refresh
  vim.keymap.set('n', 'r', function() self:render() end, opts)
  
  -- Open TUI widget at cursor
  vim.keymap.set('n', 'o', function()
    local line = vim.fn.line(".")
    for _, widget in ipairs(self.widgets) do
      if widget._start_line and widget._end_line then
        if line >= widget._start_line and line <= widget._end_line then
          if widget.open_tui then
            widget:open_tui()
          end
          break
        end
      end
    end
  end, opts)
end

function Page:update()
  if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then return end
  self:render()
end

-- Module functions
function M.create(name, opts)
  local page = Page:new(name, opts)
  M.pages[name] = page
  return page
end

function M.get(name)
  return M.pages[name]
end

function M.next()
  local names = vim.tbl_keys(M.pages)
  if #names == 0 then return end
  
  table.sort(names) -- Keep consistent order
  
  -- If on dashboard (no current page), go to first page
  if not M.current_page then
    if M.pages[names[1]] then
      M.pages[names[1]]:open()
    end
    return
  end
  
  -- Find current index
  local current_idx = 0
  for i, name in ipairs(names) do
    if name == M.current_page.name then
      current_idx = i
      break
    end
  end
  
  -- Close current buffer first
  local current_buf = M.current_page.buf
  M.current_page = nil
  
  -- Cycle back to dashboard if at end
  if current_idx >= #names then
    vim.schedule(function()
      if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
        pcall(vim.api.nvim_buf_delete, current_buf, { force = true })
      end
      
      local snacks = require("snacks")
      if snacks and snacks.dashboard then
        snacks.dashboard()
      end
    end)
    return
  end
  
  -- Go to next page
  local next_idx = current_idx + 1
  vim.schedule(function()
    if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
      pcall(vim.api.nvim_buf_delete, current_buf, { force = true })
    end
    
    if M.pages[names[next_idx]] then
      M.pages[names[next_idx]]:open()
    end
  end)
end

function M.prev()
  local names = vim.tbl_keys(M.pages)
  if #names == 0 then return end
  
  table.sort(names) -- Keep consistent order
  
  -- If on dashboard (no current page), go to last page
  if not M.current_page then
    if M.pages[names[#names]] then
      M.pages[names[#names]]:open()
    end
    return
  end
  
  -- Find current index
  local current_idx = 0
  for i, name in ipairs(names) do
    if name == M.current_page.name then
      current_idx = i
      break
    end
  end
  
  -- Close current buffer first
  local current_buf = M.current_page.buf
  M.current_page = nil
  
  -- Go to dashboard if at beginning
  if current_idx <= 1 then
    vim.schedule(function()
      if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
        pcall(vim.api.nvim_buf_delete, current_buf, { force = true })
      end
      
      local snacks = require("snacks")
      if snacks and snacks.dashboard then
        snacks.dashboard()
      end
    end)
    return
  end
  
  -- Go to previous page
  local prev_idx = current_idx - 1
  vim.schedule(function()
    if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
      pcall(vim.api.nvim_buf_delete, current_buf, { force = true })
    end
    
    if M.pages[names[prev_idx]] then
      M.pages[names[prev_idx]]:open()
    end
  end)
end

function M.close()
  -- Close current widget page buffer
  local current_buf = M.current_page and M.current_page.buf
  M.current_page = nil
  
  -- Open snacks dashboard safely
  vim.schedule(function()
    -- Delete buffer after scheduling dashboard open
    if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
      pcall(vim.api.nvim_buf_delete, current_buf, { force = true })
    end
    
    local snacks = require("snacks")
    if snacks and snacks.dashboard then
      snacks.dashboard()
    end
  end)
end

return M
