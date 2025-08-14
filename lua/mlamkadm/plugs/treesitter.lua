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
            refactor = {
                highlight_definitions = { enable = true },
                highlight_current_scope = { enable = false }, -- Disable to reduce visual clutter
                smart_rename = {
                    enable = true,
                    keymaps = {
                        smart_rename = "grr", -- Trigger rename with 'grr'
                    },
                },
                navigation = {
                    enable = true,
                    keymaps = {
                        goto_definition = "gnd",
                        list_definitions = "gnD",
                        list_definitions_toc = "gO",
                        goto_next_usage = "<a-*>";
                        goto_previous_usage = "<a-#>";
                    },
                },
            },
        })
    end,
    dependencies = {
        "nvim-treesitter/nvim-treesitter-refactor",
        "nvim-lua/plenary.nvim", -- Required for rename across files
    },
}
