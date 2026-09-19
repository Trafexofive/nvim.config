-- lazygit.nvim — proper floating lazygit (vs raw terminal toggle)
return {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit (floating)" },
    },
    config = function()
        require("lazygit").setup({})
    end,
}
