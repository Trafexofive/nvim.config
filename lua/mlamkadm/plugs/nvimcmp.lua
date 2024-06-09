return {
    "hrsh7th/cmp-nvim-lsp",
    {
        'L3MON4D3/LuaSnip',
        dependencies = {
            -- 'hrsh7th/nvim-cmp',
            -- 'tzachar/fuzzy.nvim',
            'saadparwaiz1/cmp_luasnip',
            "rafamadriz/friendly-snippets",
            'tamago324/cmp-zsh',
            'Shougo/deol.nvim',
        },
    },
    -- 'tzachar/cmp-fuzzy-path',
    -- dependencies = { 'hrsh7th/nvim-cmp', 'tzachar/fuzzy.nvim' },
    {
        "hrsh7th/nvim-cmp",
        config = function()
            local cmp = require("cmp")
            require("luasnip.loaders.from_vscode").lazy_load()
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                    end,
                },

                mapping = {
                    ['<tab>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
                    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
                    ['<C-a>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
                    ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
                    ['<C-e>'] = cmp.mapping({
                        i = cmp.mapping.abort(),
                        c = cmp.mapping.close(),
                    }),
                    ['<C-CR>'] = cmp.mapping.confirm({ select = true }),
                },
                sources = cmp.config.sources({
                    { name = 'luasnip' }, -- For luasnip users.
                }, {
                    { name = 'nvim_lsp' },
                }, {
                    { name = 'buffer' },
                    -- }, {
                    --     { name = 'fuzzy_path', option = { fd_timeout_msec = 1500 } },
                })
            })
        end,
    }
}
