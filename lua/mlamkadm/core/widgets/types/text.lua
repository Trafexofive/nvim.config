-- Static text widget
local M = {}

local Widget = {}
Widget.__index = Widget

function Widget:new(opts)
  local widget = setmetatable({
    title = opts.title or "Text Widget",
    content = opts.content or {},
    align = opts.align or "left",
    width = opts.width or nil,  -- nil = auto-size based on content
  }, Widget)
  
  return widget
end

function Widget:render()
  local lines = {}
  
  -- Calculate dynamic width based on content
  local max_width = self.width or 80
  local title_text = " " .. self.title .. " "
  local border_width = math.max(max_width, #title_text + 10)
  
  -- Top border with title
  local remaining = border_width - #title_text - 2
  local left_border = math.floor(remaining / 2)
  local right_border = remaining - left_border
  
  table.insert(lines, "╭" .. string.rep("─", left_border) .. title_text .. string.rep("─", right_border) .. "╮")
  
  -- Add content
  if type(self.content) == "string" then
    local padding = border_width - #self.content - 4
    table.insert(lines, "│ " .. self.content .. string.rep(" ", padding) .. " │")
  elseif type(self.content) == "table" then
    for _, line in ipairs(self.content) do
      local content_width = vim.fn.strdisplaywidth(line)
      local padding = math.max(0, border_width - content_width - 4)
      table.insert(lines, "│ " .. line .. string.rep(" ", padding) .. " │")
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
