return {
  -- Main markdown plugin for navigation and utilities
  {
    "jakewvincent/mkdnflow.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("mkdnflow").setup({
        modules = {
          bib = true,     -- Bibliography support
          buffers = true, -- Buffer management
          conceal = true, -- Conceal formatting syntax
          cursor = true,  -- Cursor positioning
          folds = true,   -- Folding
          links = true,   -- Link handling
          lists = true,   -- List handling
          maps = true,    -- Default mappings
          paths = true,   -- Path handling
          tables = true,  -- Table handling
          yaml = true,    -- YAML metadata handling
        },
        filetypes = { md = true, markdown = true, mkd = true, mdown = true },
        links = {
          style = "markdown", -- Default link style
          implicit_extension = "md", -- Extension for implicit links
          transform_explicit = function(text)
            text = text:gsub(" ", "-")
            text = text:lower()
            return text
          end,
        },
        tables = {
          trim_whitespace = true, -- Trim whitespace in table cells
        },
        yaml = {
          bib = { override = false }, -- Use pandoc-style bibliography
        },
        mappings = {
          MkdnEnter = { { "n", "v" }, "<CR>" },
          MkdnTab = false,
          MkdnSTab = false,
          MkdnNextLink = { "n", "<Tab>" },
          MkdnPrevLink = { "n", "<S-Tab>" },
          MkdnFollowLink = { "n", "<leader>o" },
          MkdnGoBack = { "n", "<leader><leader>" },
          MkdnCreateLink = { "n", "<leader>cl" },
          MkdnCreateLinkFromClipboard = { { "n", "v" }, "<leader>cp" },
          MkdnToggleToDo = { { "n", "v" }, "<C-Space>" },
          MkdnNewListItem = { "n", "<CR>" },
          MkdnNewListItemBelow = { "n", "o" },
          MkdnNewListItemAbove = { "n", "O" },
          MkdnExtendList = { "n", "." },
          MkdnExtendListBelow = { "n", "gl" },
          MkdnExtendListAbove = { "n", "gll" },
          MkdnUpdateNumbering = { "n", "<leader>nn" },
          MkdnToggleBulletList = { "n", "<leader>bb" },
          MkdnToggleNumberList = { "n", "<leader>bn" },
          MkdnToggleCheckBox = { "n", "<leader>bt" },
          MkdnMoveSource = { "n", "<leader>ms" },
          MkdnYankAnchorLink = { "n", "<leader>ya" },
          MkdnYankFileAnchorLink = { "n", "<leader>yf" },
          MkdnNextHeading = { "n", "]]" },
          MkdnPrevHeading = { "n", "[[" },
          MkdnGoToHeading = { "n", "g]" },
          MkdnGoToPreviousHeading = { "n", "g[" },
        },
      })
    end,
  },

  -- Better markdown preview with live updates
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = "markdown",
    config = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_command_for_global = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_open_ip = ""
      vim.g.mkdp_port = ""
      vim.g.mkdp_page_title = "${name}"
    end,
  },

  -- Markdown code blocks highlighting
  {
    "lukas-reineke/headlines.nvim",
    ft = "markdown",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("headlines").setup({
        markdown = {
          headline_highlights = { "Headline1", "Headline2", "Headline3", "Headline4" },
          codeblock_highlight = "CodeBlock",
          dash_highlight = "Dash",
          quote_highlight = "Quote",
          bullets = { "◉", "○", "✸", "✿" },
        },
      })
      
      -- Set up custom highlights for headlines
      vim.api.nvim_set_hl(0, "Headline1", { bg = "#1e232a" })
      vim.api.nvim_set_hl(0, "Headline2", { bg = "#1c2127" })
      vim.api.nvim_set_hl(0, "Headline3", { bg = "#1b2026" })
      vim.api.nvim_set_hl(0, "Headline4", { bg = "#191e24" })
      vim.api.nvim_set_hl(0, "CodeBlock", { bg = "#1a1f26" })
      vim.api.nvim_set_hl(0, "Dash", { bold = true })
    end,
  },

  -- Sniprun for code block execution
  {
    "michaelb/sniprun",
    build = "bash ./install.sh",
    ft = "markdown",
    config = function()
      require("sniprun").setup({
        selected_interpreters = {}, 
        repl_enable = {},
        repl_disable = {},
        interpreter_options = {},
        display = {
          "Classic", --# display results in the command-line  'echo'
        },
        live_display = { "VirtualTextOk" },
        display_options = {
          terminal_width = 45,
          notification_timeout = 5,
        },
        cli = {},
      })
    end,
  },
}