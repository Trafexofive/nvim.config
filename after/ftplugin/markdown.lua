-- Neovim 0.12's bundled markdown ftplugin starts treesitter directly.
-- With the currently pinned parser/query stack this can throw node:range()
-- decoration-provider errors for markdown injections, so keep markdown on
-- regex syntax highlighting until the parser stack is updated.
pcall(vim.treesitter.stop, 0)
vim.cmd("syntax enable")
