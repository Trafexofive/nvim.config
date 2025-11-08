-- Live TUI widget - embeds full interactive terminal applications
local M = {}

local Widget = {}
Widget.__index = Widget

function Widget:new(opts)
  local widget = setmetatable({
    title = opts.title or "TUI",
    cmd = opts.cmd or "htop",
    height = opts.height or 20,
    width = opts.width or nil,  -- nil = full width
    _buf = nil,
    _win = nil,
    _term_id = nil,
    _focused = false,
  }, Widget)
  
  return widget
end

function Widget:render()
  -- For live widgets, we return placeholder lines
  -- Actual rendering happens in :open()
  local lines = {}
  
  local width = self.width or 80
  local title_text = " " .. self.title .. " (TUI) "
  local title_len = #title_text
  local remaining = width - title_len - 2
  local left_border = 0
  local right_border = math.max(0, remaining)
  
  table.insert(lines, "╭" .. string.rep("─", left_border) .. title_text .. string.rep("─", right_border) .. "╮")
  
  -- Placeholder content
  for i = 1, self.height - 2 do
    table.insert(lines, "│ " .. string.rep(" ", width - 4) .. " │")
  end
  
  table.insert(lines, "╰" .. string.rep("─", width - 2) .. "╯")
  
  return lines
end

function Widget:open_tui()
  -- Create a floating window for the TUI
  local width = self.width or math.floor(vim.o.columns * 0.9)
  local height = self.height
  
  -- Create buffer
  self._buf = vim.api.nvim_create_buf(false, true)
  
  -- Calculate window position (centered)
  local win_width = vim.o.columns
  local win_height = vim.o.lines
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)
  
  -- Window config
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " " .. self.title .. " ",
    title_pos = "center",
  }
  
  -- Open window
  self._win = vim.api.nvim_open_win(self._buf, true, win_opts)
  
  -- Start terminal
  self._term_id = vim.fn.termopen(self.cmd, {
    on_exit = function()
      if self._win and vim.api.nvim_win_is_valid(self._win) then
        vim.api.nvim_win_close(self._win, true)
      end
      self._buf = nil
      self._win = nil
      self._term_id = nil
    end
  })
  
  -- Enter terminal mode
  vim.cmd("startinsert")
  
  -- Set up keymaps
  local opts = { buffer = self._buf, nowait = true }
  vim.keymap.set('t', '<C-q>', function()
    vim.cmd("stopinsert")
    if self._win and vim.api.nvim_win_is_valid(self._win) then
      vim.api.nvim_win_close(self._win, true)
    end
  end, opts)
  
  vim.keymap.set('n', 'q', function()
    if self._win and vim.api.nvim_win_is_valid(self._win) then
      vim.api.nvim_win_close(self._win, true)
    end
  end, opts)
end

function Widget:close()
  if self._term_id then
    vim.fn.jobstop(self._term_id)
  end
  if self._win and vim.api.nvim_win_is_valid(self._win) then
    vim.api.nvim_win_close(self._win, true)
  end
  self._buf = nil
  self._win = nil
  self._term_id = nil
end

function M.new(opts)
  return Widget:new(opts)
end

return M
