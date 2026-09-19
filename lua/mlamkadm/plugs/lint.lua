return {
    {
        "mfussenegger/nvim-lint",
        event = { "BufWritePost", "BufReadPost", "InsertLeave" },
        config = function()
            local lint = require("lint")

            -- Set linters by filetype
            lint.linters_by_ft = {
                lua = { "selene" },
                python = { "pylint" },
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                sh = { "shellcheck" },
                dockerfile = { "hadolint" },
                markdown = { "markdownlint" },
                yaml = { "yamllint" },
                json = { "jsonlint" },
                go = { "golangci-lint" },
                make = { "checkmake" },
                -- Java doesn't have a simple standalone linter via nvim-lint usually, relies on jdtls
            }

            -- Autocmd to trigger linting
            vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
                callback = function()
                    local ft = vim.bo.filetype
                    local linters = lint.linters_by_ft[ft]

                    if linters then
                        -- Check executable existence to avoid errors
                        local available = {}
                        for _, name in ipairs(linters) do
                            if vim.fn.executable(name) == 1 then
                                table.insert(available, name)
                            end
                        end

                        if #available > 0 then
                            lint.try_lint(available)
                        end
                    end
                end,
            })
        end,
    },
}
