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
            "tamago324/cmp-zsh",         -- Zsh Source
            "hrsh7th/cmp-emoji",         -- Emoji Source
            "lukas-reineke/cmp-rg",      -- Ripgrep Source
            "petertriho/cmp-git",        -- Git Source
            "david-kunz/cmp-npm",        -- NPM Source
            "hrsh7th/cmp-calc",          -- Inline math (2+2 → 4)
            "rcarriga/cmp-dap",          -- DAP variable completion
            "uga-rosa/cmp-dictionary",   -- English word completion (prose)

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

            -- menuone+noselect: always show the menu, don't pre-select, so Tab
            -- explicitly accepts (IDE-like) instead of cycling silently.
            vim.opt.completeopt = "menu,menuone,noselect"

            -- Helper function for Tab/S-Tab navigation with Luasnip
            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            -- Dictionary source: only available where a real wordlist exists.
            -- (pacman -S words → /usr/share/dict/words)
            local dict_words = "/usr/share/dict/words"
            local has_dict = vim.fn.filereadable(dict_words) == 1

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },

                -- Sources Configuration
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 90 },
                    { name = "luasnip",  priority = 80 },
                    { name = "path",     priority = 70 },
                }, {
                    { name = "nvim_lua",    keyword_length = 2 },
                    { name = "buffer",      keyword_length = 3 },
                    { name = "calc" },
                    { name = "emoji" },
                    { name = "npm" },
                    { name = "zsh" },
                    { name = "rg",          keyword_length = 3 },
                }),

                -- Key Mappings
                mapping = cmp.mapping.preset.insert({
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.abort(),
                    -- j/k-style navigation via C-n/C-p (preset.insert already
                    -- has these; explicit here so it's visible).
                    ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                    ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
                    ['<Down>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
                    ['<Up>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
                    -- IDE-like: Tab accepts the highlighted item (or first).
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.confirm({ select = true })
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

                -- Performance & ordering
                performance = {
                    debounce = 60,
                    fetching_timeout = 200,
                    max_view_entries = 200,
                },
                sorting = {
                    priority_weight = 2.0,
                    comparators = {
                        cmp.config.compare.offset,
                        cmp.config.compare.exact,
                        cmp.config.compare.score,
                        cmp.config.compare.recently_used,
                        cmp.config.compare.locality,
                        cmp.config.compare.kind,
                        cmp.config.compare.sort_text,
                        cmp.config.compare.length,
                        cmp.config.compare.order,
                    },
                },
                matching = {
                    disallow_fuzzy_matching = false,
                    disallow_full_fuzzy_matching = false,
                    disallow_partial_fuzzy_matching = false,
                    disallow_partial_matching = false,
                    disallow_prefix_unmatching = false,
                },

                -- Formatting
                formatting = {
                    format = lspkind.cmp_format({
                        mode = "symbol_text",
                        maxwidth = 50,
                        ellipsis_char = "...",
                        symbol_map = {
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
                    { name = "dictionary", keyword_length = 3 },
                    { name = "buffer" },
                })
            })

            -- Prose filetypes: English dictionary + inline math word completion
            -- for writing/commits/docs. Dictionary is only wired when a wordlist
            -- is present (pacman -S words → /usr/share/dict/words).
            local prose_sources = {
                { name = "luasnip" },
                { name = "path" },
                { name = "calc" },
            }
            if has_dict then
                table.insert(prose_sources, { name = "dictionary", keyword_length = 2 })
            end
            cmp.setup.filetype({ "markdown", "help", "text", "txt", "gitcommit" }, {
                sources = cmp.config.sources(prose_sources, {
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

    -- Dictionary Completion Source
    {
        "uga-rosa/cmp-dictionary",
        event = { "InsertEnter" },
        config = function()
            local words = "/usr/share/dict/words"
            if vim.fn.filereadable(words) ~= 1 then
                return
            end
            require("cmp_dictionary").setup({
                paths = { words },
                exact_length = 2,
            })
        end,
    },
}
