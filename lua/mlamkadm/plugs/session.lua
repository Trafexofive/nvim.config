return {
  "rmagatti/auto-session",
  event = "VimEnter",
  opts = {
    log_level = "info",
    auto_session_enable_last_session = true,
    auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
    auto_session_create_root_dir = true,
    auto_session_suppress_dirs = { "~/", "/" },
    auto_session_strategy = "dir",
  },
  keys = {
    {
      "<leader>ss",
      function()
        require("auto-session.session-lens").search_session()
      end,
      desc = "Search and restore session",
    },
    {
      "<leader>sr",
      function()
        require("auto-session").RestoreLastSession()
      end,
      desc = "Restore last session",
    },
  },
  config = function(_, opts)
    require("auto-session").setup(opts)
  end,
}
