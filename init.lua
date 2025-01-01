-- ************************************************************************** --
--                                                                            --
--                                                        :::      ::::::::   --
--   init.lua                                           :+:      :+:    :+:   --
--                                                    +:+ +:+         +:+     --
--   By: mlamkadm <mlamkadm@student.42.fr>          +#+  +:+       +#+        --
--                                                +#+#+#+#+#+   +#+           --
--   Created: 2025/01/01 05:51:03 by mlamkadm          #+#    #+#             --
--   Updated: 2025/01/01 05:51:03 by mlamkadm         ###   ########.fr       --
--                                                                            --
-- ************************************************************************** --

require("mlamkadm.core")
require("mlamkadm.lazy")
require("mlamkadm.core.sessions")
require("mlamkadm.core.terminal")
require("mlamkadm.core.cmp")
require("mlamkadm.core.winshift")

require('Comment').setup()

require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls" }
})

require("mason-lspconfig").setup({
    ensure_installed = { "typos_lsp" }
})

require("mason-lspconfig").setup({
    ensure_installed = { "clangd" }
})

require("lspconfig").lua_ls.setup {}
require("lspconfig").clangd.setup {}
require("lspconfig").typos_lsp.setup {}

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        vim.cmd("silent! call jobstop(b:terminal_job_id)")
    end,
})

require('glow').setup({
    glow_path = "/home/linuxbrew/.linuxbrew/bin/glow", -- will be filled automatically with your glow bin in $PATH, if any
    install_path = "~/.local/bin",                     -- default path for installing glow binary
    border = "shadow",                                 -- floating window border config
    style = "dark",                                    -- filled automatically with your current editor background, you can override using glow json style
    pager = nil,
    width = 80,
    height = 100,
    width_ratio = 1, -- maximum width of the Glow window compared to the nvim window size (overrides `width`)
    height_ratio = 1,
})

require 'cmp_zsh'.setup {
    zshrc = true,                     -- Source the zshrc (adding all custom completions). default: false
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


-- require("neoconf").setup({
--     -- override any of the default settings here
-- })


require("symbols-outline").setup()


-- deps:
-- require('img-clip').setup({
--     -- use recommended settings from above
-- })
-- require('render-markdown').setup({
--     -- use recommended settings from above
-- })
-- require('avante_lib').load()
-- -- Avante.nvim setup
-- require('avante').setup({
--   provider = "copilot", -- Recommend using Claude
--   auto_suggestions_provider = "copilot",
--   mappings = {
--     suggestion = {
--       accept = "<M-l>",
--       next = "<M-]>",
--       prev = "<M-[>",
--       dismiss = "<C-]>",
--     },
--   },
-- })

-- require('copilot').setup({
--   auto_trigger = true,
--   filetypes = {'*'},
-- })
--

-- local colors = require("sttusline.colors")

require("sttusline").setup {
    statusline_color = "StatusLine",

    laststatus = 3,
    disabled = {
        filetypes = {},
        buftypes = {},
    },
    components = {
        "mode",
        "filename",
        "git-branch",
        "git-diff",
        "%=",
        "diagnostics",
        "lsps-formatters",
        "copilot",
        "indent",
        "encoding",
        "pos-cursor",
        "pos-cursor-progress",
    },
}

