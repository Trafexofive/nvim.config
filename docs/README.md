# Neovim Configuration Documentation

## Enhanced Session Management

Full session state preservation across switches. Terminals, widgets, and all buffers are maintained when switching between sessions.

### Key Features
- Auto-saves current session before switching
- Terminals persist across session switches
- Widget states maintained during session transitions
- Smooth session switching with `<leader>ss`
- Session saving with `<leader>sS`
- Session restoration with `<leader>sr`

### Quick Start
- Press `<leader>ss` to open session picker (current session auto-saved)
- Press `<leader>sS` to save current session
- Press `<leader>sr` to restore a session
- Running terminals will be preserved across sessions

## Widget System

Custom widget system with full buffer control, live updates, and TUI support.

### Quick Start
- Press `w` or `Ctrl-j` from dashboard to open widget pages
- Use `Ctrl-j/k` to navigate between widget pages
- Press `q` to return to dashboard
- Press `r` to refresh current page

### Pages
1. **System** - Calendar, system info, disk usage
2. **Dev** - Git status and recent commits

### Creating Custom Widgets

See `lua/mlamkadm/core/widgets/` for implementation details.

Widget types available:
- `text` - Static text widgets
- `command` - Execute shell commands
- `tui` - Interactive TUI applications

## Dashboard

Zen-focused dashboard using snacks.nvim with custom ASCII art.

### Keybindings
- `f` - Find files
- `r` - Recent files
- `s` - Enhanced Sessions
- `S` - Restore Session
- `t` - TUI commands
- `w` - Widgets
- `l` - Lazy
- `q` - Quit

## Architecture

```
lua/mlamkadm/
├── core/
│   ├── widgets/       # Custom widget system
│   │   ├── init.lua   # Main setup
│   │   ├── page.lua   # Page management
│   │   ├── buffer.lua # Buffer utilities
│   │   └── types/     # Widget implementations
│   └── terminal.lua   # TUI registry
├── plugs/             # Plugin configurations
└── utils/             # Utilities
```

# Quick Reference

## Dashboard Navigation

| Key | Action |
|-----|--------|
| `f` | Find files (Telescope) |
| `r` | Recent files |
| `s` | Sessions |
| `S` | Restore session |
| `t` | TUI Commands |
| `w` | Open widgets |
| `l` | Lazy plugin manager |
| `q` | Quit |

## Widget Pages

| Key | Action |
|-----|--------|
| `Ctrl-j` | Next widget page |
| `Ctrl-k` | Previous widget page |
| `r` | Refresh current page |
| `q` / `Esc` | Return to dashboard |

## Widget Pages

1. **System**: Calendar, system info, disk usage
2. **Dev**: Git status, commits, processes

## Customization

Edit `lua/mlamkadm/core/widgets/init.lua` to add/modify widgets.

See `docs/widgets.md` for detailed documentation.
