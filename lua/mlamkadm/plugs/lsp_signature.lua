return {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = {
        debug = false,
        hint_enable = true,
        floating_window = true,
        floating_window_above_cur_line = true,
        hint_prefix = "🐼 ",
        max_height = 15,
        max_width = 80,
        handler_opts = {
            border = "rounded"
        },
        hi_parameter = "LspSignatureActiveParameter",
    },
    config = function(_, opts)
        require('lsp_signature').setup(opts)
    end,
}