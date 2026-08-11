-- Treesitter is blocked for markdown by the monkey-patch in init.lua.
-- This file provides regex-based syntax highlighting as fallback.
vim.cmd("syntax enable")

-- mkdnflow dropped the ft_plugin config key; set these locally here.
vim.opt_local.spell = true
vim.opt_local.wrap = true
