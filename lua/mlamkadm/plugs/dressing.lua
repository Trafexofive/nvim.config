-- dressing.nvim — consistent UI for vim.ui.select/input
return {
  "stevearc/dressing.nvim",
  lazy = false,
  config = function()
    require("dressing").setup({
      select = { backend = { "telescope", "fzf", "nui", "builtin" } },
      input = { enabled = true },
    })
  end,
}
