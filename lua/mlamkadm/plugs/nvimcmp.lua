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
            "hrsh7th/cmp-emoji", -- Emoji completions
            "lukas-reineke/cmp-rg", -- Ripgrep for search-based completions
            "petertriho/cmp-git", -- Git completions
            "david-kunz/cmp-npm", -- NPM package completions for JS/TS

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
                    { name = "copilot",  group_index = 2, max_item_count = 3 }, -- Prioritize Copilot completions
                    { name = "nvim_lsp",                  max_item_count = 8 }, -- LSP for code completion
                    { name = "luasnip",  keyword_length = 2, max_item_count = 3 }, -- Snippets with 2+ chars
                    { name = "buffer",   keyword_length = 3, max_item_count = 5 }, -- Buffer context
                    { name = "path" },
                    { name = "nvim_lua" },
                    { name = "emoji",    max_item_count = 2 }, -- Emoji completions
                    { name = "rg",       keyword_length = 3, max_item_count = 5 }, -- Ripgrep for text search
                    { name = "npm",      max_item_count = 3 }, -- NPM packages
                    { name = "zsh" }, -- Add zsh source
                    { name = "git",      max_item_count = 5 }, -- Git completions
                }),
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-j>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                    ['<C-k>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
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

                -- Enhanced formatting with better icons and styling
                formatting = {
                    format = lspkind.cmp_format({
                        mode = "symbol_text", -- Show symbol and text
                        maxwidth = 50, -- Truncate long completion items
                        ellipsis_char = "...",
                        symbol_map = {
                            Copilot = "",
                            nvim_lsp = "ﲳ",
                            luasnip = "﬌",
                            buffer = "﬘",
                            path = "ﱮ",
                            emoji = "ﲊ",
                            rg = "",
                            npm = "",
                            git = "ﱘ",
                        },
                        -- Custom format function for more control
                        before = function(entry, vim_item)
                            -- Add a source prefix to each completion item
                            local lspkind_icons = lspkind.symbolic(vim_item.kind, { with_text = false })
                            vim_item.menu = lspkind_icons .. " " .. vim_item.kind
                            return vim_item
                        end,
                    }),
                },

                -- Enhanced appearance settings with better borders and colors
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

                -- Advanced matching and sorting
                matching = {
                    disallow_fuzzy_matching = false,
                    disallow_fullfuzzy_matching = false,
                    disallow_partial_fuzzy_matching = false,
                    disallow_partial_matching = false,
                    disallow_prefix_unmatching = false,
                },
                
                -- Smart sorting based on context
                sorting = {
                    comparators = {
                        -- Priority to Copilot suggestions
                        function(entry1, entry2)
                            if entry1.source.name == "copilot" and entry2.source.name ~= "copilot" then
                                return true
                            elseif entry1.source.name ~= "copilot" and entry2.source.name == "copilot" then
                                return false
                            end
                        end,
                        -- Score order (LSP, snippets, buffer, etc.)
                        cmp.config.compare.score,
                        cmp.config.compare.locality,
                        cmp.config.compare.recently_used,
                        cmp.config.compare.kind,
                        cmp.config.compare.sort_text,
                        cmp.config.compare.length,
                        cmp.config.compare.order,
                    },
                },

                -- Appearance settings (optional)
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },

                -- Experimental options (use with caution)
                -- Performance optimization settings
                performance = {
                    -- Make sure to use caching to improve performance
                    fetching_timeout = 500, -- Timeout for fetching completions (ms)
                    max_view_entries = 30, -- Limit number of entries in completion view
                    debounce = 60, -- Debounce time in milliseconds
                },

                experimental = {
                    ghost_text = true, -- Show ghost text for Copilot completions
                },
            })
            
            -- Markdown-specific configuration with more sources
            cmp.setup.filetype("markdown", {
                sources = cmp.config.sources({
                    { name = "copilot", max_item_count = 2 },
                    { name = "luasnip" },
                    { name = "buffer", keyword_length = 2 },
                    { name = "path" },
                    { name = "emoji" }, -- Add emoji support for markdown
                })
            })

            -- Gitcommit filetype configuration
            cmp.setup.filetype("gitcommit", {
                sources = cmp.config.sources({
                    { name = "copilot", max_item_count = 2 },
                    { name = "luasnip" },
                    { name = "buffer", keyword_length = 2 },
                    { name = "path" },
                })
            })

            -- Command mode completion
            cmp.setup.cmdline({ '/', '?' }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'buffer' }
                }
            })

            -- NPM package completion doesn't require explicit setup

            -- Git completion doesn't require explicit setup

            -- Ripgrep setup
            cmp.setup({
                sources = {
                    { name = "rg" }
                }
            })

            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = 'path' },
                    { name = 'cmdline' }
                })
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
        config = function()
            local ls = require("luasnip")
            local types = require("luasnip.util.types")
            
            -- Setup custom snippets and options
            ls.setup({
                history = true,
                -- Update more frequently, more smooth experience
                update_events = "TextChanged,TextChangedI",
                delete_check_events = "TextChanged,InsertLeave",
                -- Enable regular expression snippets
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
                -- Store snippets in cache directory to avoid losing them
                store_selection_keys = "<Tab>",
            })

            -- Load snippets from various sources
            require("luasnip.loaders.from_vscode").lazy_load()
            require("luasnip.loaders.from_snipmate").lazy_load()
            require("luasnip.loaders.from_lua").lazy_load()

            -- Load custom user snippets from the dedicated directory
            require("luasnip.loaders.from_lua").load({ paths = { vim.fn.stdpath("config") .. "/LuaSnip" } })
        end,
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

    -- Git completion source
    {
        "petertriho/cmp-git",
        dependencies = { "nvim-lua/plenary.nvim" },
        event = "InsertEnter",
    },

    -- NPM completion source
    {
        "david-kunz/cmp-npm",
        event = "InsertEnter",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- Ripgrep completion source
    {
        "lukas-reineke/cmp-rg",
        event = "InsertEnter",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- Emoji completion source
    {
        "hrsh7th/cmp-emoji",
        event = "InsertEnter",
    },
}
