-- aerial.nvim — richer outline (replaces symbols-outline)
return {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle" },
    keys = {
        { "<leader>a", "<cmd>AerialToggle<CR>", desc = "Toggle Aerial outline" },
    },
    opts = {
        backends = { "lsp", "treesitter", "markdown", "man" },
        layout = { default_direction = "right" },
        update_events = "TextChanged,TextChangedI",
    },
}
