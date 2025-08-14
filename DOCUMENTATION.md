# Neovim Configuration Documentation

This document provides an overview of the Neovim configuration, detailing the workflow philosophy, key plugins, and important key mappings.

## Workflow Philosophy

The configuration is built around the principles of efficiency, modularity, and seamless integration, aiming to create a powerful development environment within Neovim.

- **Efficiency**: Leverage powerful plugins for common tasks (fuzzy finding, file browsing, LSP) to minimize manual effort and maximize productivity.
- **Modularity**: Organize the configuration into distinct, self-contained plugin configurations (`lua/mlamkadm/plugs/`) for easy maintenance and extensibility.
- **Native Integration**: Prioritize the use of Neovim's built-in capabilities and standard plugin interfaces (like `nvim-lspconfig`) for a stable and well-supported setup.
- **Automation**: Automate repetitive tasks, such as formatting (`auto-save.nvim`, `42-C-Formatter.nvim`), session management (`auto-session`), and terminal operations (`toggleterm.nvim` mappings).
- **Extensibility**: Design the structure to easily add new plugins or modify existing ones without disrupting the core setup.

## Core Plugin Categories and Highlights

### Language Server Protocol (LSP) & Completion

Provides intelligent code assistance.

- **`neovim/nvim-lspconfig`**: Core plugin for configuring LSP servers.
- **`williamboman/mason.nvim` & `williamboman/mason-lspconfig.nvim`**: Manage and install LSP servers, ensuring `clangd`, `pyright`, `gopls`, `lua_ls`, `bashls`, and `marksman` are available.
- **`hrsh7th/nvim-cmp`**: Autocompletion engine.
  - Sources: LSP (`cmp-nvim-lsp`), Buffers (`cmp-buffer`), Paths (`cmp-path`), LuaSnip (`cmp_luasnip`), Zsh (`cmp-zsh`), Copilot (`copilot-cmp`).
  - Integrates with `LuaSnip` for snippet expansion.
- **`zbirenbaum/copilot.lua`**: GitHub Copilot integration, providing AI-powered suggestions.
- **`jose-elias-alvarez/null-ls.nvim`**: Provides formatting and linting capabilities through external tools.
- **`jay-babu/mason-null-ls.nvim`**: Bridge between Mason and null-ls for automatic tool installation.

### File Navigation & Management

Efficiently find and manage files and buffers.

- **`nvim-telescope/telescope.nvim`**: Fuzzy finder for files, buffers, LSP symbols, git status, etc.
  - Enhanced with `telescope-fzf-native.nvim` for faster sorting.
  - Includes `telescope-frecency.nvim` for accessing frequently used files.
- **`nvim-neo-tree/neo-tree.nvim`**: File explorer with git integration and intuitive mappings.
- **`akinsho/toggleterm.nvim`**: Manage integrated terminal instances.

### Syntax Highlighting & Code Analysis

Enhanced code readability and understanding.

- **`nvim-treesitter/nvim-treesitter`**: Improved syntax highlighting and code analysis for numerous languages.
  - Includes `nvim-treesitter-refactor` for smart renaming and navigation features.

### Markdown & Writing

Comprehensive Markdown editing experience.

- **`jakewvincent/mkdnflow.nvim`**: Navigation and utilities for Markdown files.
- **`iamcco/markdown-preview.nvim`**: Real-time browser preview.
- **`lukas-reineke/headlines.nvim`**: Enhanced headings and code block highlighting.
- **`michaelb/sniprun`**: Execute code blocks directly from Markdown.

### Utilities & UI

Enhance the overall user experience.

- **`numToStr/Comment.nvim`**: Easy code commenting.
- **`windwp/nvim-autopairs`**: Auto-close brackets and quotes.
- **`Pocco81/auto-save.nvim`**: Automatically save files.
- **`rmagatti/auto-session`**: Automatically save and restore sessions.
- **`sontungexpt/sttusline`**: Customizable status line.
- **`folke/which-key.nvim`**: Shows available keybindings.
- **`sindrets/winshift.nvim`**: Easily move and resize windows.
- **`jose-elias-alvarez/null-ls.nvim`**: Provides formatting and linting capabilities through external tools.

