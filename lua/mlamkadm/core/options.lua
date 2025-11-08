vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.cursorline = true

vim.opt.termguicolors = true
--vim.opt.background = "dark"
vim.opt.signcolumn = "yes"

-- Zen-focused options
vim.opt.scrolloff = 8        -- Keep cursor centered
vim.opt.sidescrolloff = 8    -- Horizontal scrolloff
vim.opt.updatetime = 250     -- Faster completion
vim.opt.timeoutlen = 300     -- Faster which-key
vim.opt.splitbelow = true    -- Intuitive splits
vim.opt.splitright = true
vim.opt.list = true          -- Show invisible chars
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split' -- Live preview of substitutions
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.backspace = "indent,eol,start"

-- Session options
vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,localoptions"

-- Example using a list of specs with the default options
vim.g.mapleader = " "         -- Make sure to set `mapleader` before lazy so your mappings are correct
vim.g.maplocalleader = "\\\\" -- Same for `maplocalleader`

-- wl-clipboard
vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<leader>y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from clipboard" })

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Markdown options
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.spell = false -- Enable per buffer in filetype autocommand

-- Auto-save buffers on focus lost or leaving insert mode
vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost", "BufLeave", "WinLeave", "TabLeave" }, {
    pattern = "*",
    command = "silent! wall",
    desc = "Auto save all files on leaving insert mode or losing focus"
})
