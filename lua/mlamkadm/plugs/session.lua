return {
  "rmagatti/auto-session",
  dependencies = { "nvim-telescope/telescope.nvim" }, -- Ensure Telescope is loaded
  event = "VimEnter",
  config = function()
    require("auto-session").setup({
      log_level = "error",
      auto_save = { enabled = true },
      auto_restore = { enabled = true },
      auto_session_suppress_dirs = { "~/", "/" },
      auto_session_strategy = "dir",
    })

    -- Load the telescope extension for auto-session
    pcall(require('telescope').load_extension, 'session-lens')

    -- Keymaps for session management
    vim.keymap.set("n", "<leader>ss", "<cmd>Telescope session-lens<CR>", { desc = "Search sessions" })
    vim.keymap.set("n", "<leader>sr", "<cmd>SessionRestore<CR>", { desc = "Restore last session" })
  end,
}