## Key Mappings (Leader is Space)

### General

- `<leader>c`: Clear search highlighting.
- `<leader>r`: Reload configuration.
- `<leader>s`: Save file.
- `<leader>q`: Quit all.

### Window Management

- `<C-h/j/k/l>`: Move between windows.
- `<leader>-`: Horizontal split.
- `<leader>=`: Vertical split.
- `<C-Left/Right/Up/Down>`: Resize windows.
- `<leader>tk`: Change split orientation (vertical to horizontal).
- `<leader>th`: Change split orientation (horizontal to vertical).

### File Navigation

- `<leader><leader>`: Find files (Telescope).
- `<C-n>`: Toggle Neo-tree file explorer.
- `<leader><tab>`: Toggle Neo-tree (float).
- `<leader>b`: List buffers (Telescope).
- `<leader>i`: Find git files (Telescope).
- `<leader>f`: Refresh Neo-tree.
- `<leader>n`: Find current file in Neo-tree.
- `<leader>r`: Resume last Telescope picker.

### Search & Find

- `<leader>/`: Live grep with arguments (Telescope).
- `<leader>fw`: Find word under cursor (Telescope).
- `<leader>fr`: Recent files (Telescope).
- `<leader>fu`: Undo tree (Telescope).
- `<leader>fh`: Help tags (Telescope).
- `<leader>fk`: Key maps (Telescope).
- `<leader>fc`: Commands (Telescope).
- `<leader>fm`: Marks (Telescope).
- `<leader>fo`: Recent files (old) (Telescope).

### LSP & Code Actions

- `gd`: Go to definition (LSP).
- `K`: Hover.
- `<leader>rn`: Rename.
- `<leader>ca`: Code actions.
- `<leader>ld`: LSP definitions (Telescope).
- `<leader>lr`: LSP references (Telescope).
- `<leader>li`: LSP implementations (Telescope).
- `<leader>ls`: LSP document symbols (Telescope).
- `<leader>lw`: LSP workspace symbols (Telescope).
- `<leader>lt`: LSP type definitions (Telescope).
- `<leader>e`: Show line diagnostics.
- `[d` / `]d`: Navigate diagnostics.
- `grr`: Smart rename (Treesitter).
- `gnd`: Go to definition (Treesitter).
- `gnD`: List definitions (Treesitter).
- `gO`: List definitions (TOC - Treesitter).

### Git Integration (Telescope)

- `<leader>gc`: Git commits.
- `<leader>gb`: Git branches.
- `<leader>gs`: Git status.
- `<leader>gf`: Git files.

### Terminal & External Tools

- `<C-t>`: Toggle terminal (`toggleterm.nvim`).
- `<leader>gg`: Toggle Lazygit.
- `<leader>jt`: Toggle Btop.
- `<leader>jd`: Toggle Lazydocker.
- `<leader>jy`: Toggle Yazi (file manager).
- `<leader>ja`: Toggle AI Shell.
- `<leader>jg`: Preview current file with Glow.
- `<leader>mr`: Run `make run`.
- `<leader>mm`: Run `make`.
- `<leader>mc`: Run `make clean`.
- `<leader>mf`: Run `make fclean`.

### Markdown

- `<leader>mp`: Start Markdown preview.
- `<leader>ms`: Stop Markdown preview.
- `<leader>mt`: Toggle Markdown preview (or toggle checkbox via `keymaps.lua`).
- `<leader>rr`: Run code block (normal or visual mode).
- `<leader>ml`: Paste clipboard content as Markdown link.
- `<leader>mc`: Insert a code block.

### Copilot

- `<C-l>`: Accept Copilot suggestion.
- `<C-]>`: Dismiss Copilot suggestion.
- `<M-]>` / `<M-[>`: Cycle through Copilot suggestions.

### Formatting

- `<leader>f`: Format the current buffer using LSP or external formatters (including 42 Norm for C/C++ files).
- Auto-formatting on save is enabled for all supported filetypes.

### Snippets & Completion

- `<Tab>`: Navigate/select next item in completion/snippet.
- `<S-Tab>`: Navigate/select previous item in completion/snippet.
- `<C-Space>`: Trigger completion menu.
- `<CR>`: Confirm completion selection.

