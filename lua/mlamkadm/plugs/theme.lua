return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    lazy = false,  -- Load at startup
    config = function()
        -- Our theme system handles everything, so no need for plugin-specific config here
        -- This avoids initialization errors while ensuring the plugin is loaded
    end,
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
  },
  {
    "Mofiqul/dracula.nvim",
    lazy = true,
  },
  {
    "navarasu/onedark.nvim",
    lazy = true,
  },
}