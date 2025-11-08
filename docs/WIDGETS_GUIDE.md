# Widget System Guide

## Overview
Custom widget system for Neovim dashboard with full buffer control, live updates, and TUI support.

## Features
- **Full buffer manipulation** - Complete control over widget rendering
- **Multiple widget pages** - Navigate between different widget collections
- **Live TUI support** - Interactive terminal UIs within widgets
- **Command widgets** - Run and display shell command output
- **Auto-refresh** - Widgets can update automatically
- **Clean navigation** - Intuitive keyboard shortcuts

## Usage

### Opening Widgets
From the dashboard:
- Press `w` - Opens first widget page (System)
- Press `Ctrl-j` - Also opens first widget page

### Navigation
On widget pages:
- `Ctrl-j` - Next widget page (cycles back to dashboard at end)
- `Ctrl-k` - Previous widget page (cycles back to dashboard at beginning)
- `r` - Refresh current page
- `q` or `Esc` - Return to dashboard

### Current Widget Pages
1. **System** (`1_system`)
   - Calendar
   - System Info (uname)
   - Disk Usage

2. **Development** (`2_development`)
   - Git Status
   - Recent Commits
   - Current Branch

## Creating Custom Widgets

### Command Widget
```lua
local widgets = require("mlamkadm.core.widgets")

local my_widget = widgets.types.command.new({
  title = "My Widget",
  cmd = "echo 'Hello World'",
  height = 10,
  refresh = 60,  -- Auto-refresh every 60 seconds (0 = no auto-refresh)
})
```

### Creating a New Page
```lua
local widgets = require("mlamkadm.core.widgets")

-- Create page
local my_page = widgets.page.create("my_page", { layout = "vertical" })

-- Add widgets
my_page:add_widget(widgets.types.command.new({
  title = "Widget 1",
  cmd = "date",
  height = 3,
}))

my_page:add_widget(widgets.types.command.new({
  title = "Widget 2",
  cmd = "uptime",
  height = 3,
}))
```

## Architecture

### Core Components
- `widgets/init.lua` - Main entry point and setup
- `widgets/page.lua` - Page management and navigation
- `widgets/buffer.lua` - Buffer manipulation utilities
- `widgets/types/` - Widget type implementations

### Widget Types
- `command` - Shell command output (implemented)
- `text` - Static text content (stub)
- `tui` - Interactive TUI applications (stub)

## Design Philosophy
- **Simple** - Easy to understand and extend
- **Solid** - Robust buffer and state management
- **Modular** - Clean separation of concerns
- **Zenful** - Minimal, beautiful, functional

## Future Enhancements
- Live TUI widget support (htop, btop, etc.)
- Widget borders and visual improvements
- Grid/horizontal layouts
- Widget highlighting and focus
- Per-widget keybindings
- Widget templates and presets
