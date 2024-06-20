
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.number = true
--vim.opt.undo_history = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.cursorline = true

vim.opt.termguicolors = true
--vim.opt.background = "dark"
vim.opt.signcolumn = "yes"

vim.opt.backspace = "indent,eol,start"


-- Example using a list of specs with the default options
vim.g.mapleader = " "       -- Make sure to set `mapleader` before lazy so your mappings are correct
vim.g.maplocalleader = "\\" -- Same for `maplocalleader`


if vim.fn.executable('wl-copy') == 1 then
  vim.g.clipboard = {
    name = 'wl-clipboard',
    copy = {
      ['+'] = 'wl-copy',
      ['*'] = 'wl-copy',
    },
    paste = {
      ['+'] = 'wl-paste',
      ['*'] = 'wl-paste',
    },
    cache_enabled = 1,
  }

  -- Yank to system clipboard
  vim.api.nvim_set_keymap('n', 'y', '"+y', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('v', 'y', '"+y', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('n', 'yy', '"+yy', { noremap = true, silent = true })
end

