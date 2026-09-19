-- render-markdown.nvim — inline markdown rendering (complements mkdnflow nav + glow preview)
return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "md" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
        file_types = { "markdown", "md" },
        render_modes = { "n", "i" },
    },
}
