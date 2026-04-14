return {
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonInstallAll" }, -- Lazy load
        dependencies = {
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        config = function()
            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗"
                    }
                },
                -- Automatically install these tools
                ensure_installed = {
                    -- LSPs are handled by mason-lspconfig in lsp.lua
                    -- This list is for formatters, linters, debuggers
                    
                    -- Formatters
                    "prettierd",
                    "stylua",
                    "black",
                    "isort",
                    "shfmt",
                    "clang-format",
                    "gofumpt",
                    "goimports",
                    "yamlfmt",
                    
                    -- Linters
                    "eslint_d",
                    "shellcheck",
                    "markdownlint",
                    "yamllint",
                    "golangci-lint",
                    "hadolint",
                    "pylint",
                    "selene",
                    
                    -- Debuggers (DAP)
                    "delve", -- Go
                    "codelldb", -- C/C++/Rust
                    "debugpy", -- Python
                },
            })

            -- Tool Installer configuration
            require("mason-tool-installer").setup({
                ensure_installed = {
                    -- Formatters
                    "prettierd",
                    "stylua",
                    "black",
                    "isort",
                    "shfmt",
                    "clang-format",
                    "gofumpt",
                    "goimports",
                    "yamlfmt",
                    "google-java-format",
                    
                    -- Linters
                    "eslint_d",
                    "shellcheck",
                    "markdownlint",
                    "yamllint",
                    "golangci-lint",
                    "hadolint",
                    "pylint",
                    "selene",
                    "checkmake",
                    
                    -- Debuggers
                    "delve",
                    "codelldb",
                    "debugpy",
                },
                auto_update = true,
                run_on_start = true,
            })
            
            -- Add Mason bin to PATH
            vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
        end,
    },
}
