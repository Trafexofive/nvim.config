# Dashboard Widget System

Custom widget framework for Neovim dashboard with full buffer control and TUI support.

## Features

✓ **Modular Architecture** - Easy to extend with new widget types  
✓ **Multiple Pages** - Organize widgets into separate pages  
✓ **Smooth Navigation** - Ctrl-j/k to cycle between pages  
✓ **Auto-refresh** - Widgets can update on intervals  
✓ **TUI Support** - Embed interactive terminal applications  
✓ **Responsive Borders** - Auto-sizing with clean visual design  

## Quick Start

### Navigation

| Key | Action |
|-----|--------|
| `w` or `Ctrl-j` | Open widgets from dashboard |
| `Ctrl-j` | Next widget page |
| `Ctrl-k` | Previous widget page |
| `q` / `Esc` | Return to dashboard |
| `r` | Refresh current page |
| `o` | Open TUI widget (if on widget line) |

### Default Pages

**Page 1: System**
- Calendar
- System Info  
- Disk Usage

**Page 2: Development**
- Git Status
- Recent Commits
- Current Branch

## Custom Widget Pages

```lua
local widgets = require("mlamkadm.core.widgets")

-- Create page
local my_page = widgets.page.create("3_custom", { layout = "vertical" })

-- Add widgets
my_page:add_widget(widgets.types.command.new({
  title = "My Command",
  cmd = "echo 'Hello World'",
  height = 5,
}))
```

## Widget Types

### Command Widget

Executes shell commands and displays output.

```lua
widgets.types.command.new({
  title = "Git Status",
  cmd = "git status -s",
  height = 10,
  refresh = 60,  -- Optional: auto-refresh every 60s
})
```

Features:
- Filters out "[Process exited X]" messages
- Strips ANSI color codes
- Auto-trims output to height
- Optional auto-refresh

### TUI Widget

Embeds interactive terminal applications.

```lua
widgets.types.tui.new({
  title = "htop",
  cmd = "htop",
  height = 20,
})
```

Press `o` while cursor is on the widget to open the TUI.

### Text Widget

Static text display.

```lua
widgets.types.text.new({
  title = "Notes",
  content = {"Line 1", "Line 2", "Line 3"},
  align = "left",  -- left, center, right
})
```

## Architecture

```
core/widgets/
├── init.lua          # Main system, setup, keymaps
├── page.lua          # Page navigation & rendering
├── buffer.lua        # Buffer operations (create, write, highlight)
└── types/
    ├── command.lua   # Shell command widgets
    ├── text.lua      # Static text widgets
    └── tui.lua       # Interactive TUI widgets
```

### Buffer Management

- Creates scratch buffers (`nofile`, `bufhidden=wipe`)
- Proper modifiable state handling
- Namespace-based highlighting
- Auto-cleanup on navigation

### Page System

Pages cycle: Dashboard → Page 1 → Page 2 → Dashboard

- Sorted alphabetically by name
- Auto-buffer cleanup
- FileType-based keymaps
- Responsive rendering

## Extending

### Create New Widget Type

1. Create `lua/mlamkadm/core/widgets/types/mywidget.lua`
2. Implement `:new(opts)` and `:render()` methods
3. Return array of strings from `:render()`
4. Register in `init.lua`

Example template:

```lua
local M = {}
local Widget = {}
Widget.__index = Widget

function Widget:new(opts)
  return setmetatable({
    title = opts.title or "Widget",
    -- your fields
  }, Widget)
end

function Widget:render()
  local lines = {}
  -- Build your widget
  table.insert(lines, "╭─ " .. self.title .. " ─╮")
  table.insert(lines, "│ Content here   │")
  table.insert(lines, "╰────────────────╯")
  return lines
end

function M.new(opts)
  return Widget:new(opts)
end

return M
```

## Design Philosophy

**Simple** - Minimal API surface, easy to understand  
**Solid** - Robust buffer management, proper cleanup  
**Modular** - Composable widgets, extensible system  
**Zenful** - Clean aesthetics, intuitive navigation  

## Configuration

Widget system is initialized in `snacks-dashboard.lua`:

```lua
config = function(_, opts)
  require("snacks").setup(opts)
  require("mlamkadm.core.widgets").setup()
end
```

Default pages are created in `widgets/init.lua`:
- Modify `M.create_default_pages()` to customize
- Change widget heights, commands, or add new widgets
- Create additional pages with sequential names

## Troubleshooting

**Widgets not appearing?**
- Check `:messages` for errors
- Verify commands execute: `:lua vim.inspect(require('mlamkadm.core.widgets').page.pages)`

**Navigation not working?**
- Ensure FileType is `dashboard_widgets`
- Check keymaps: `:nmap <C-j>`

**Page not found?**
- Verify page name matches exactly (case-sensitive)
- Check page was created in `setup()`
