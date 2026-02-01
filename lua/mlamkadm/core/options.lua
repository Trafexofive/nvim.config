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
vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

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

-- Intelligent Auto-save: Saves valid, writeable buffers when focus is lost or mode changes
local function smart_autosave()
    local bufs = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufs) do
        if vim.api.nvim_buf_is_valid(buf) 
           and vim.api.nvim_buf_get_option(buf, "modified") 
           and vim.api.nvim_buf_get_option(buf, "buftype") == "" 
           and vim.api.nvim_buf_get_name(buf) ~= "" 
        then
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("silent! write")
            end)
        end
    end
end

vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost", "BufLeave", "TermClose" }, {
    pattern = "*",
    callback = smart_autosave,
    desc = "Intelligent auto-save for valid file buffers"
})

-- Jump to last known cursor position when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
    desc = "Restore last cursor position",
})
