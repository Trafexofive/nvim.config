return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
        -- Safely attempt to set up the gruvbox theme
        local ok, gruvbox = pcall(require, "gruvbox")
        if not ok then
            -- If direct require fails, the theme system will handle it later
            vim.schedule(function()
                -- Try again after the event loop executes, giving lazy more time to load the plugin
                local ok_retry, gruvbox_retry = pcall(require, "gruvbox")
                if ok_retry then
                    gruvbox_retry.setup({
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
                    -- If it still fails, log a message but continue - our theme system will handle theme setup
                    vim.schedule(function()
                        vim.notify("Could not initialize gruvbox theme directly. Theme system will handle initialization.", vim.log.levels.WARN, { title = "Theme Manager" })
                    end)
                end
            end)
        else
            -- If require succeeds immediately, proceed with setup
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