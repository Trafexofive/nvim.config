# Neovim Keymaps & Workflows

This document outlines the primary keybindings and operational workflows for this Neovim configuration.

## 🔑 Global Keymaps

The leader key is set to `(Space)`.

### General
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>c` | `:nohl` | Clear search highlighting |
| `<leader>s` | `:w` | Fast save current buffer |
| `<leader>q` | `:wa...:qa` | Save all and quit Neovim |
| `<leader>r` | `:so %` | Reload current configuration file |
| `<leader>f` | LSP Format | Format current buffer using active LSP |
| `n / N` | Search | Next/Prev match (stays centered with `zzzv`) |
| `<C-Tab>` | Switch Buffer | Toggle between the current and last used buffer |

### Window Management
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>-` | Split Horizontal | Create a horizontal split |
| `<leader>=` | Split Vertical | Create a vertical split |
| `<C-h/j/k/l>` | Navigate | Move between splits (Left/Down/Up/Right) |
| `<C-Arrows>` | Resize | Resize active split |

### Tab Management
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>t` | `:tabnew` | Open a new tab |
| `<leader>tc` | `:close` | Close current tab |
| `<leader>to` | `:tabonly` | Close all other tabs |

---

## 📂 Workflows

### 1. Session Management
The configuration uses `auto-session` for seamless project switching.

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ss` | Session Picker | Open Telescope picker with README preview |
| `<leader>sS` | Save Session | Manually save the current session |
| `<leader>sr` | Restore | Restore session for the current CWD |
| `<leader>sd` | Delete | Open picker to delete a session |
| `<leader>Q` | Dashboard | Save session and return to dashboard |

**Workflow:**
- Start `nvim` in any directory; it will auto-restore or create a session.
- Use `<leader>ss` to switch between projects instantly. Your layout and terminals are preserved.

### 2. Terminal & TUI (Pop-up Bin)
All TUIs and terminals open in centered floating windows.

| Key | Action | Description |
|-----|--------|-------------|
| `<C-t>` | Terminal | Toggle a floating shell |
| `<leader>tt` | TUI Registry | Browse all available TUI tools |
| `<leader>ts` | Switch | Switch between currently running pop-ups |
| `<leader>jj` | Lazygit | Toggle Lazygit |
| `<leader>jd` | Lazydocker | Toggle Lazydocker |
| `<leader>jf` | Yazi | Toggle File Manager |
| `<leader>jt` | Btop | Toggle System Monitor |
| `<leader>jc` | Copilot | Toggle AI Chat (Right aligned) |

**Workflow:**
- Press `<leader>jj` to commit, then `<C-t>` or `q` to hide and return to code.
- Pop-ups are persistent; if you hide a shell, its state is kept.

### 3. Markdown Integration
Enhanced markdown editing with `mkdnflow.nvim` and `glow`.

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>mp` | Preview | Preview current file with `glow` |
| `<leader>mP` | Browse | Browse all Markdown files in CWD with `glow` |

**Workflow:**
- Use standard Markdown syntax. `mkdnflow` handles list toggling and link following.
- Press `<leader>mp` for a rich TUI preview.

### 4. RSS Feed (FeedMe)
Stay updated within Neovim.

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>fm` | Open FeedMe | Launch the RSS reader |
| `<CR>` | Open Link | Open selected article in browser |
| `r` | Toggle Read | Mark article as read/unread |
| `R` | Refresh | Fetch latest updates from feeds |
| `q` | Close | Exit FeedMe |

---

## 🛠️ Productivity Tools
- **Vim Motions Registry**: `<leader>vm` - Interactive guide for motions.
- **Make Commands**: `<leader>mm` (Build), `<leader>mr` (Run), `<leader>mc` (Clean).
- **LSP Diagnostics**: Use standard Neovim LSP bindings (usually under `<leader>l`).
