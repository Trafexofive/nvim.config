return {
    "rmagatti/auto-session",
    dependencies = { "nvim-telescope/telescope.nvim" },
    lazy = false,
    priority = 1001, -- Ensure it loads before dashboard (priority 1000) so auto-restore happens first
    config = function()
        require("auto-session").setup({
            log_level = "error",
            auto_save_enabled = true,
            auto_restore_enabled = true, -- Auto restore enabled
            auto_session_suppress_dirs = { "~/", "~/Downloads", "~/Desktop", "~/Documents", "~/Videos", "~/Music", "/", "/tmp", "/etc" },
            auto_session_use_git_branch = false,
            
            -- Better flow for directory changes
            cwd_change_handling = {
                restore_upcoming_session = true, -- Restore session for upcoming CWD
                pre_cwd_changed_hook = nil, -- Function to run before CWD changes
                post_cwd_changed_hook = function() -- Refresh UI components
                     vim.cmd("redrawstatus")
                end,
            },

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

        -- Keymaps for session management
        vim.keymap.set("n", "<leader>ss", function() require("mlamkadm.core.session_manager").sessions_with_readme() end, { desc = "Search sessions" })
        vim.keymap.set("n", "<leader>sr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
        vim.keymap.set("n", "<leader>sS", "<cmd>SessionSave<CR>", { desc = "Save session" })
        vim.keymap.set("n", "<leader>sd", "<cmd>AutoSession deletePicker<CR>", { desc = "Delete session" })
    end,
}
