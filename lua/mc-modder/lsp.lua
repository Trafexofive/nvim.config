local M = {}

-- Standard LSP keymaps
local function on_attach(client, bufnr)
    local opts = { buffer = bufnr }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
end

-- Get capabilities for nvim-cmp
local function get_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok then
        return cmp_lsp.default_capabilities(capabilities)
    end
    return capabilities
end

-- Function to setup Java language server (jdtls)
function M.setup_java_lsp(opts)
    opts = opts or {}
    local ok, jdtls = pcall(require, "jdtls")
    if not ok then
        vim.notify("nvim-jdtls not found. Please install it for Java support.", vim.log.levels.WARN)
        return
    end

    -- Find the project root (where .git or build.gradle or pom.xml is located)
    local root_markers = { ".git", "build.gradle", "pom.xml", "settings.gradle" }

    -- Use lspconfig util if available
    local root_dir = require("lspconfig.util").root_pattern(unpack(root_markers))(vim.fn.getcwd())

    if not root_dir or root_dir == "" then
        -- Not necessarily an error, might just be opening a single file
        return
    end

    -- Default java home
    local java_home = opts.java_home or os.getenv("JAVA_HOME") or ""

    -- Determine the configuration directory based on OS
    local os_name = vim.loop.os_uname().sysname
    local config_dir
    if os_name == "Linux" then
        config_dir = "linux"
    elseif os_name == "Darwin" then
        config_dir = "mac"
    elseif os_name:match("Windows") then
        config_dir = "win"
    else
        config_dir = "linux" -- default fallback
    end

    -- Workspace directory for jdtls
    local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

    -- Default jdtls installation path
    local jdtls_path = opts.jdtls_path or vim.fn.expand("~/tools/jdtls")

    -- JDTLS configuration
    local jdtls_config = {
        cmd = {
            "java",
            "-Declipse.application=org.eclipse.jdt.ls.core.id1",
            "-Dosgi.bundles.defaultStartLevel=4",
            "-Declipse.product=org.eclipse.jdt.ls.core.product",
            "-Dlog.protocol=true",
            "-Dlog.level=ALL",
            "-Xms1g",
            "-Xmx2G",
            "-jar",
            vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
            "-configuration",
            jdtls_path .. "/config_" .. config_dir,
            "-data",
            workspace_dir,
        },
        root_dir = root_dir,
        on_attach = on_attach,
        capabilities = get_capabilities(),
        settings = {
            java = {
                -- Configure the Java language server
                configuration = {
                    runtimes = {
                        {
                            name = "JavaSE-17",
                            path = java_home,
                        },
                        {
                            name = "JavaSE-11",
                            path = java_home,
                        },
                        {
                            name = "JavaSE-8",
                            path = java_home,
                        },
                    },
                },
                eclipse = {
                    downloadSources = true,
                },
                maven = {
                    downloadSources = true,
                },
                implementationsCodeLens = {
                    enabled = true,
                },
                referencesCodeLens = {
                    enabled = true,
                },
                references = {
                    includeDecompiledSources = true,
                },
                inlayHints = {
                    parameterNames = {
                        enabled = "all", -- literals, all, none
                    },
                },
            },
            signatureHelp = { enabled = true },
            completion = {
                favoriteStaticMembers = {
                    "org.hamcrest.MatcherAssert.assertThat",
                    "org.hamcrest.Matchers.*",
                    "org.hamcrest.CoreMatchers.*",
                    "org.junit.jupiter.api.Assertions.*",
                    "java.util.Objects.requireNonNull",
                    "java.util.Objects.requireNonNullElse",
                    "org.mockito.Mockito.*",
                },
            },
            contentProvider = { preferred = "fernflower" },
            extendedFileStreamSupport = true,
        },
        init_options = {
            bundles = {},
        },
    }

    -- Apply any user overrides
    if opts.settings then
        jdtls_config.settings = vim.tbl_deep_extend("force", jdtls_config.settings, opts.settings)
    end

    -- Setup jdtls
    jdtls.start_or_attach(jdtls_config)

    -- Setup dap (Debug Adapter Protocol) for Java if available
    if pcall(require, "jdtls.dap") then
        require("jdtls").setup_dap({ hotcodereplace = "auto" })
    end

    -- Add some useful commands
    vim.api.nvim_create_user_command("JavaProjectReload", function()
        jdtls.project_reload()
    end, {})

    vim.api.nvim_create_user_command("JavaImportOrganize", function()
        jdtls.organize_imports()
    end, {})

    vim.api.nvim_create_user_command("JavaTestFinder", function()
        jdtls.test_finder()
    end, {})
