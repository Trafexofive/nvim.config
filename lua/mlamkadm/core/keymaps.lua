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

-----------------------------------------------------------
-- Vim Motions Registry shortcuts
-----------------------------------------------------------

-- Open the Vim motions registry
map('n', '<leader>vm', '<cmd>lua require("mlamkadm.utils.vim_motions_cmd").show_motions_cmd()<cr>', { desc = 'Open Vim Motions Registry' })

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

-- Save current session and return to dashboard
map('n', '<leader>Q', function()
    -- Save current session while preserving CWD to prevent session corruption
    local current_dir = vim.fn.getcwd()
    
    -- Use auto-session command to save the session (since rmagatti/auto-session is being used)
    vim.cmd('silent! SessionSave')
    
    -- Ensure we're still in the same directory after saving
    vim.fn.chdir(current_dir)
    
    -- Close all windows except the current one (we'll replace it with dashboard)
    local current_win = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= current_win then
            pcall(vim.api.nvim_win_close, win, true)  -- force close other windows
        end
    end
    
    -- Close all buffers except dashboard
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local ft = vim.bo[buf].filetype
        if vim.api.nvim_buf_is_loaded(buf) and ft ~= 'snacks_dashboard' and ft ~= 'alpha' and vim.api.nvim_buf_get_name(buf) ~= '' then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
    end
    
    -- Show dashboard (using snacks if available, otherwise alpha fallback)
    local snacks_ok, snacks = pcall(require, 'snacks')
    if snacks_ok and snacks.dashboard then
        snacks.dashboard()
    else
        vim.cmd('Alpha')
    end
end, { desc = 'Save session and return to dashboard' })

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

-- RSS Reader
map('n', '<leader>fm', '<cmd>FeedMe<CR>', { desc = 'Open FeedMe RSS' })
map('n', '<leader>fs', function() require('mlamkadm.core.rss').telescope_search() end, { desc = 'Search RSS Feeds' })

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

-- Reliable alternate buffer switching (Leader-Tab) with Zen UX
local switch_notify_id = nil
map('n', '<leader><Tab>', function()
    local alternate_buf = vim.fn.bufnr('#')
    if alternate_buf ~= -1 and vim.api.nvim_buf_is_valid(alternate_buf) then
        vim.cmd('buffer #')
        
        -- Gather buffer info for rich feedback
        local buf_name = vim.api.nvim_buf_get_name(0)
        local filename = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":t") or "[No Name]"
        local filepath = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":~:.:h") or ""
        local line_count = vim.api.nvim_buf_line_count(0)
        local ft = vim.bo.filetype
        
        -- Get icon
        local icon = "󰈹"
        local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
        if devicons_ok then
            local f_icon, _ = devicons.get_icon(filename, vim.fn.expand('%:e'), { default = true })
            if f_icon then icon = f_icon end
        end

        -- Construct Zen message
        local msg = string.format(" %s %s\n 󰉖 %s\n  %d lines", icon, filename, filepath, line_count)
        
        -- Notify with replace to avoid spam
        local notify_ok, notify = pcall(require, "notify")
        if notify_ok then
            switch_notify_id = notify(msg, "info", {
                title = "Flash Switch",
                icon = "⚡",
                timeout = 1000,
                replace = switch_notify_id,
                hide_from_history = true,
                animate = false, -- Snappy
            })
        else
            vim.notify(msg, vim.log.levels.INFO, { title = "Flash Switch" })
        end
    else
        vim.notify("No alternate buffer", vim.log.levels.WARN, { title = "Flash Switch", icon = "" })
    end
end, { desc = 'Switch to alternate buffer with Zen feedback' })


-- Polymorphic "Smart Find" (<leader><leader>)
-- Automatically chooses between git_files (if in repo) or find_files (if not)
map('n', '<leader><leader>', function()
    local has_telescope, telescope_builtin = pcall(require, 'telescope.builtin')
    if not has_telescope then
        vim.notify("Telescope not installed", vim.log.levels.ERROR)
        return
    end

    -- Check if inside git repo
    local is_git = vim.fn.system("git rev-parse --is-inside-work-tree"):match("true")
    
    if is_git then
        telescope_builtin.git_files({ show_untracked = true })
    else
        telescope_builtin.find_files({ hidden = true })
    end
end, { desc = 'Smart Find Files (Git/All)' })


