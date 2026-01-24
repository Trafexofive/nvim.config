# Neovim Configuration

A simple yet opinionated Neovim configuration that enhances your coding experience with powerful completion, documentation lookup, and productivity features.

## ✨ Features

- **Enhanced Completion**: Powerful nvim-cmp and Copilot integration with AI-powered suggestions
- **Organized Snippets**: Language-specific snippets in dedicated directories
- **Documentation Lookup**: Easy access to help documentation and cheat sheets
- **Performance Optimized**: Fast startup and responsive editing
- **Modern UI**: Clean, Zenful interface with customizable themes
- **Session Management**: Full session state preservation across switches (terminals, widgets, buffers)
- **Widget System**: Custom dashboard widgets with TUI support

## 🔧 Key Components

### Completion Engine
- **nvim-cmp**: Advanced completion framework with multiple sources
- **Copilot Integration**: AI-powered code completion and suggestions
- **LSP Support**: Full Language Server Protocol integration
- **Multiple Sources**: LSP, snippets, buffer, path, emoji, git, npm, and ripgrep completion

### Snippet Management
- Organized in dedicated directories by language: `all`, `javascript`, `typescript`, `python`, `markdown`
- Language-appropriate templates for faster coding
- Easy to extend with custom snippets

### Documentation & Help
- **LSP Signature**: Real-time function signature help
- **Telescope Integration**: Quick access to help tags and keybindings
- **Cheatsheet Plugin**: Built-in keybinding reference

### Theme System
- Multiple theme options with easy switching
- Consistent UI across all components
- Dark/light theme support

### Enhanced Session Management
Full session state preservation across switches. Terminals, widgets, and all buffers are maintained when switching between sessions.
- Auto-saves current session before switching
- Terminals persist across session switches
- Widget states maintained during session transitions
- Smooth session switching with `<leader>ss`
- Session saving with `<leader>sS`
- Session restoration with `<leader>sr`

### Widget System
Custom widget system with full buffer control, live updates, and TUI support.
- Press `w` or `Ctrl-j` from dashboard to open widget pages
- Use `Ctrl-j/k` to navigate between widget pages
- Press `q` to return to dashboard
- Press `r` to refresh current page

**Pages:**
1. **System** - Calendar, system info, disk usage
2. **Dev** - Git status and recent commits

## 🚀 Quick Start

1. **Prerequisites**:
   ```bash
   # Make sure you have Neovim 0.9+ installed
   nvim --version
   ```

2. **Installation**:
   ```bash
   # Backup your existing config (if any)
   mv ~/.config/nvim ~/.config/nvim.backup

   # Clone this configuration
   git clone https://github.com/yourusername/nvim.config ~/.config/nvim

   # Start Neovim to install plugins
   nvim
   ```

3. **Plugin Installation**:
   - Run `:Lazy` in Neovim to see plugin management UI
   - Plugins will install automatically on first launch

## 🎯 Key Bindings

### General
- `<leader>` - Space key
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Find buffers
- `<leader>fh` - Help tags
- `<leader>fr` - Recent files
- `<leader>fs` - Search history

### Session Management
- `<leader>ss` - Switch session (auto-saves current)
- `<leader>sS` - Save current session
- `<leader>sr` - Restore session

### Dashboard Navigation
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

### Widget Pages
| Key | Action |
|-----|--------|
| `Ctrl-j` | Next widget page |
| `Ctrl-k` | Previous widget page |
| `r` | Refresh current page |
| `q` / `Esc` | Return to dashboard |

### LSP
- `<leader>ld` - LSP Definitions
- `<leader>lr` - LSP References
- `<leader>li` - LSP Implementations
- `<leader>ls` - LSP Document Symbols

### Documentation
- `<leader>cs` - Open cheatsheet
- `<leader>?` - Which-key menu
- `K` - Show documentation for symbol under cursor

## 🛠️ Customization

### Adding Snippets
Create snippet files in the `LuaSnip/<language>/` directory:

```lua
-- Example: LuaSnip/javascript/custom_snippets.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("req", {
    t("require('"), i(1, "module"), t("')")
  }),
}
```

### Changing Theme
- Run `:Telescope themes` to see available themes
- Or modify the theme configuration in `lua/mlamkadm/core/theme.lua`

### Widget Customization
Edit `lua/mlamkadm/core/widgets/init.lua` to add/modify widgets.

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

## 🤝 Contributing

Feel free to fork this repository and submit pull requests for any improvements you'd like to make.

## 📝 Notes

This configuration is designed to be both powerful and accessible. It includes:
- A well-organized snippet system for faster development
- AI-powered completion with Copilot integration
- Comprehensive documentation access
- Performance optimizations for a smooth editing experience
- A Zenful, distraction-free interface

## 📄 License

MIT License - Feel free to use and modify as you see fit.
