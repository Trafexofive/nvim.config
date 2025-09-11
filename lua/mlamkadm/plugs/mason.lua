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
        },
        ensure_installed = {
          -- Formatters
          "prettierd",
          "stylua",
          "black",
          "isort",
          "shfmt",
          "clang_format",
          -- Linters
          "eslint_d",
          "shellcheck",
        }
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" }, -- Ensure mason is loaded first
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

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

      require("mason-lspconfig").setup({
        -- Ensure these LSP servers are installed
        ensure_installed = {
          "lua_ls", "clangd", "typos_lsp", "rust_analyzer", "jsonls", "html", "cssls", "dockerls", "bashls", "vimls", "pyright", "gopls", "diagnosticls", "marksman"
        },
        handlers = {
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
        }
      })
    end,
  },
  {
    -- Core LSP configuration
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-lspconfig.nvim",
    },
    config = function()
      -- All setup is now handled by mason-lspconfig, so this can be empty
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
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
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
    config = function(_, opts)
        require("conform").setup(opts)
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        sh = { "shellcheck" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
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
