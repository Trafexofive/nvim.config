return {
    "rmagatti/auto-session",
    dependencies = { "nvim-telescope/telescope.nvim" },
    lazy = false,
    config = function()
        require("auto-session").setup({
            log_level = "error",
            auto_save_enabled = true,
            auto_restore_enabled = false, -- Manual restore only
            auto_session_suppress_dirs = { "~/", "/", "~/Downloads", "~/repos", "~/services", "~/Desktop", "~/tmp", "~/temp" },
            auto_session_use_git_branch = false,
            session_lens = {
                load_on_setup = true,
                theme_conf = { border = true },
                previewer = false,
            },
            -- Preserve buffer state across sessions
            preserve_state = true,
            -- Don't close buffers when restoring sessions
            silence_on_save = true,
        })

        -- Load telescope extension
        pcall(require('telescope').load_extension, 'session-lens')

        -- Keymaps for session management - these will be overridden by the enhanced session module
        vim.keymap.set("n", "<leader>ss", "<cmd>Telescope session-lens<CR>", { desc = "Search sessions" })
        vim.keymap.set("n", "<leader>sr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
        vim.keymap.set("n", "<leader>sS", "<cmd>SessionSave<CR>", { desc = "Save session" })
        vim.keymap.set("n", "<leader>sd", "<cmd>AutoSession deletePicker<CR>", { desc = "Delete session" })
    end,
}
