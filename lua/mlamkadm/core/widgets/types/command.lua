-- Command output widget (runs shell commands)
local M = {}

local Widget = {}
Widget.__index = Widget

function Widget:new(opts)
  local widget = setmetatable({
    title = opts.title or "Command",
    cmd = opts.cmd or "echo 'No command'",
    refresh_interval = opts.refresh or 0,  -- 0 = no auto-refresh
    height = opts.height or 10,
    min_width = opts.min_width or 40,
    _output = {},
    _timer = nil,
  }, Widget)
  
  widget:update()
  
  -- Set up auto-refresh if needed
  if widget.refresh_interval > 0 then
    widget:start_refresh()
  end
  
  return widget
end

function Widget:update()
  local handle = io.popen(self.cmd .. " 2>&1")
  if not handle then
    self._output = {"Error running command"}
    return
  end
  
  local result = handle:read("*a")
  handle:close()
  
  self._output = {}
  for line in result:gmatch("[^\r\n]+") do
    -- Filter out process exit messages and control characters
    local clean_line = line:gsub("%[Process exited %d+%]", "")
                          :gsub("\27%[[%d;]*m", "")  -- Remove ANSI codes
    
    -- Trim whitespace
    clean_line = clean_line:match("^%s*(.-)%s*$")
    
    -- Only add non-empty lines that aren't just process exit messages
    if clean_line and clean_line ~= "" and not clean_line:match("^%[Process") then
      table.insert(self._output, clean_line)
    end
  end
  
  -- If no output, add placeholder
  if #self._output == 0 then
    self._output = {"(no output)"}
  end
  
  -- Trim to height
  if #self._output > self.height then
    local start = #self._output - self.height + 1
    self._output = {unpack(self._output, start)}
  end
end

function Widget:start_refresh()
  if self._timer then return end
  
  self._timer = vim.loop.new_timer()
  self._timer:start(self.refresh_interval * 1000, self.refresh_interval * 1000, vim.schedule_wrap(function()
    self:update()
    -- Trigger page re-render if we can
    -- TODO: Add callback to parent page
  end))
end

function Widget:stop_refresh()
  if self._timer then
    self._timer:stop()
    self._timer = nil
  end
end

function Widget:render()
  local lines = {}
  
  -- Get terminal width for responsive design
  local term_width = vim.o.columns
  local max_widget_width = math.min(term_width - 10, 120)
  
  -- Calculate content width
  local max_content_width = 0
  for _, line in ipairs(self._output) do
    local display_width = vim.fn.strdisplaywidth(line)
    max_content_width = math.max(max_content_width, display_width)
  end
  
  -- Determine border width
  local title_text = " " .. self.title .. " "
  local min_width = math.max(#title_text + 4, self.min_width or 40)
  local border_width = math.min(math.max(min_width, max_content_width + 4), max_widget_width)
  
  -- Top border with centered title
  local title_display_width = vim.fn.strdisplaywidth(title_text)
  local remaining = math.max(0, border_width - title_display_width - 2)
  local left_border = math.floor(remaining / 2)
  local right_border = remaining - left_border
  
  table.insert(lines, "╭" .. string.rep("─", left_border) .. title_text .. string.rep("─", right_border) .. "╮")
  
  -- Add output with proper padding
  for _, line in ipairs(self._output) do
    local content_width = vim.fn.strdisplaywidth(line)
    local padding = math.max(0, border_width - content_width - 4)
    table.insert(lines, "│ " .. line .. string.rep(" ", padding) .. " │")
  end
  
  -- Fill empty space if needed
  if #self._output < self.height then
    for i = #self._output + 1, self.height do
      table.insert(lines, "│ " .. string.rep(" ", border_width - 4) .. " │")
    end
  end
  
  -- Bottom border
  table.insert(lines, "╰" .. string.rep("─", border_width - 2) .. "╯")
  
  return lines
end

function M.new(opts)
  return Widget:new(opts)
end

return M
