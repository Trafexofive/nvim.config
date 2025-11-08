return {
    "rmagatti/auto-session",
    dependencies = { "nvim-telescope/telescope.nvim" },
    lazy = false,
    config = function()
        require("auto-session").setup({
            log_level = "error",
            auto_save_enabled = true,
            auto_restore_enabled = false, -- Manual restore only
            auto_session_suppress_dirs = { "~/", "/", "~/Downloads" },
            auto_session_use_git_branch = false,
            session_lens = {
                load_on_setup = true,
                theme_conf = { border = true },
                previewer = false,
            },
        })

        -- Load telescope extension
        pcall(require('telescope').load_extension, 'session-lens')

        -- Keymaps for session management
        vim.keymap.set("n", "<leader>ss", "<cmd>Telescope session-lens<CR>", { desc = "Search sessions" })
        vim.keymap.set("n", "<leader>sr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
        vim.keymap.set("n", "<leader>sS", "<cmd>SessionSave<CR>", { desc = "Save session" })
        vim.keymap.set("n", "<leader>sd", "<cmd>SessionDelete<CR>", { desc = "Delete session" })
    end,
}
