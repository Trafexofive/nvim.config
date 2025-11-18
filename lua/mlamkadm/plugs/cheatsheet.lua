return {
    "sudormrfbin/cheatsheet.nvim",
    dependencies = {
        "nvim-lua/popup.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("cheatsheet").setup({
            bundled_cheatsheets = {
                enabled = { 'default', 'lua', 'git' },
                disabled = {},
            },
            bundled_plugin_cheatsheets = {
                enabled = { 'telescope', 'nvim-tree', 'dap' },
                disabled = {},
            },
            -- Custom cheatsheet files
            include_only_installed_plugins = true,
        })
    end,
    cmd = { "Cheatsheet", "CheatsheetEdit" },
    keys = {
        { "<leader>?", "<cmd>Cheatsheet<cr>", desc = "Open cheatsheet" },
        { "<leader>cs", "<cmd>Cheatsheet<cr>", desc = "Open cheatsheet" },
    }
}