return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    lazy = false,  -- Force this plugin to load at startup
    init = function()
      -- Set colorscheme in init to ensure it's available when UI starts
      vim.g.gruvbox_italic = true
      vim.g.gruvbox_contrast_dark = 'hard'
    end,
    config = function()
        -- Safely require and setup gruvbox
        local ok, gruvbox = pcall(require, "gruvbox")
        if ok then
            gruvbox.setup({
                -- contrast = "medium",
                palette_overrides = {},
                overrides = {
                    SignColumn = { bg = "NONE" },
                    NormalFloat = { bg = "NONE" },
                    FloatBorder = { fg = "#928374", bg = "NONE" },
                },
                dim_inactive = false,
                transparent_mode = false,
            })
            vim.cmd.colorscheme "gruvbox"

            -- Set terminal colors to match gruvbox
            vim.g.terminal_color_0 = '#282828'
            vim.g.terminal_color_1 = '#cc241d'
            vim.g.terminal_color_2 = '#98971a'
            vim.g.terminal_color_3 = '#d79921'
            vim.g.terminal_color_4 = '#458588'
            vim.g.terminal_color_5 = '#b16286'
            vim.g.terminal_color_6 = '#689d6a'
            vim.g.terminal_color_7 = '#a89984'
            vim.g.terminal_color_8 = '#928374'
            vim.g.terminal_color_9 = '#fb4934'
            vim.g.terminal_color_10 = '#b8bb26'
            vim.g.terminal_color_11 = '#fabd2f'
            vim.g.terminal_color_12 = '#83a598'
            vim.g.terminal_color_13 = '#d3869b'
            vim.g.terminal_color_14 = '#8ec07c'
            vim.g.terminal_color_15 = '#ebdbb2'
        else
            -- If setup fails, defer to our theme system
            vim.schedule(function()
                local theme_ok, theme_mod = pcall(require, "mlamkadm.core.theme")
                if theme_ok then
                    theme_mod.setup()
                end
            end)
        end
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