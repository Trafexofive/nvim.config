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

--
-- Disable arrow keys
map('', '<up>', '<nop>')
map('', '<down>', '<nop>')
map('', '<left>', '<nop>')
map('', '<right>', '<nop>')

-- Clear search highlighting with <leader> and c
map('n', '<leader>c', ':nohl<CR>')

-- Toggle auto-indenting for code paste
--
--map('n', '<F2>', ':set invpaste paste?<CR>')
--vim.opt.pastetoggle = '<F2>'

-- Change split orientation
map('n', '<leader>tk', '<C-w>t<C-w>K') -- change vertical to horizontal
map('n', '<leader>th', '<C-w>t<C-w>H') -- change horizontal to vertical

-- Move around splits using Ctrl + {h,j,k,l}
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- split keymaps
map('n', '<leader>-', '<cmd>split<cr>')
map('n', '<leader>=', '<cmd>vsplit<cr>')

map('n', '<C-Left>', '<cmd>vertical resize -7<cr>')
map('n', '<C-Right>', '<cmd>vertical resize +7<cr>')
map('n', '<C-Up>', '<cmd>horizontal resize +7<cr>')
map('n', '<C-Down>', '<cmd>horizontal resize -7<cr>')

-- Reload configuration without restart nvim
map('n', '<leader>r', ':so %<CR>')

-- Fast saving with <leader> and s
map('n', '<leader>s', ':w<CR>')


map('n', '<leader>q', ':qall!<CR>')

-----------------------------------------------------------
-- Markdown shortcuts
-----------------------------------------------------------

-- Markdown preview
map('n', '<leader>mp', '<cmd>MarkdownPreview<CR>', { desc = 'Markdown Preview' })
map('n', '<leader>ms', '<cmd>MarkdownPreviewStop<CR>', { desc = 'Stop Markdown Preview' })
map('n', '<leader>mt', '<cmd>MarkdownPreviewToggle<CR>', { desc = 'Toggle Markdown Preview' })

-- Run code blocks
map('n', '<leader>rr', '<cmd>SnipRun<CR>', { desc = 'Run code block' })
map('v', '<leader>rr', '<cmd>SnipRun<CR>', { desc = 'Run selected code' })

-- Markdown utilities
map('n', '<leader>ml', '<cmd>lua require("mlamkadm.core.markdown-utils").paste_markdown_link()<CR>', { desc = 'Paste as Markdown Link' })
map('n', '<leader>mt', '<cmd>lua require("mlamkadm.core.markdown-utils").toggle_checkbox()<CR>', { desc = 'Toggle Checkbox' })
map('n', '<leader>mc', '<cmd>lua require("mlamkadm.core.markdown-utils").insert_code_block()<CR>', { desc = 'Insert Code Block' })

-----------------------------------------------------------
-- Applications and Plugins shortcuts
-----------------------------------------------------------

-- Terminal mappings
map('n', '<C-t>', ':ToggleTerm<CR>', { noremap = true }) -- open
map('t', '<C-t>', '<C-\\><C-n>')                   -- exit

-- Neo-tree mappings are now handled in the explorer plugin configuration

-- Tagbar
map('n', '<leader>z', ':TagbarToggle<CR>') -- open/close

map('n', '<leader>g', ':Glow<CR>')

-- Formatting

-- map('n', '<leader>p', '<cmd>LspZeroFormat<CR>', { noremap = true, silent = true })
map('n', '<leader>p', ':CFormat42<CR>', { noremap = true, silent = true })

-- Tab Management mappings
map('n', '<leader>t', ':tabnew<CR>') -- open new tab
map('n', '<leader>tc', ':tabclose<CR>') -- close current tab
map('n', '<leader>to', ':tabonly<CR>') -- close all tabs except current

-- Use standard Ctrl+PageUp/PageDown for tab navigation
-- map('n', '<c-j>', ':tabprevious<CR>') -- go to previous tab (conflicts with leader+j)
-- map('n', '<c-k>', ':tabNext<CR>') -- go to next tab (conflicts with leader+k)

-----------------------------------------------------------
-- automation shortcuts
-----------------------------------------------------------
---
-----------------------------------------------------------
-- Pop-ups shortcuts
-----------------------------------------------------------




