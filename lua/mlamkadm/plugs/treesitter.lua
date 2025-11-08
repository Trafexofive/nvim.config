return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
            -- A more comprehensive list of ensured grammars
            ensure_installed = {
                "c", "cpp", "markdown", "markdown_inline", "lua", "vim", "vimdoc", "query",
                "javascript", "html", "css", "python", "go", "rust", "bash", "yaml", "json",
                "toml", "tsx", "typescript", "regex", "sql", "http", "dockerfile"
            },
            sync_install = false, -- Use async installation for better performance
            highlight = { enable = true },
            indent = { enable = true }, -- Enable indentation module
        })
    end,
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
}
