return {
    "williamboman/mason.nvim",
    "VonHeikemen/lsp-zero.nvim",
    "neovim/nvim-lspconfig",
    "williamboman/mason-lspconfig",
    branch = 'v2.x',
    requires = {
        -- LSP Support
        { "neovim/nvim-lspconfig" }, -- Required
        {
            -- Optional
            "williamboman/mason.nvim",
            run = function()
                pcall(vim.cmd, "MasonUpdate")
            end,
        },
        --{ "williamboman/mason-lspconfig.nvim" }, -- Optional

        -- Autocompletion
        { "hrsh7th/nvim-cmp" }, -- Required
        { "hrsh7th/cmp-nvim-lsp" }, -- Required
        { "hrsh7th/cmp-buffer" }, -- Optional
        { "hrsh7th/cmp-path" }, -- Optional
        { "saadparwaiz1/cmp_luasnip" }, -- Optional
        { "hrsh7th/cmp-nvim-lua" }, -- Optional

        -- Snippets
        { "L3MON4D3/LuaSnip" },    -- Required
        { "rafamadriz/friendly-snippets" }, -- Optional
    }
}
