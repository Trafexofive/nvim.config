require("toggleterm").setup {
    -- size can be a number or function which is passed the current terminal
    size = 50, --function(term)
    -- if term.direction == "horizontal" then
    --     return 15
    -- elseif term.direction == "vertical" then
    --     return vim.o.columns * 0.4
    -- end
    -- end,
    direction = 'float',
    open_mapping = [[<c-\>]], -- or { [[<c-\>]], [[<c-¥>]] } if you also use a Japanese keyboard.
    -- on_create = fun(t: Terminal), -- function to run when the terminal is first created
    -- on_open = fun(t: Terminal), -- function to run when the terminal opens
    -- on_close = fun(t: Terminal), -- function to run when the terminal closes
    -- on_stdout = fun(t: Terminal, job: number, data: string[], name: string) -- callback for processing output on stdout
    -- on_stderr = fun(t: Terminal, job: number, data: string[], name: string) -- callback for processing output on stderr
    -- on_exit = fun(t: Terminal, job: number, exit_code: number, name: string) -- function to run when terminal process exits
    hide_numbers = true, -- hide the number column in toggleterm buffers
    shade_filetypes = {},
    autochdir = true,    -- when neovim changes it current directory the terminal will change it's own when next it's opened
    -- highlights = {
    --     -- highlights which map to a highlight group name and a table of it's values
    --     -- NOTE: this is only a subset of values, any group placed here will be set for the terminal window split
    --     Normal = {
    --         guibg = "<VALUE-HERE>",
    --     },
    --     NormalFloat = {
    --         link = 'Normal'
    --     },
    --     FloatBorder = {
    --         guifg = "<VALUE-HERE>",
    --         guibg = "<VALUE-HERE>",
    --     },
    -- },
    shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
    -- shading_factor = '<number>', -- the percentage by which to lighten dark terminal background, default: -30
    -- shading_ratio = '<number>', -- the ratio of shading factor for light/dark terminal background, default: -3
    start_in_insert = true,
    -- insert_mappings = true, -- whether or not the open mapping applies in insert mode
    terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
    -- persist_size = true,
    -- persist_mode = true, -- if set to true (default) the previous terminal mode will be remembered
    -- direction = 'vertical' | 'horizontal' | 'tab' | 'float',
    close_on_exit = true, -- close the terminal window when the process exits
    -- clear_env = false, -- use only environmental variables from `env`, passed to jobstart()
    --  -- Change the default shell. Can be a string or a function returning a string
    -- shell = vim.o.shell,
    -- auto_scroll = true, -- automatically scroll to the bottom on terminal output
    -- -- This field is only relevant if direction is set to 'float'
    -- float_opts = {
    --   -- The border key is *almost* the same as 'nvim_open_win'
    --   -- see :h nvim_open_win for details on borders however
    --   -- the 'curved' border is a custom border type
    --   -- not natively supported but implemented in this plugin.
    border = 'curved' --| 'double' | 'shadow' | 'curved' | ... other options supported by win open
    --   -- like `size`, width, height, row, and col can be a number or function which is passed the current terminal
    --   width = <value>,
    --   height = <value>,
    --   row = <value>,
    --   col = <value>,
    --   winblend = 3,
    --   zindex = <value>,
    --   title_pos = 'left' | 'center' | 'right', position of the title of the floating window
    -- },
    -- winbar = {
    --   enabled = false,
    --   name_formatter = function(term) --  term: Terminal
    --     return term.name
    --   end
    -- },
    -- responsiveness = {
    --   -- breakpoint in terms of `vim.o.columns` at which terminals will start to stack on top of each other
    --   -- instead of next to each other
    --   -- default = 0 which means the feature is turned off
    --   horizontal_breakpoint = 135,
    -- }
}

local Terminal = require('toggleterm.terminal').Terminal

-- local options = {
--     dir = "git_dir", -- Optional: opens in git repo root
--     direction = "float",
--     float_opts = {
--         border = "curved",
--         winblend = 13,      -- Transparency (0-100)
--     },
--     shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
-- }

local openGlowCurrentFile = function()
    local openGlow = Terminal:new({
        cmd = "glow " .. vim.fn.expand("%"),
        dir = "git_dir", -- Optional: opens in git repo root
        direction = "float",
        float_opts = {
            border = "curved",
            winblend = 13,      -- Transparency (0-100)
        },
        shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
    })
    return openGlow
end

local function renderMdFile() 
    local open_glow = Terminal:new({
        cmd = "md-tui " .. vim.fn.expand("%"),
        direction = "float",
        float_opts = {
            border = "curved",
            winblend = 13,      -- Transparency (0-100)
        },
        shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
    })
    return open_glow
end

function GetFileNames()
    local file = vim.fn.expand("%")
    local file_name = vim.fn.fnamemodify(file, ":t")
    local file_extension = vim.fn.fnamemodify(file, ":e")
    return file_name, file_extension
end

local function get_term(cmd)
    return Terminal:new({
        cmd = cmd,
        dir = "git_dir", -- Optional: opens in git repo root
        direction = "float",
        float_opts = {
            border = "curved",
            winblend = 13,      -- Transparency (0-100)
        },
        shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
    })
end

function Poptui(cmd)
    get_term(cmd):toggle()
end



vim.keymap.set("n", "<leader>jh", function()
    Poptui(
    "python3 /home/mlamkadm/repos/IRC-TUI-python/irc_tui.py --password Alilepro135! --user testuser --port 16000 --nick testnick --real testreal")
end)

-- vim.keymap.set("n", "<leader>jh", function ()
-- poptui("irssi")

-- end)

vim.api.nvim_set_keymap("n", "<leader>jj", "<cmd>lua Poptui('lazygit')<CR>", { noremap = true, silent = true })
-- Keymap to toggle btop terminal
vim.keymap.set("n", "<leader>jt", "<cmd> lua Poptui('btop')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jd", "<cmd> lua Poptui('lazydocker')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jy", "<cmd> lua Poptui('yazi')<CR>", { noremap = true, silent = true })


vim.keymap.set("n", "<leader>ja", "<cmd> lua Poptui('ai')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jg", "<cmd> lua Poptui('glow')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jo", "<cmd> lua renderMdFile:toggle()<CR>", { noremap = true, silent = true })

-- Makefile

vim.keymap.set("n", "<leader>jr", "<cmd> lua Poptui('make run')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jm", "<cmd> lua Poptui('make')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>ja", "<cmd> lua Poptui('agent')<CR>", { noremap = true, silent = true })

-- Markdown preview with glow
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("n", "<leader>gp", "<cmd>lua require('mlamkadm.core.terminal').Poptui('glow ' .. vim.fn.expand('%'))<CR>", 
      { noremap = true, silent = true, buffer = 0, desc = "Preview Markdown with Glow" })
  end,
})

