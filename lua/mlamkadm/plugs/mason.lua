return {
  {
    -- NOTE: Ensure mason and mason-lspconfig are set up before lspconfig
    "williamboman/mason.nvim",
    build = ":MasonUpdate", -- Automatically update Mason registry
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" }, -- Ensure mason is loaded first
    config = function()
      require("mason-lspconfig").setup({
        -- Ensure these LSP servers are installed
        ensure_installed = {
          "lua_ls", "clangd", "typos_lsp", "rust_analyzer", "jsonls", "html", "cssls", "dockerls", "bashls", "vimls", "pyright", "gopls", "diagnosticls", "marksman"
        },
        -- Automatically set up lspconfig for installed servers
        automatic_installation = true,
      })
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim", -- Bridge between mason and null-ls
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "jose-elias-alvarez/null-ls.nvim",
    },
    config = function()
      require("mason-null-ls").setup({
        ensure_installed = {
          -- Formatters
          "prettierd",     -- JavaScript, TypeScript, CSS, HTML, JSON, YAML, Markdown
          "stylua",        -- Lua
          "black",         -- Python
          "isort",         -- Python imports
          "shfmt",         -- Shell scripts
          "clang_format",  -- C/C++
          -- Linters
          "eslint_d",      -- JavaScript, TypeScript
          "shellcheck",    -- Shell scripts
        },
        automatic_installation = true,
      })
    end,
  },
  {
    -- Core LSP configuration
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-lspconfig.nvim",
      "jose-elias-alvarez/null-ls.nvim",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local mason_lspconfig = require('mason-lspconfig')

      local function on_attach(client, bufnr)
        vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
        local opts = { buffer = bufnr, noremap = true, silent = true }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>ds', vim.lsp.buf.document_symbol, opts)
        vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, opts)
        vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>e', function() vim.diagnostic.open_float({ bufnr = bufnr }) end, opts)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
        vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, opts)
      end

      mason_lspconfig.setup_handlers({
        function(server_name)
          lspconfig[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
        ["lua_ls"] = function()
          lspconfig.lua_ls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              Lua = {
                runtime = { version = "LuaJIT" },
                diagnostics = { globals = { "vim" } },
                workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                telemetry = { enable = false },
              },
            },
          })
        end,
        ["clangd"] = function()
          lspconfig.clangd.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            cmd = { "clangd", "--background-index", "--cross-file-rename" },
          })
        end,
      })
    end,
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local null_ls = require("null-ls")
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
      
      null_ls.setup({
        sources = {
          -- Formatters
          null_ls.builtins.formatting.prettierd,
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.isort,
          null_ls.builtins.formatting.shfmt,
          null_ls.builtins.formatting.clang_format,
          
          -- Linters
          null_ls.builtins.diagnostics.eslint_d,
          null_ls.builtins.diagnostics.shellcheck,
        },
        -- Enable formatting on save
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
              end,
            })
          end
        end,
      })
    end,
  },
  {
    "ray-x/go.nvim", -- Go tools
    ft = "go", -- Load only for Go files
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig", -- Ensure LSP is available
    },
    config = function()
      require("go").setup()
      -- Keymaps are often set up within go.nvim itself or can be added here
      -- Example (ensure gopls is set up via lspconfig first for these to work fully):
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>gt", "<cmd>GoTest<CR>", opts)
      vim.keymap.set("n", "<leader>gb", "<cmd>GoBuild<CR>", opts)
      vim.keymap.set("n", "<leader>gr", "<cmd>GoRun<CR>", opts)
    end,
  },
}