-----------------------------------------------------------
-- Define keymaps of Neovim and installed plugins.
-----------------------------------------------------------

local function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

vim.g.mapleader = ' '

-----------------------------------------------------------
-- Neovim shortcuts
-----------------------------------------------------------

-- Disable arrow keys in normal mode
map('', '<up>', '<nop>')
map('', '<down>', '<nop>')
map('', '<left>', '<nop>')
map('', '<right>', '<nop>')

-- Clear search highlighting
map('n', '<leader>c', ':nohl<CR>')

-- Window split management
map('n', '<leader>-', '<cmd>split<cr>')
map('n', '<leader>=', '<cmd>vsplit<cr>')

-- Move between splits
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- Resize splits
map('n', '<C-Left>', '<cmd>vertical resize -5<cr>')
map('n', '<C-Right>', '<cmd>vertical resize +5<cr>')
map('n', '<C-Up>', '<cmd>resize +5<cr>')
map('n', '<C-Down>', '<cmd>resize -5<cr>')


-- Reload configuration
map('n', '<leader>r', ':so %<CR>')

-- Fast saving
map('n', '<leader>s', ':w<CR>')

-- Quit all
map('n', '<leader>q', ':xa<CR>')

-----------------------------------------------------------
-- Applications and Plugins shortcuts
-----------------------------------------------------------

-- Note: Plugin-specific mappings are now primarily defined
-- within their respective plugin configuration files.

-- Formatting (LSP)
map('n', '<leader>f', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', { desc = 'Format buffer' })

-- Tab Management
map('n', '<leader>t', ':tabnew<CR>')   -- open new tab
map('n', '<leader>tc', ':tabclose<CR>') -- close current tab
map('n', '<leader>to', ':tabonly<CR>')  -- close all other tabs