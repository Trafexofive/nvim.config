-- ************************************************************************** --
--                                                                            --
--                                                        :::      ::::::::   --
--   init.lua                                           :+:      :+:    :+:   --
--                                                    +:+ +:+         +:+     --
--   By: mlamkadm <mlamkadm@student.42.fr>          +#+  +:+       +#+        --
--                                                +#+#+#+#+#+   +#+           --
--   Created: 2025/01/01 11:20:17 by mlamkadm          #+#    #+#             --
--   Updated: 2025/01/01 11:20:17 by mlamkadm         ###   ########.fr       --
--                                                                            --
-- ************************************************************************** --

-- Core settings and lazy loading
require("mlamkadm.core")
require("mlamkadm.lazy")
-- require("mlamkadm.core.mason")
-- require("mlamkadm.core.terminal")
-- require("mlamkadm.core.cmp")
-- require("mlamkadm.core.winshift")
-- require("mlamkadm.core.gemini-integration").setup()
-- require("mlamkadm.core.ollama-mk2").setup()
-- require("mlamkadm.core.ollama-vi-mk2").setup()
-- require("mlamkadm.core.ollama").setup()
-- require("mlamkadm.core.ollama-mk2").setup({
--     -- Custom configuration (optional)
--     host = "http://localhost",
--     port = 11434,
--     default_model = "llama2",
--     keymaps = {
--         prompt = "<leader>op",
--         inline = "<leader>oi",
--         selection = "<leader>os",
--         chat = "<leader>oc",
--     }
-- })
-- Comment.nvim setup
require('Comment').setup()
require("mlamkadm.core.bespokePlugs.monkeytype")

-- Mason and LSP setup
require("mason").setup()
-- require("mason-lspconfig").setup({
--     ensure_installed = { "lua_ls", "clangd", "typos_lsp", "rust_analyzer", "jsonls", "html", "cssls", "dockerls", "bashls", "vimls", "pyright", "gopls", "diagnosticls" },
-- })

local lspconfig = require("lspconfig")
local server_configs = {
    lua_ls = {
        settings = {
            Lua = {
                diagnostics = { globals = { "vim" } },
            },
        },
    },
    clangd = {},
    typos_lsp = {},
}

for server, config in pairs(server_configs) do
    lspconfig[server].setup(config)
end

-- Automatically stop terminal jobs on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        vim.cmd("silent! call jobstop(b:terminal_job_id)")
    end,
})

-- Cmp_zsh setup
require 'cmp_zsh'.setup {
    zshrc = true,
    filetypes = { "deoledit", "zsh" },
}

-- Nvim-web-devicons setup
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

-- Symbols-outline setup
require("symbols-outline").setup()

-- Markdown setup
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- Enable spell checking for markdown files
    vim.opt_local.spell = true
    -- Enable text wrapping
    vim.opt_local.wrap = true
    -- Enable line breaking at word boundaries
    vim.opt_local.linebreak = true
    -- Highlight matching brackets
    vim.opt_local.showmatch = true
  end,
})
