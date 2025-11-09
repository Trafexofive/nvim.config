-----------------------------------------------------------
-- Define keymaps of Neovim and installed plugins.
-----------------------------------------------------------

local function map(mode, lhs, rhs, opts)
    local options = { silent = true } -- noremap is true by default with vim.keymap.set
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
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

-- Better vertical movement - stay centered
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

-- Keep visual selection when indenting
map('v', '<', '<gv')
map('v', '>', '>gv')

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
-- Save all buffers, stop background jobs, and quit
map('n', '<leader>q', ':wa<CR>:silent! call jobstop(0)<CR>:qa<CR>', { desc = 'Save all and quit' })

-- Exit current session and return to startup
map('n', '<leader>Q', function()
    -- Save current session if in a project
    pcall(vim.cmd, 'SessionSave')
    -- Close all buffers except dashboard
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local ft = vim.bo[buf].filetype
        if vim.api.nvim_buf_is_loaded(buf) and ft ~= 'snacks_dashboard' and ft ~= 'alpha' then
            vim.api.nvim_buf_delete(buf, { force = false })
        end
    end
    -- Show dashboard (snacks or alpha fallback)
    local has_snacks = pcall(require, 'snacks')
    if has_snacks then
        require('snacks').dashboard()
    else
        pcall(vim.cmd, 'Alpha')
    end
end, { desc = 'Save session and return to startup' })

-----------------------------------------------------------
-- Applications and Plugins shortcuts
-----------------------------------------------------------

-- Note: Plugin-specific mappings are now primarily defined
-- within their respective plugin configuration files.

-- Formatting (LSP)
map('n', '<leader>f', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', { desc = 'Format buffer' })

-- Tab Management
map('n', '<leader>t', ':tabnew<CR>')     -- open new tab
map('n', '<leader>tc', '<cmd>close<CR>') -- close current tab
map('n', '<leader>to', ':tabonly<CR>')   -- close all other tabs

-- Makefile build command
map('n', '<leader>mm', 'make<CR>', { desc = 'Make: Build' })

-- Consistent escape mapping for terminal mode
vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*",
    callback = function()
        vim.keymap.set('t', '<C-Esc>', [[<C-\><C-n>]], { buffer = true, desc = 'Exit terminal mode' })
    end,
})

-- Your plugins and other setup here (e.g., require('lazy').setup({...}))

-- Autocmd for .myl filetype alias
vim.api.nvim_create_autocmd("BufRead", {
    pattern = "*.sat",
    callback = function()
        vim.bo.filetype = "cpp" -- Swap to "c" for C-like, "lua" for Lua-like, etc.
    end,
})

-- Optional: Also handle BufNewFile for new files
vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "*.sat",
    callback = function()
        vim.bo.filetype = "cpp"
    end,
})

-- Uncategorized/staging mappings can go here

-- New buffer with a terminal
map('n', '<leader>nt', '<cmd>enew | terminal<CR>', { desc = 'New buffer with terminal' })

-- Smart ctrl-tab behavior, that remembers last used buffer
local last_buffer = nil

vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        local current_buffer = vim.api.nvim_get_current_buf()
        -- Only update if it's a different buffer and it's a real file buffer
        if last_buffer ~= current_buffer and vim.bo[current_buffer].buflisted then
            last_buffer = vim.fn.bufnr('#') -- Get the alternate buffer (previous)
        end
    end,
})

map('n', '<C-Tab>', function()
    if last_buffer and vim.api.nvim_buf_is_valid(last_buffer) and vim.bo[last_buffer].buflisted then
        vim.api.nvim_set_current_buf(last_buffer)
    else
        -- Fallback to :bnext if no valid last buffer
        vim.cmd('bnext')
    end
end, { desc = 'Switch to last used buffer' })
