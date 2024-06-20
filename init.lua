require("mlamkadm.core")
require("mlamkadm.lazy")

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("lazy").setup("mlamkadm.plugs",
    {
        change_detection = {
            -- automatically check for config file changes and reload the ui
            enabled = false,
            notify = false, -- get a notification when changes are found
        },
    }
)

require('glow').setup({
    border = "shadow",         -- floating window border config
    pager = true,
    width = 80,
    height = 100,
    width_ratio = 0.7,         -- maximum width of the Glow window compared to the nvim window size (overrides `width`)
    height_ratio = 0.7,
})

require'cmp_zsh'.setup {
  zshrc = true, -- Source the zshrc (adding all custom completions). default: false
  filetypes = { "deoledit", "zsh" } -- Filetypes to enable cmp_zsh source. default: {"*"}
}


require 'nvim-web-devicons'.setup {
    override = {
        zsh = {
            icon = "",
            color = "#428850",
            cterm_color = "65",
            name = "Zsh"
        }
    },
    color_icons = true,
    default = true,
    strict = true,
    override_by_filename = {
        [".gitignore"] = {
            icon = "",
            color = "#f1502f",
            name = "Gitignore"
        }
    },
    override_by_extension = {
        ["log"] = {
            icon = "",
            color = "#81e043",
            name = "Log"
        }
    },
    override_by_operating_system = {
        ["apple"] = {
            icon = "",
            color = "#A2AAAD",
            cterm_color = "248",
            name = "Apple",
        },
    },
}


require("neoconf").setup({
    -- override any of the default settings here
})

require('Comment').setup()
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls" }
})

require("mason-lspconfig").setup({
    ensure_installed = { "clangd" }
})

require("lspconfig").lua_ls.setup {}
require("lspconfig").clangd.setup {}

require("term").setup({
    shell = vim.o.shell,
    width = 0.7,
    height = 0.7,
    anchor = "NW",
    position = "center",
    title = {
        align = "center", -- left, center or right
    },
    border = {
        chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        hl = "TermBorder",
    },
})

require("symbols-outline").setup()
