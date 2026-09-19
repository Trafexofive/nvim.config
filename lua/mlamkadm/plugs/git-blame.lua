-- blame.nvim — fugitive-style git blame visualizer (window + virtual views)
-- Complements gitsigns (inline signs + current_line_blame).
-- This adds a full per-file blame WINDOW toggle + commit navigation.
return {
    "FabijanZulj/blame.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>gB", "<cmd>BlameToggle<CR>", desc = "Toggle blame window" },
        { "<leader>gbl", "<cmd>BlameToggle virtual<CR>", desc = "Toggle blame (virtual)" },
    },
    config = function()
        require("blame").setup({
            date_format = "%Y-%m-%d %H:%M",
            focus_blame = true,
            merge_consecutive = false,
            max_summary_width = 30,
        })
    end,
}
