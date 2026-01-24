return {
  {
    "jakewvincent/mkdnflow.nvim",
    ft = "markdown", -- Load only for markdown files
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("mkdnflow").setup({
        -- Sensible defaults are used. Customizations can be added here.
        mappings = {
            MkdnEnter = {{'i', 'n'}, '<CR>'},
            MkdnTab = false,
            MkdnSTab = false,
            MkdnNextLink = {'n', '<Tab>'},
            MkdnPrevLink = {'n', '<S-Tab>'},
            MkdnNextHeading = {'n', ']]'},
            MkdnPrevHeading = {'n', '[['},
            MkdnGoBack = {'n', '<BS>'},
            MkdnGoForward = {'n', '<Del>'},
            MkdnFollowLink = false, -- We use CR
            MkdnDestroyLink = {'n', '<leader>md'},
            MkdnTagSpan = {'v', '<leader>mt'},
            MkdnMoveSource = {'n', '<leader>mv'},
            MkdnYankAnchor = {'n', '<leader>my'},
            MkdnYankFileAnchor = {'n', '<leader>mY'},
            MkdnIncreaseHeading = {'n', '<leader>m+'},
            MkdnDecreaseHeading = {'n', '<leader>m-'},
            MkdnToggleTodo = {{'n', 'v'}, '<leader>mt'},
            MkdnNewListItem = false,
            MkdnNewListItemBelow = {'n', '<leader>o'},
            MkdnNewListItemAbove = {'n', '<leader>O'},
            MkdnUpdateNumbering = {'n', '<leader>mn'},
            MkdnTableNextCell = {'i', '<Tab>'},
            MkdnTablePrevCell = {'i', '<S-Tab>'},
            MkdnTableNextRow = false,
            MkdnTablePrevRow = {'i', '<M-CR>'},
            MkdnTableNewRowBelow = {'n', '<leader>ir'},
            MkdnTableNewRowAbove = {'n', '<leader>iR'},
            MkdnTableNewColAfter = {'n', '<leader>ic'},
            MkdnTableNewColBefore = {'n', '<leader>iC'},
            MkdnFoldSection = {'n', '<leader>mf'},
            MkdnUnfoldSection = {'n', '<leader>mF'}
        },
        -- Automatically enable spell checking and wrapping for markdown files.
        ft_plugin = {
            ['markdown'] = {
                spell = true,
                wrap = true,
            },
        },
      })

      -- Keymap for previewing with glow, using our global terminal function.
      vim.keymap.set("n", "<leader>mp", function()
        _G.Poptui('glow -p ' .. vim.fn.expand('%'))
      end, { desc = "Markdown Preview (Glow)" })

      -- Keymap for browsing markdown files in the current directory with glow.
      vim.keymap.set("n", "<leader>mP", function()
        _G.Poptui('glow .')
      end, { desc = "Browse Markdown with Glow" })
    end,
  },
}