-- Override Neovim 0.12's built-in ftplugin/markdown.lua which is just
-- `vim.treesitter.start()` — this triggers node:range() nil crashes in the
-- injection subsystem with the current parser/query stack.
-- By existing here (earlier in runtimepath), the built-in never runs.
-- Fall back to regex syntax highlighting.
vim.cmd("syntax enable")
