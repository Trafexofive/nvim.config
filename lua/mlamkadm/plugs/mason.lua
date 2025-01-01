return {
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v2.x",
        dependencies = {
            -- Core LSP plugins
            { "neovim/nvim-lspconfig" },
            {
                "williamboman/mason.nvim",
                build = ":MasonUpdate", -- Automatically update Mason registry
            },
            { "williamboman/mason-lspconfig.nvim" },

            -- Autocompletion plugins
            { "hrsh7th/nvim-cmp" },
            { "hrsh7th/cmp-nvim-lsp" },
            { "hrsh7th/cmp-buffer" },
            { "hrsh7th/cmp-path" },
            { "saadparwaiz1/cmp_luasnip" },
            { "hrsh7th/cmp-nvim-lua" },

            -- Snippet engine and snippets
            { "L3MON4D3/LuaSnip" },
            { "rafamadriz/friendly-snippets" },
        },
        config = function()
            local lsp = require("lsp-zero").preset({})

            -- Ensure these LSP servers are installed
            lsp.ensure_installed({
                "clangd",  -- C/C++
                "pyright", -- Python
                "gopls",   -- Go
                "lua_ls",  -- Lua
                "bashls",  -- Shell scripting
            })

            -- LSP-specific configurations
            require("lspconfig").clangd.setup({
                cmd = { "clangd", "--background-index", "--cross-file-rename" },
            })
            require("lspconfig").pyright.setup({})
            require("lspconfig").gopls.setup({})
            require("lspconfig").lua_ls.setup({
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                        telemetry = { enable = false },
                    },
                },
            })
            require("lspconfig").bashls.setup({})

            -- Attach key mappings
            lsp.on_attach(function(_, bufnr)
                local opts = { buffer = bufnr, noremap = true, silent = true }
                vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
                vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
                vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
                vim.keymap.set("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
                vim.keymap.set("n", "<leader>ds", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", opts)
                vim.keymap.set("n", "<leader>ws", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>", opts)
                vim.keymap.set("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
                vim.keymap.set("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
                vim.keymap.set("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
                vim.keymap.set("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
            end)

            lsp.setup()
        end,
    },
    {
        "ray-x/go.nvim", -- Go tools
        dependencies = { "ray-x/guihua.lua" },
        config = function()
            require("go").setup()
            local opts = { noremap = true, silent = true }
            vim.keymap.set("n", "<leader>gt", "<cmd>GoTest<CR>", opts)
            vim.keymap.set("n", "<leader>gb", "<cmd>GoBuild<CR>", opts)
            vim.keymap.set("n", "<leader>gr", "<cmd>GoRun<CR>", opts)
        end,
    },
    {
        "mfussenegger/nvim-lint", -- Linting
        config = function()
            require("lint").linters_by_ft = {
                cpp = { "clangtidy" },
                c = { "clangtidy" },
                python = { "pylint" },
                lua = { "luacheck" },
                go = { "golangci-lint" },
                sh = { "shellcheck" },
            }
            vim.api.nvim_create_autocmd({ "BufWritePost" }, {
                callback = function()
                    require("lint").try_lint()
                end,
            })
            local opts = { noremap = true, silent = true }
            vim.keymap.set("n", "<leader>p", "<cmd>lua require('lint').try_lint()<CR>", opts)
        end,
    },
    {
        "jose-elias-alvarez/null-ls.nvim", -- Formatting
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local null_ls = require("null-ls")
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.clang_format, -- C/C++
                    null_ls.builtins.formatting.black,        -- Python
                    null_ls.builtins.formatting.gofmt,        -- Go
                    null_ls.builtins.formatting.stylua,       -- Lua
                    null_ls.builtins.formatting.shfmt,        -- Shell scripting
                },
            })
            local opts = { noremap = true, silent = true }
            vim.keymap.set("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
        end,
    },
}
