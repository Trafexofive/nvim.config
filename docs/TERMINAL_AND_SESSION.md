# Terminal and Session Management Overhaul

## Features

### Advanced Terminal Management
The terminal system has been completely rewritten (`lua/mlamkadm/core/terminal.lua`) to support:
- **Multiple Instances**: Create and manage multiple terminal instances (e.g., multiple shells, logs).
- **Persistence**: Terminals are automatically saved to disk (per project/CWD) and restored when you open the project.
- **Toggles**: Toggle visibility of specific terminals or cycle through them.
- **TUI Registry**: Pre-configured TUIs (Lazygit, Btop, Docker, etc.) are preserved and enhanced.
- **Telescope Integration**: Easily list and switch between active terminals.

### Enhanced Session Management
Session management (`lua/mlamkadm/core/session_manager.lua` & `lua/mlamkadm/plugs/session.lua`) now integrates with the terminal system:
- **Auto-Restore**: Terminals are restored alongside your file buffers when loading a session.
- **Project Isolation**: Terminal sessions are stored separately for each project CWD.
- **Hooks**: Automatic saving/restoring on `VimLeave`, `DirChanged`, and Session commands.

## Keymaps

| Key | Description |
| :--- | :--- |
| `<C-t>` | Toggle primary shell |
| `<leader>tn` | Create new terminal instance |
| `<leader>ts` | Switch between active terminals (Telescope) |
| `<leader>tt` | Show TUI Registry (launch pre-configured tools) |
| `<leader>jj` | Toggle Lazygit |
| `<leader>jd` | Toggle Lazydocker |
| `<leader>jt` | Toggle Btop |
| `<leader>ss` | Search sessions (with README preview) |
| `<leader>sr` | Restore session for CWD |
| `<leader>sS` | Save session |

## Implementation Details

- **Terminal Storage**: JSON files stored in `stdpath("data")/term_sessions/`.
- **Session Plugin**: Uses `auto-session` with custom hooks for terminal integration.
