return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
        -- Define the formatters for each file type
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort", "black" },
            javascript = { "prettierd" },
            typescript = { "prettierd" },
            css = { "prettierd" },
            html = { "prettierd" },
            json = { "prettierd" },
            yaml = { "prettierd" },
            markdown = { "prettierd" },
            sh = { "shfmt" },
            c = { "clang_format" },
            cpp = { "clang_format" },
            java = { "google-java-format" },
            rust = { "rustfmt" },
            go = { "goimports", "gofumpt" },
        },
        -- Configure format on save with fallback
        format_on_save = function(bufnr)
            -- Disable format on save for .sat files
            if vim.bo[bufnr].filetype == "sat" or vim.api.nvim_buf_get_name(bufnr):match("%.sat$") then
                return
            end
            return {
                timeout_ms = 1000, -- Increased timeout for better reliability
                lsp_fallback = true,
            }
        end,
        -- Configure formatters with more options
        formatters = {
            shfmt = {
                prepend_args = { "-i", "4", "-ci" },
            },
            clang_format = {
                prepend_args = {
                    "-style={IndentWidth: 4, TabWidth: 4, UseTab: Never, AccessModifierOffset: -4, AllowShortIfStatementsOnASingleLine: false, AllowShortFunctionsOnASingleLine: false}",
                },
            },
            prettierd = {
                prepend_args = { "--tab-width", "4", "--no-use-tabs" },
            },
            stylua = {
                prepend_args = { "--indent-type", "Spaces", "--indent-width", "4" },
            },
            ["google-java-format"] = {
                prepend_args = { "--aosp" },
            },
        },
    },
    init = function()
        -- Create a keymap to format manually
        vim.api.nvim_create_user_command("Format", function(args)
            local range = nil
            if args.count ~= -1 then
                local start_line = vim.fn.line("v")
                local end_line = vim.fn.line(".")
                range = { start = start_line, ["end"] = end_line }
            end
            require("conform").format({ async = true, lsp_fallback = true, range = range })
        end, { desc = "Format current buffer" })
    end,
    config = function(_, opts)
        require("conform").setup(opts)
    end,
}
