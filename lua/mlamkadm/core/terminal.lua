local M = {}

require("toggleterm").setup {
    size = 50,
    direction = 'float',
    open_mapping = [[<c-\>]],
    hide_numbers = true,
    shade_filetypes = {},
    autochdir = true,
    shade_terminals = true,
    start_in_insert = true,
    terminal_mappings = true,
    close_on_exit = true,
    border = 'curved'
}

local Terminal = require('toggleterm.terminal').Terminal

local function get_term(cmd)
    return Terminal:new({
        cmd = cmd,
        dir = "git_dir",
        direction = "float",
        float_opts = {
            border = "curved",
            winblend = 13,
        },
        shade_terminals = true,
    })
end

function M.Poptui(cmd)
    get_term(cmd):toggle()
end

function M.renderMdFile()
    local open_glow = Terminal:new({
        cmd = "md-tui " .. vim.fn.expand("%"),
        direction = "float",
        float_opts = {
            border = "curved",
            winblend = 13,
        },
        shade_terminals = true,
    })
    return open_glow
end

vim.keymap.set("n", "<leader>jh", "<cmd>lua require('mlamkadm.core.terminal').Poptui('python3 /home/mlamkadm/repos/IRC-TUI-python/irc_tui.py --password Alilepro135! --user testuser --port 16000 --nick testnick --real testreal')<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<leader>jj", "<cmd>lua require('mlamkadm.core.terminal').Poptui('lazygit')<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>jt", "<cmd>lua require('mlamkadm.core.terminal').Poptui('btop')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jd", "<cmd>lua require('mlamkadm.core.terminal').Poptui('lazydocker')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jy", "<cmd>lua require('mlamkadm.core.terminal').Poptui('yazi')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jg", "<cmd>lua require('mlamkadm.core.terminal').Poptui('glow')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jo", "<cmd>lua require('mlamkadm.core.terminal').renderMdFile():toggle()<CR>", { noremap = true, silent = true })

-- Makefile
vim.keymap.set("n", "<leader>jr", "<cmd>lua require('mlamkadm.core.terminal').Poptui('make run')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jm", "<cmd>lua require('mlamkadm.core.terminal').Poptui('make')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>ja", "<cmd>lua require('mlamkadm.core.terminal').Poptui('agent')<CR>", { noremap = true, silent = true })

-- Markdown preview with glow
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("n", "<leader>gp", "<cmd>lua require('mlamkadm.core.terminal').Poptui('glow ' .. vim.fn.expand('%'))<CR>",
      { noremap = true, silent = true, buffer = 0, desc = "Preview Markdown with Glow" })
  end,
})

return M