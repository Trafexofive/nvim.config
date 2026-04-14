-- lua/mlamkadm/plugs/nvimcmp.lua
return {
    -- Completion Engine
    {
        "hrsh7th/nvim-cmp",
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            -- Sources
            "hrsh7th/cmp-nvim-lsp",      -- LSP Source
            "hrsh7th/cmp-buffer",        -- Buffer Source
            "hrsh7th/cmp-path",          -- Path Source
            "hrsh7th/cmp-cmdline",       -- Cmdline Source
            "saadparwaiz1/cmp_luasnip",  -- Snippet Source
            "hrsh7th/cmp-nvim-lua",      -- Lua Source
            "zbirenbaum/copilot-cmp",    -- Copilot Source
            "tamago324/cmp-zsh",         -- Zsh Source
            "hrsh7th/cmp-emoji",         -- Emoji Source
            "lukas-reineke/cmp-rg",      -- Ripgrep Source
            "petertriho/cmp-git",        -- Git Source
            "david-kunz/cmp-npm",        -- NPM Source

            -- Snippet Engine
            "L3MON4D3/LuaSnip",

            -- UI Icons
            "onsails/lspkind.nvim",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local lspkind = require("lspkind")

            -- Load VSCode-like snippets
            require("luasnip.loaders.from_vscode").lazy_load()
            luasnip.config.setup({}) 

            -- Helper function for Tab/S-Tab navigation with Luasnip
            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                
                -- Sources Configuration
                sources = cmp.config.sources({
                    { name = "copilot",  group_index = 2, priority = 100 }, 
                    { name = "nvim_lsp", priority = 90 },
                    { name = "luasnip",  priority = 80 },
                    { name = "path", priority = 70 },
                }, {
                    { name = "buffer", keyword_length = 3 },
                    { name = "emoji" },
                    { name = "npm" },
                    { name = "zsh" },
                    { name = "rg", keyword_length = 3 },
                }),

                -- Key Mappings
                mapping = cmp.mapping.preset.insert({
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.abort(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item
                    
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    
                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),

                -- Formatting
                formatting = {
                    format = lspkind.cmp_format({
                        mode = "symbol_text",
                        maxwidth = 50,
                        ellipsis_char = "...",
                        symbol_map = {
                            Copilot = "",
                            nvim_lsp = "λ",
                            luasnip = "⎋",
                            buffer = "Ω",
                            path = "🖫",
                            emoji = "☺",
                            rg = "",
                        },
                        -- Custom format function
                        before = function(entry, vim_item)
                            return vim_item
                        end
                    }),
                },

                -- Window Appearance
                window = {
                    completion = cmp.config.window.bordered({
                        border = "rounded",
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
                    }),
                    documentation = cmp.config.window.bordered({
                        border = "rounded",
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
                    }),
                },
                
                -- Experimental
                experimental = {
                    ghost_text = true, 
                },
            })

            -- Filetype Specific Configs
            cmp.setup.filetype("gitcommit", {
                sources = cmp.config.sources({
                    { name = "git" },
                }, {
                    { name = "buffer" },
                })
            })
            
            cmp.setup.filetype({ "markdown", "help" }, {
                 sources = cmp.config.sources({
                    { name = "luasnip" },
                    { name = "path" },
                 }, {
                    { name = "buffer" },
                    { name = "emoji" },
                 })
            })

            cmp.setup.filetype("smelt", {
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 100 },
                    { name = "luasnip", priority = 90 },
                    { name = "path", priority = 70 },
                }, {
                    { name = "buffer", keyword_length = 2 },
                }),
            })

            -- Command Line Config
            cmp.setup.cmdline({ '/', '?' }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'buffer' }
                }
            })

            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = 'path' }
                }, {
                    { name = 'cmdline' }
                })
            })
        end,
    },

    -- Snippet Engine Config
    {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
            local ls = require("luasnip")
            local types = require("luasnip.util.types")
            
            ls.setup({
                history = true,
                update_events = "TextChanged,TextChangedI",
                delete_check_events = "TextChanged,InsertLeave",
                ext_opts = {
                    [types.choiceNode] = {
                        active = {
                            virt_text = { { "●", "GruvboxOrange" } },
                        },
                    },
                    [types.insertNode] = {
                        active = {
                            virt_text = { { "●", "GruvboxBlue" } },
                        },
                    },
                },
            })

            -- Load Custom Snippets
            require("luasnip.loaders.from_vscode").lazy_load()
            require("luasnip.loaders.from_lua").load({ paths = { vim.fn.stdpath("config") .. "/LuaSnip" } })
        end,
    },

    -- Zsh Completion Source Config
    {
        'tamago324/cmp-zsh',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            require 'cmp_zsh'.setup {
                zshrc = true,
                filetypes = { "deoledit", "zsh" },
            }
        end
    },

    -- Copilot CMP Source
    {
        "zbirenbaum/copilot-cmp",
        dependencies = { "copilot.lua" },
        config = function()
            require("copilot_cmp").setup()
        end,
    },
}