end

-- Function to setup Kotlin language server
function M.setup_kotlin_lsp(opts)
    opts = opts or {}

    local ok, lspconfig = pcall(require, "lspconfig")
    if not ok then
        vim.notify("lspconfig not found. Please install it for Kotlin support.", vim.log.levels.WARN)
        return
    end

    -- Find the project root
    local root_markers =
        { ".git", "build.gradle", "pom.xml", "settings.gradle", "build.gradle.kts", "gradle.properties" }
    local root_dir = require("lspconfig.util").root_pattern(unpack(root_markers))(vim.fn.getcwd())

    if not root_dir or root_dir == "" then
        return
    end

    -- Check if kotlin language server is available
    local ktls_path = opts.ktls_path or vim.fn.expand("~/tools/kotlin-language-server")
    local server_script = ktls_path .. "/bin/kotlin-language-server"

    if vim.fn.executable(server_script) ~= 1 then
        -- Don't notify on every startup, only if we are actually in a kotlin project and it's missing
        return
    end

    -- Setup the Kotlin language server
    local util = require("lspconfig.util")

    lspconfig.kotlin_language_server.setup({
        cmd = { server_script },
        root_dir = util.root_pattern(unpack(root_markers)),
        on_attach = on_attach,
        capabilities = get_capabilities(),
        settings = {
            kotlin = {
                compiler = {
                    jvm = {
                        target = opts.jvm_target or "17",
                    },
                },
                languageServer = {
                    execution = {
                        javaHome = opts.java_home or os.getenv("JAVA_HOME") or "",
                    },
                },
            },
        },
    })
end

-- Function to automatically detect and setup the appropriate LSP based on project files
function M.setup_auto_lsp(opts)
    opts = opts or {}

    -- Check for Java/Kotlin project indicators
    local has_build_gradle = vim.fn.filereadable("build.gradle") == 1 or vim.fn.filereadable("build.gradle.kts") == 1
    local has_pom_xml = vim.fn.filereadable("pom.xml") == 1
    local has_java_files = not vim.tbl_isempty(vim.fn.glob("src/**/*.java", 1, 1))
    local has_kotlin_files = not vim.tbl_isempty(vim.fn.glob("src/**/*.{kt,kotlin}", 1, 1))

    -- Determine which LSP to setup based on project files
    -- Check if glob returned actual files
    local has_kotlin_content = false
    local kotlin_glob = vim.fn.glob("src/**/*.{kt,kotlin}", 1, 1)
    if type(kotlin_glob) == "table" then
        has_kotlin_content = not vim.tbl_isempty(kotlin_glob)
    else
        has_kotlin_content = kotlin_glob ~= ""
    end

    if has_kotlin_files or (has_build_gradle and has_kotlin_content) then
        -- This looks like a Kotlin project
        M.setup_kotlin_lsp(opts.kotlin or opts)
    elseif has_java_files or has_build_gradle or has_pom_xml then
        -- This looks like a Java project
        M.setup_java_lsp(opts.java or opts)
    end
end

-- Function to setup LSP for Minecraft-specific configurations
function M.setup_minecraft_lsp(opts)
    opts = opts or {}

    -- Setup the appropriate LSP
    M.setup_auto_lsp(opts)

    -- Add Minecraft-specific LSP configurations
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true

    -- Enhance with custom Minecraft-specific handlers
    vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
        underline = true,
        virtual_text = {
            spacing = 4,
            prefix = "●",
        },
        update_in_insert = false,
    })
end

return M
