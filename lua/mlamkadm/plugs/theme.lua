return {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
        -- Set contrast. Available values are "hard", "medium", "soft"
        vim.g.gruvbox_contrast_dark = "medium"
        vim.cmd.colorscheme "gruvbox"
    end,
}
