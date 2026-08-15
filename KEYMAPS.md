# Neovim Keymaps & Workflows

Leader key: `Space`. `Mod` below = Super (niri). Terminal cycling uses `<C-j>/<C-k>`, so split nav uses `<C-h>/<C-l>` (left/right) and `<C-w>j/k` (down/up).

## 🔑 General
| Key | Action |
|-----|--------|
| `<leader><leader>` | Smart Find — `git_files` (in repo) or `find_files` |
| `<leader>c` | Clear search highlighting |
| `<leader>s` | Save buffer |
| `<leader>q` | Save all + quit |
| `<leader>Q` | Save session + return to dashboard |
| `<leader>R` | Reload current config file |
| `<leader>lf` | LSP format buffer |
| `<leader>mm` | Make build |
| `n` / `N` | Next/Prev search match (centered) |
| `<C-Tab>` | Switch to last buffer |

## 🖥️ Terminal / Zellij
| Key | Action |
|-----|--------|
| `<C-t>` | Pull up / pull down the terminal popup (strict toggle — restores last-active) |
| `<C-n>` | New zellij session (hides the current one first) |
| `<C-j>` / `<C-k>` | Cycle terminals (only when visible; never drops the popup) |
| `<C-d>` | Kill current terminal + pull up the next one (popup stays focused) |
| `<C-Esc>` (term mode) | Exit terminal mode |
| `<leader>tz` | Open the project's primary zellij session (explicit, non-toggle) |
| `<leader>ts` | Switch terminal (telescope) |
| `<leader>tt` | TUI registry |
| `<leader>tn` | New zellij session |
| `<leader>nt` | New buffer with plain terminal |
| `<leader>jX` | lazygit / lazydocker / btop / yazi / glow etc. |

## 🧠 LSP
| Key | Action |
|-----|--------|
| `gd` / `gD` | Definition / Declaration |
| `gr` / `gi` | References / Implementation |
| `K` | Hover docs |
| `<C-k>` (insert) | Signature help |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action |
| `<leader>e` | Show diagnostics float |
| `[d` / `]d` | Prev/Next diagnostic |
| `[e` / `]e` | Prev/Next **error** |
| `<leader>dd` | Trouble: diagnostics list |
| `<leader>lh` | Toggle inlay hints |
| `<leader>ls` / `<leader>lw` | Document / workspace symbols (telescope) |

## 🔍 Telescope
| Key | Action |
|-----|--------|
| `<leader>ff` | Find files (all) |
| `<leader>i` / `<leader>gf` | Git files |
| `<leader>r` | Resume last picker |
| `<leader>/` | Live grep |
| `<leader>fw` | Grep word under cursor |
| `<leader>fr` | Frecency (recent files) |
| `<leader>fu` | Undo tree |
| `<leader>fh` / `fk` / `fc` / `fm` | Help / keymaps / commands / marks |
| `<leader>fo` | Old files |
| `<leader>b` | Buffers |
| `<leader>gc` / `gb` / `gs` | Git commits / branches / status |

## 💾 Session
| Key | Action |
|-----|--------|
| `<leader>ss` | Search sessions |
| `<leader>sr` | Restore session for cwd |
| `<leader>sS` | Save session |
| `<leader>sd` | Delete session |

## 📁 Files / Dirs
| Key | Action |
|-----|--------|
| `<leader><tab>` | File Manager — floating NeoTree (primary) |
| `<leader>n` | NeoTree sidebar reveal |
| `yy` (in neo-tree/netrw) | Yank full path |

**NeoTree (in-tree) bindings:**
| Key | Action |
|-----|--------|
| `L` | Create symlink → cursor node |
| `<C-j>` / `<C-k>` | Cycle sources (files → buffers → git_status) |
| `V` + `x` / `d` / `y` | Multi-select: cut / delete / copy all selected |
| `<` / `>` | Prev / next source (same as `<C-k>` / `<C-j>`) |
| click winbar tabs | Flip sources (files / buffers / git_status) |

## 🧱 Text Objects (treesitter)
| Key | Action |
|-----|--------|
| `af` / `if` | Around / inner function |
| `ac` / `ic` | Around / inner class |
| `aa` / `ia` | Around / inner parameter |
| `]]` / `[[` | Next / prev class (move) |
| `]m` / `[m` | Next / prev function (move) |
| `<CR>` / `<Tab>` | Incremental selection |

## 📋 Yank / Path
| Key | Action |
|-----|--------|
| `<leader>yp` | Yank full path |
| `<leader>yr` | Yank relative path |
| `<leader>yn` | Yank filename |

## 🔧 Misc
| Key | Action |
|-----|--------|
| `<leader>vm` | Vim motions registry |
| `<leader>fm` | Open RSS reader |
| `<leader>fs` | Search RSS feeds |
| `]t` / `[t` | Next / prev TODO comment |
| `<leader>gg` | LazyGit (floating) |
| `<leader>a` | Toggle Aerial outline |

## 🪟 Window / Split
| Key | Action |
|-----|--------|
| `<leader>-` / `<leader>=` | Split horizontal / vertical |
| `<C-h>` / `<C-l>` | Move left / right split |
| `<C-w>j` / `<C-w>k` | Move down / up split |
| `<C-arrows>` | Resize splits |
| `<leader>t` / `tc` / `to` | New / close / only tab |

## 🖥️ WM (niri) — quick reference
| Key | Action |
|-----|--------|
| `Mod+D` | Noctalia launcher |
| `Mod+Shift+R` | Restore saved session |
| `Mod+B` | Open btop |
| `Mod+V` | Clipboard history picker |
| `Mod+Shift+M` | Move window to workspace |
| `Mod+Z` | Zen (hide bar) |
| `Ctrl+Print` | Save region screenshot to disk |
| `Print` / `Shift+Print` / `Alt+Print` | Region / full / monitor → clipboard |
