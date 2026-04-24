return {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup({
            -- v4 uses default keymaps automatically
            -- cs, ds, yss, etc.
        })
    end,
}
