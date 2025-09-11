return {
  {
    "jakewvincent/mkdnflow.nvim",
    ft = "markdown", -- Load only for markdown files
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "akinsho/toggleterm.nvim",
    },
    config = function()
      require("mkdnflow").setup({
        -- Sensible defaults are used. Customizations can be added here.
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
    end,
  },
}