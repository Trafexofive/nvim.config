return {
    'rmagatti/auto-session',
    dependencies = {
        "junegunn/fzf",
        build = "./install --bin",
        'tzachar/fuzzy.nvim',
    },
    config = function()
        require("auto-session").setup {
            log_level = "error",
            auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        }
    end
}
