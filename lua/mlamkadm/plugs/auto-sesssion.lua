return {
    'rmagatti/auto-session',
    dependencies = {
        'tzachar/fuzzy.nvim',
        require = {
            'nvim-telescope/telescope-fzf-native.nvim',
        }
    },
    config = function()
        require("auto-session").setup {
            auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
            auto_save_enabled = true,
            auto_session_use_git_branch = true,
        }
    end
}
