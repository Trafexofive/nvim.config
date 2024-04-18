require("mlamkadm.core")
require("mlamkadm.lazy")


require("lazy").setup("mlamkadm.plugs")


-- require("neoconf").setup({
--     -- override any of the default settings here
-- })


local fineline = require("fine-cmdline")
local fn = fineline.fn

fineline.setup({
  cmdline = {
    -- Prompt can influence the completion engine.
    -- Change it to something that works for you
    prompt = ': ',

    -- Let the user handle the keybindings
    enable_keymaps = false
  },
  popup = {
    buf_options = {
      -- Setup a special file type if you need to
      filetype = 'FineCmdlinePrompt'
    }
  },
  hooks = {
    set_keymaps = function(imap, feedkeys)
      -- Restore default keybindings...
      -- Except for `<Tab>`, that's what everyone uses to autocomplete
      imap('<Esc>', fn.close)
      imap('<C-c>', fn.close)

      imap('<Up>', fn.up_search_history)
      imap('<Down>', fn.down_search_history)
    end
  }
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
    width = 0.5,
    height = 0.5,
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
