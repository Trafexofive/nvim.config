return {
    'rmagatti/auto-session',
    lazy = false,

    opts = {
        -- Enable auto-restore of the last session if no session exists for the current directory
        auto_restore_last_session = true,
        
        -- Enable handling of cwd changes
        cwd_change_handling = {
            enable = true,
            -- Stop LSP servers when changing directories to prevent conflicts
            -- This will restart them in the new directory
            stop_lsp_servers = true,
        },

        -- Basic settings
        enabled = true,
        root_dir = vim.fn.stdpath("data") .. "/sessions/",
        auto_save = true,
        auto_restore = true,
        auto_create = true,
        
        -- Simplified suppressed directories
        suppressed_dirs = { '~/', '~/Downloads', '/' },
        
        -- Other settings
        lazy_support = true,
        close_unsupported_windows = true,
        continue_restore_on_error = true,
        show_auto_restore_notif = false,
        lsp_stop_on_restore = false,
        log_level = "error",

        -- Session lens settings (for Telescope integration)
        session_lens = {
            load_on_setup = true,
            previewer = false,
            mappings = {
                delete_session = { "i", "<C-D>" },
                alternate_session = { "i", "<C-S>" },
                copy_session = { "i", "<C-Y>" },
            },
            session_control = {
                control_dir = vim.fn.stdpath("data") .. "/auto_session/",
                control_filename = "session_control.json",
            },
        },
    }
}
