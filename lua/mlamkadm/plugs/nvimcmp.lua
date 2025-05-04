-- lua/mlamkadm/plugs/nvimcmp.lua
return {
    -- Completion Engine
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter", -- Load when starting insert mode
        dependencies = {
            -- Sources (ensure these plugins are listed elsewhere too, e.g., under lsp-zero)
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "saadparwaiz1/cmp_luasnip",
            "hrsh7th/cmp-nvim-lua",
            "zbirenbaum/copilot-cmp",
            "tamago324/cmp-zsh",

            -- Snippet Engine
            "L3MON4D3/LuaSnip",

            -- Optional UI Icons
            "onsails/lspkind.nvim",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local lspkind = require("lspkind") -- Optional, for icons

            -- Load snippets
            require("luasnip.loaders.from_vscode").lazy_load()
            luasnip.config.setup({}) -- Basic luasnip setup

            -- Helper function for Tab/S-Tab navigation selection with Luasnip
            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and
                vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip", keyword_length = 2 }, -- Trigger snippets with 2+ chars
                    { name = "copilot", group_index = 2 }, -- Copilot suggestions below LSP/Snippets
                    { name = "buffer",  keyword_length = 3 },
                    { name = "path" },
                    { name = "zsh" }, -- Add zsh source
                    { name = "nvim_lua" },
                }),
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<C-e>'] = cmp.mapping.abort(),
                    ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                    ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    -- Tab mapping integrates with luasnip
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete() -- Complete if there's text before cursor
                        else
                            fallback() -- Fallback to normal tab behavior
                        end
                    end, { "i", "s" }), -- Insert and Select mode
                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback() -- Fallback to normal shift-tab behavior
                        end
                    end, { "i", "s" }), -- Insert and Select mode
                }),

                -- Optional: Add icons using lspkind
                formatting = {
                    format = lspkind.cmp_format({
                        mode = "symbol_text", -- Show symbol and text
                        maxwidth = 50, -- Truncate long completion items
                        ellipsis_char = "...",
                        symbol_map = { Copilot = "" }, -- Custom icon for Copilot
                        -- Show source name for debugging:
                        -- format = function(entry, vim_item)
                        --   local kind = lspkind.cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
                        --   local strings = vim.split(kind.menu, " ")
                        --   table.insert(strings, entry.source.name)
                        --   kind.menu = table.concat(strings, " ")
                        --   return kind
                        -- end
                    }),
                },

                -- Appearance settings (optional)
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },

                -- Experimental options (use with caution)
                experimental = {
                    ghost_text = false, -- Set to true to try ghost text completion
                },
            })
        end,
    },

    -- Snippet Engine Config (ensure loaded)
    {
        "L3MON4D3/LuaSnip",
        version = "v2.*",                              -- Use a specific version branch if needed
        build = "make install_jsregexp",               -- For regex support in snippets
        event = "InsertEnter",                         -- Load snippets when entering insert mode
        dependencies = { "rafamadriz/friendly-snippets" }, -- Load snippet collection
    },

    -- Zsh Completion Source Config
    {
        'tamago324/cmp-zsh',
        dependencies = { 'nvim-lua/plenary.nvim' },
        event = "VeryLazy", -- Load lazily
        config = function()
            require 'cmp_zsh'.setup {
                zshrc = true,              -- Or path to your zshrc
                filetypes = { "deoledit", "zsh" }, -- As previously configured
            }
        end
    },

    -- Copilot CMP Source (ensure copilot.lua is also configured)
    {
        "zbirenbaum/copilot-cmp",
        dependencies = { "copilot.lua" }, -- Make sure copilot itself is loaded
        event = "InsertEnter",
        config = function()
            require("copilot_cmp").setup({}) -- Basic setup is usually enough
        end,
    },
}
