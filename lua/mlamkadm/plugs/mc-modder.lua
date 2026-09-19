-- lua/mlamkadm/plugs/mc-modder.lua
-- Minecraft modding IDE plugin for Neovim
return {
    dir = vim.fn.stdpath("config") .. "/lua/mc-modder", -- Local plugin directory
    dependencies = {
        "neovim/nvim-lspconfig",
        "nvim-lua/plenary.nvim",
        -- 'mfussenegger/nvim-jdtls',  -- Removed, handled by mason/lsp.lua
    },
    config = function()
        require("mc-modder").setup({
            lsp_enabled = false, -- Disable built-in LSP setup to avoid conflicts
            java = {
                java_home = os.getenv("JAVA_HOME") or "",
                -- jdtls_path = ... -- No longer needed here
            },
            kotlin = {
                ktls_path = vim.fn.expand("~/tools/kotlin-language-server"), -- Path to your KLS installation
            },
            minecraft = {
                default_version = "1.20.1",
                default_mod_type = "fabric",
            },
            mappings = {
                gradle = {
                    build = "<leader>mgb", -- Build project
                    run_client = "<leader>mrc", -- Run Minecraft client
                    run_server = "<leader>mrs", -- Run Minecraft server
                    clean = "<leader>mgc", -- Clean project
                    gen_sources = "<leader>mgs", -- Generate sources
                },
                maven = {
                    compile = "<leader>mmc", -- Compile project
                    install = "<leader>mmi", -- Install project
                    test = "<leader>mnt", -- Run tests
                },
                lsp = {
                    reload = "<leader>mlr", -- Reload LSP
                    organize_imports = "<leader>mo", -- Organize imports
                },
                scaffold = {
                    create_mod = "<leader>msc", -- Create new mod project
                },
            },
        })
    end,
    event = "VeryLazy",
}
