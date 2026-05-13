-- Set leader keys BEFORE loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\\\"

-- Neovim 0.12 ships broken markdown tree-sitter parsers in
-- /usr/share/nvim/runtime/parser/ that throw node:range() nil errors.
-- Any redraw (notification, diagnostic, focus) triggers the crash chain:
--   TSHighlighter._on_start → tree:parse() → langtree:tcall() → node:range() nil
-- Must block BEFORE any plugin or treesitter init.
--
-- 1. Override the language registration so treesitter can't find the parser.
--    vim.treesitter.language.add() with an empty table blocks parser resolution.
pcall(vim.treesitter.language.add, "markdown", {})
-- 2. Also monkey-patch start() as a safety net.
local _ts_start = vim.treesitter.start
vim.treesitter.start = function(bufnr, lang, opts)
  -- Resolve language from buffer
  local ft = vim.bo[bufnr or 0].filetype
  if (lang == "markdown" or lang == "markdown_inline")
    or (ft == "markdown" or ft == "markdown_inline") then
    return
  end
  return _ts_start(bufnr, lang, opts)
end

-- Load lazy.nvim plugin manager first
require("mlamkadm.lazy")

-- Load core settings (options, keymaps) after lazy
require("mlamkadm.core")
