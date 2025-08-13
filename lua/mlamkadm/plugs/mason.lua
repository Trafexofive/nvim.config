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
          "clangd",   -- C/C++
          "pyright",  -- Python
          "gopls",    -- Go
          "lua_ls",   -- Lua
          "bashls",   -- Shell scripting
          "marksman", -- Markdown
        },
        -- Automatically set up lspconfig for installed servers
        automatic_installation = true,
      })
    end,
  },
  {
    -- Core LSP configuration
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-lspconfig.nvim", -- Ensure mason-lspconfig is loaded first
      -- Autocompletion plugins (if not configured elsewhere)
      -- { "hrsh7th/nvim-cmp" },
      -- { "hrsh7th/cmp-nvim-lsp" },
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require('cmp_nvim_lsp').default_capabilities() -- Integrate with nvim-cmp if available

      -- LSP-specific configurations
      lspconfig.clangd.setup({
        capabilities = capabilities,
        cmd = { "clangd", "--background-index", "--cross-file-rename" },
      })
      lspconfig.pyright.setup({
        capabilities = capabilities,
      })
      lspconfig.gopls.setup({
        capabilities = capabilities,
      })
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
          },
        },
      })
      lspconfig.bashls.setup({
        capabilities = capabilities,
      })
      lspconfig.marksman.setup({
        capabilities = capabilities,
      })

      -- Attach key mappings for LSP functions
      -- This function will be called when an LSP server attaches to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          local opts = { buffer = ev.buf, noremap = true, silent = true }

          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<leader>ds', vim.lsp.buf.document_symbol, opts)
          vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, opts)
          vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<leader>e', function() vim.diagnostic.open_float({ bufnr = ev.buf }) end, opts)
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
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