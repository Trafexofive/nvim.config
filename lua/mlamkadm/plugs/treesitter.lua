return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
            ensure_installed = { "c", "cpp", "markdown", "lua", "vim", "vimdoc", "query", "javascript", "html" },
            sync_install = true,
            highlight = { enable = true },
            indent = { enable = false},
        })
    end
}
