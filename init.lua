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



require 'nvim-web-devicons'.setup {
    -- your personnal icons can go here (to override)
    -- you can specify color or cterm_color instead of specifying both of them
    -- DevIcon will be appended to `name`
    override = {
        zsh = {
            icon = "",
            color = "#428850",
            cterm_color = "65",
            name = "Zsh"
        }
    },
    -- globally enable different highlight colors per icon (default to true)
    -- if set to false all icons will have the default icon's color
    color_icons = true,
    -- globally enable default icons (default to false)
    -- will get overriden by `get_icons` option
    default = true,
    -- globally enable "strict" selection of icons - icon will be looked up in
    -- different tables, first by filename, and if not found by extension; this
    -- prevents cases when file doesn't have any extension but still gets some icon
    -- because its name happened to match some extension (default to false)
    strict = true,
    -- same as `override` but specifically for overrides by filename
    -- takes effect when `strict` is true
    override_by_filename = {
        [".gitignore"] = {
            icon = "",
            color = "#f1502f",
            name = "Gitignore"
        }
    },
    -- same as `override` but specifically for overrides by extension
    -- takes effect when `strict` is true
    override_by_extension = {
        ["log"] = {
            icon = "",
            color = "#81e043",
            name = "Log"
        }
    },
    -- same as `override` but specifically for operating system
    -- takes effect when `strict` is true
    override_by_operating_system = {
        ["apple"] = {
            icon = "",
            color = "#A2AAAD",
            cterm_color = "248",
            name = "Apple",
        },
    },
}


-- require("neoconf").setup({
--     -- override any of the default settings here
-- })

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

-- vim.cmd("COQnow")
