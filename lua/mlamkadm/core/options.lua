-- Compatibility shim: nvim 0.11+ deprecated vim.tbl_islist in favor of
-- vim.islist. Upstream plugins (plenary, cmp, dap, mini, snacks, nui, ...)
-- still call the old name, which emits a deprecation warning on every call.
-- Point the old name at the new one once so we don't patch every plugin.
if vim.islist then
    vim.tbl_islist = vim.islist
end

-- Add Mason bin + ~/.cargo/bin to PATH (fixes linter/formatter issues and
-- finds zellij/other cargo tools, e.g. for <C-t>)
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.HOME .. "/.cargo/bin:" .. vim.env.PATH

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
vim.opt.scrolloff = 8 -- Keep cursor centered
vim.opt.sidescrolloff = 8 -- Horizontal scrolloff
vim.opt.updatetime = 250 -- Faster completion
vim.opt.timeoutlen = 300 -- Faster which-key
vim.opt.splitbelow = true -- Intuitive splits
vim.opt.splitright = true
vim.opt.list = true -- Show invisible chars
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split" -- Live preview of substitutions
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.backspace = "indent,eol,start"

-- Session options (terminal omitted: zellij owns CLI persistence now)
vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"

-- Example using a list of specs with the default options
vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct
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
    local now = os.time()
    for _, buf in ipairs(bufs) do
        if
            vim.api.nvim_buf_is_valid(buf)
            and vim.api.nvim_buf_get_option(buf, "modified")
            and vim.api.nvim_buf_get_option(buf, "buftype") == ""
            and vim.api.nvim_buf_get_name(buf) ~= ""
        then
            -- Skip buffers opened less than 2 seconds ago (likely not edited)
            local buf_age = now - math.floor(tonumber(vim.fn.getbufvar(buf, "b_mtime")) or 0)
            if buf_age < 2 then
                goto continue
            end

            -- Skip buffers with no real edits (tracked via change tick)
            local changedtick = vim.api.nvim_buf_get_changedtick(buf)
            local last_save = vim.b[buf].last_auto_save_tick or 0
            if changedtick == last_save then
                goto continue
            end

            vim.api.nvim_buf_call(buf, function()
                vim.cmd("silent! write")
            end)

            -- Track saved state to avoid re-saving unchanged buffers
            vim.b[buf].last_auto_save_tick = vim.api.nvim_buf_get_changedtick(buf)

            ::continue::
        end
    end
end

vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost", "BufLeave", "TermClose" }, {
    pattern = "*",
    callback = smart_autosave,
    desc = "Intelligent auto-save for valid file buffers",
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
