# Custom Widget System

A modular, extensible widget system for the Neovim dashboard with full buffer control.

## Architecture

```
lua/mlamkadm/core/widgets/
├── init.lua              # Main entry point and page registration
├── buffer.lua            # Buffer management utilities
├── page.lua              # Page management and navigation
└── types/
    ├── text.lua          # Static text widgets
    └── command.lua       # Command output widgets (with auto-refresh)
```

## Usage

### Opening Widgets

From dashboard:
- Press `w` key
- Or press `Ctrl-j`

### Navigation

In widget pages:
- `Ctrl-j` - Next page
- `Ctrl-k` - Previous page
- `q` or `Esc` - Return to dashboard
- `r` - Refresh current page

## Creating Custom Pages

```lua
local widgets = require("mlamkadm.core.widgets")

-- Create a new page
local my_page = widgets.page.create("my_page", { layout = "vertical" })

-- Add text widget
my_page:add_widget(widgets.types.text.new({
  title = "My Title",
  content = {"Line 1", "Line 2", "Line 3"}
}))

-- Add command widget
my_page:add_widget(widgets.types.command.new({
  title = "System Info",
  cmd = "uname -a",
  height = 5,
}))

-- Add auto-refreshing widget
my_page:add_widget(widgets.types.command.new({
  title = "Live CPU",
  cmd = "top -bn1 | head -5",
  height = 6,
  refresh = 5,  -- Refresh every 5 seconds
}))

-- Open the page
widgets.open("my_page")
```

## Widget Types

### Text Widget
Static content display with border.

```lua
widgets.types.text.new({
  title = "Widget Title",
  content = {"line1", "line2"},  -- or single string
  align = "left",  -- left, center, right
})
```

### Command Widget
Runs shell commands and displays output.

```lua
widgets.types.command.new({
  title = "Command Output",
  cmd = "ls -la",
  height = 10,           -- Max lines to display
  refresh = 0,           -- Auto-refresh interval (0 = disabled)
})
```

## Default Pages

1. **System** - Calendar, disk usage, system info
2. **Git** - Status, recent commits, current branch
3. **Processes** - Top processes, memory usage (auto-refresh)

## Extending

To create a new widget type:

1. Create file in `types/` directory
2. Implement `:new(opts)` and `:render()` methods
3. Return table of lines from `:render()`
4. Register in `init.lua`

Example:

```lua
-- types/my_widget.lua
local M = {}

local Widget = {}
Widget.__index = Widget

function Widget:new(opts)
  return setmetatable({
    title = opts.title or "Widget",
  }, Widget)
end

function Widget:render()
  return {
    "╭─ " .. self.title .. " " .. string.rep("─", 70),
    "│ Content here",
    "╰" .. string.rep("─", 78),
  }
end

function M.new(opts)
  return Widget:new(opts)
end

return M
```
