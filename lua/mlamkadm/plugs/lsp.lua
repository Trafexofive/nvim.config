return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "folke/neodev.nvim",
            "b0o/schemastore.nvim", -- Add schemastore dependency
        },
        config = function()
            local lspconfig = require("lspconfig")
            local mason_lspconfig = require("mason-lspconfig")
            local cmp_nvim_lsp = require("cmp_nvim_lsp")

            -- Setup Neodev for Lua development
            require("neodev").setup()

            -- Default capabilities with nvim-cmp
            local capabilities = cmp_nvim_lsp.default_capabilities()

            -- Enable folding capabilities for nvim-ufo if used later
            capabilities.textDocument.foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true
            }

            -- GLOBAL LSP KEYMAPS (LspAttach)
            -- This ensures keymaps work for ANY active LSP, regardless of how it was setup
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('UserLspConfig', {}),
                callback = function(ev)
                    -- Enable completion triggered by <c-x><c-o>
                    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

                    -- Navigation
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition", buffer = ev.buf })
                    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration", buffer = ev.buf })
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to References", buffer = ev.buf })
                    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation", buffer = ev.buf })

                    -- Information
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation", buffer = ev.buf })
                    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "Signature Help", buffer = ev.buf })

                    -- Actions
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename Symbol", buffer = ev.buf })
                    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action", buffer = ev.buf })

                    -- Diagnostics
                    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Diagnostics", buffer = ev.buf })
                    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic", buffer = ev.buf })
                    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic", buffer = ev.buf })
                end,
            })

            -- Setup Mason LSPconfig
            mason_lspconfig.setup({
                ensure_installed = {
                    "lua_ls",
                    "pyright",
                    "ts_ls",
                    "html",
                    "cssls",
                    "jsonls",
                    "yamlls",
                    "bashls",
                    "dockerls",
                    "gopls",
                    "rust_analyzer",
                    "clangd",
                    -- "marksman", -- DISABLED: triggers treesitter node:range() crash via diagnostics redraw on Neovim 0.12
                    -- "jdtls", -- Removed from here, handled by nvim-jdtls in ftplugin/java.lua
                },
                automatic_installation = true,
                handlers = {
                    -- Default handler
                    function(server_name)
                        lspconfig[server_name].setup({
                            capabilities = capabilities,
                        })
                    end,

                    -- Marksman disabled — triggers treesitter node:range() crash on Neovim 0.12
                    -- The diagnostic redraw chain (LSP→diagnostics→redraw→treesitter→crash) is unfixable
                    -- without Neovim-side parser query fixes. Re-enable when parsers are updated.
                    ["marksman"] = function() end,

                    -- Specialized handlers
                    ["lua_ls"] = function()
                        lspconfig.lua_ls.setup({
                            capabilities = capabilities,
                            settings = {
                                Lua = {
                                    completion = { callSnippet = "Replace" },
                                    diagnostics = { globals = { "vim" } },
                                    workspace = { checkThirdParty = false },
                                    telemetry = { enable = false },
                                },
                            },
                        })
                    end,

                    ["jsonls"] = function()
                        lspconfig.jsonls.setup({
                            capabilities = capabilities,
                            settings = {
                                json = {
                                    schemas = require('schemastore').json.schemas(),
                                    validate = { enable = true },
                                },
                            },
                        })
                    end,

                    ["yamlls"] = function()
                        lspconfig.yamlls.setup({
                            capabilities = capabilities,
                            settings = {
                                yaml = {
                                    schemaStore = {
                                        enable = false,
                                        url = "",
                                    },
                                    schemas = require('schemastore').yaml.schemas(),
                                },
                            },
                        })
                    end,

                    ["gopls"] = function()
                        lspconfig.gopls.setup({
                            capabilities = capabilities,
                            settings = {
                                gopls = {
                                    analyses = {
                                        unusedparams = true,
                                    },
                                    staticcheck = true,
                                    gofumpt = true,
                                },
                            },
                        })
                    end,

                    ["rust_analyzer"] = function()
                        lspconfig.rust_analyzer.setup({
                            capabilities = capabilities,
                            settings = {
                                ["rust-analyzer"] = {
                                    checkOnSave = {
                                        command = "clippy",
                                    },
                                },
                            },
                        })
                    end,

                    ["clangd"] = function()
                        local util = require("lspconfig.util")

                        lspconfig.clangd.setup({
                            capabilities = capabilities,
                            cmd = {
                                "clangd",
                                "--background-index",
                                "--clang-tidy",
                                "--header-insertion=iwyu",
                                "--completion-style=detailed",
                                "--function-arg-placeholders",
                                "--fallback-style=llvm",
                            },
                            root_dir = function(fname)
                                return util.root_pattern(
                                    "compile_commands.json",
                                    "compile_flags.txt",
                                    ".clangd",
                                    ".clang-tidy",
                                    "CMakeLists.txt",
                                    "Makefile",
                                    "configure.ac",
                                    "configure",
                                    ".git"
                                )(fname) or util.path.dirname(fname)
                            end,
                            single_file_support = true,
                            on_new_config = function(new_config, new_root_dir)
                                local has_db = util.path.exists(util.path.join(new_root_dir, "compile_commands.json"))
                                local build_db = util.path.exists(util.path.join(new_root_dir, "build", "compile_commands.json"))
                                local cmd = vim.deepcopy(new_config.cmd or { "clangd" })

                                cmd = vim.tbl_filter(function(arg)
                                    return not vim.startswith(arg, "--compile-commands-dir=")
                                end, cmd)

                                if not has_db and build_db then
                                    table.insert(cmd, "--compile-commands-dir=build")
                                end

                                new_config.cmd = cmd
                            end,
                        })
                    end,

                    ["jdtls"] = function()
                        -- DEBUG: Notify that JDTLS handler is running
                        vim.notify("Setting up JDTLS with wrapper...", vim.log.levels.INFO)

                        -- Explicitly configuring root directory pattern for better project detection
                        local root_pattern = require("lspconfig.util").root_pattern

                        -- Use our custom wrapper script that enforces Java 21 environment
                        local wrapper_script = vim.fn.stdpath("config") .. "/jdtls_wrapper.sh"

                        lspconfig.jdtls.setup({
                            capabilities = capabilities,
                            cmd = { wrapper_script },
                            root_dir = root_pattern("gradlew", "mvnw", ".git", "pom.xml", "build.gradle"),
                            settings = {
                                java = {
                                    signatureHelp = { enabled = true },
                                    contentProvider = { preferred = 'fernflower' },
                                    configuration = {
                                        runtimes = {
                                            {
                                                name = "JavaSE-17",
                                                path = "/usr/lib/jvm/java-17-openjdk",
                                                default = true,
                                            },
                                            {
                                                name = "JavaSE-21",
                                                path = "/usr/lib/jvm/java-21-openjdk",
                                            },
                                        }
                                    },
                                    sources = {
                                        organizeImports = {
                                            starThreshold = 9999,
                                            staticStarThreshold = 9999,
                                        },
                                    },
                                },
                            },
                        })
                    end,
                }
            })

            -- Smelt LSP (optional): activates when `smelt-lsp` is available.
            if vim.fn.executable("smelt-lsp") == 1 then
                local util = require("lspconfig.util")
                local lspconfig_configs = require("lspconfig.configs")
                if not lspconfig_configs.smeltls then
                    lspconfig_configs.smeltls = {
                        default_config = {
                            cmd = { "smelt-lsp" },
                            filetypes = { "smelt" },
                            root_dir = util.root_pattern(".smelt.yml", "smelt.yml", ".git"),
                            single_file_support = true,
                        },
                    }
                end
                lspconfig.smeltls.setup({
                    cmd = { "smelt-lsp" },
                    filetypes = { "smelt" },
                    root_dir = util.root_pattern(".smelt.yml", "smelt.yml", ".git"),
                    capabilities = capabilities,
                })
            end

            -- Diagnostic configuration
            vim.diagnostic.config({
                virtual_text = {
                    prefix = '●', -- Could be '■', '▎', 'x'
                },
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = " ",
                        [vim.diagnostic.severity.WARN] = " ",
                        [vim.diagnostic.severity.HINT] = " ",
                        [vim.diagnostic.severity.INFO] = " ",
                    },
                },
                underline = true,
                update_in_insert = false,
                severity_sort = true,
                float = {
                    border = 'rounded',
                    source = 'always',
                },
            })
        end,
    },

    -- SchemaStore for JSON/YAML
    {
        "b0o/schemastore.nvim",
        lazy = true,
    },
}
