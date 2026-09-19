-- todo-comments.nvim — highlight TODO/FIXME/NOTE (matches TODO.md workflow)
return {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        signs = true,
        highlight = { multiline = true },
    },
    keys = {
        {
            "]t",
            function()
                require("todo-comments").jump_next()
            end,
            desc = "Next todo comment",
        },
        {
            "[t",
            function()
                require("todo-comments").jump_prev()
            end,
            desc = "Previous todo comment",
        },
    },
}
