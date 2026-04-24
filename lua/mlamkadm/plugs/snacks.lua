-- snacks.nvim - Ultimate QOL pack (picker, dashboard, git, etc.)
-- Zen: Modular, only enable what you need
return {
    "folke/snacks.nvim",
    version = "*",
    event = "VeryLazy",
    keys = {
        -- Dashboard
        { "<leader>d", function() require("snacks").dashboard() end, desc = "Dashboard" },
        
        -- Picker (replaces telescope for some things)
        { "<leader>f", function() require("snacks").picker.files() end, desc = "Find File" },
        { "<leader>F", function() require("snacks").picker.grep() end, desc = "Grep Text" },
        { "<leader>b", function() require("snacks").picker.buffers() end, desc = "Buffers" },
        { "<leader>r", function() require("snacks").picker.recent() end, desc = "Recent Files" },
        { "<leader>gd", function() require("snacks").picker.git_diff() end, desc = "Git Diff" },
        { "<leader>gB", function() require("snacks").picker.git_branches() end, desc = "Git Branches" },
        { "<leader>gs", function() require("snacks").picker.git_status() end, desc = "Git Status" },
        
        -- Notifications
        { "<leader>un", function() require("snacks").notify.clean() end, desc = "Clear Notifications" },
    },
    opts = {
        -- ══════════════════════════════════════════
        -- Zen Mode: Only enable what you use
        -- ══════════════════════════════════════════
        dashboard = {
            enabled = true,
            -- Minimal, zenful dashboard
            presets = {
                { "<leader>d", section = "keys", title = "Dashboard", align = "center" },
                { "<leader>f", section = "keys", title = "Find File", align = "center" },
                { "<leader>F", section = "keys", title = "Grep Text", align = "center" },
                { "<leader>b", section = "keys", title = "Buffers", align = "center" },
                { "<leader>r", section = "keys", title = "Recent Files", align = "center" },
                { "<leader>q", section = "keys", title = "Quit", align = "center" },
            },
            sections = {
                { section = "header", padding = 5 },
                { section = "keys", gap = 1, padding = 1 },
            },
        },
        
        -- Picker (fast, zenful)
        picker = {
            enabled = true,
            formatters = {
                file = function(item)
                    -- Show just filename (zen: no paths)
                    item.text = vim.fn.fnamemodify(item.file, ":t")
                    return item
                end,
            },
            layouts = {
                -- Default layout (zen: minimal)
                default = {
                    layout = {
                        box = "vertical",
                        { win = "input", height = 1, border = "bottom" },
                        { win = "list", border = "none" },
                        { win = "preview", border = "left" },
                    },
                },
            },
            -- Sources (only what we need)
            sources = {
                files = { enabled = true },
                grep = { enabled = true },
                buffers = { enabled = true },
                recent = { enabled = true },
                git_diff = { enabled = true },
                git_branches = { enabled = true },
                git_status = { enabled = true },
            },
        },
        
        -- Notifications (optional, replaces nvim-notify)
        notify = {
            enabled = false, -- Use nvim-notify for now
        },
        
        -- Git (optional)
        git = {
            enabled = true,
        },
        
        -- Terminal (optional)
        terminal = {
            enabled = false, -- Don't enable yet
        },
    },
    config = function(_, opts)
        local snacks = require("snacks")
        snacks.setup(opts)
        
        -- ══════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ══════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("SnacksHighlights", { clear = true }),
            callback = function()
                -- Dashboard (gruvbox yellow - warm, inviting)
                vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#fabd2f", bold = true, nocombine = true })
                vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = "#b16286", bold = true, nocombine = true }) -- purple
                vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = "#a89984", nocombine = true }) -- gray
                vim.api.nvim_set_hl(0, "SnacksDashboardFooter", { fg = "#665c54", italic = true, nocombine = true }) -- dark gray
                
                -- Picker (gruvbox palette)
                vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#928374", bg = "#3c3836", nocombine = true }) -- gray + bg1
                vim.api.nvim_set_hl(0, "SnacksPickerTitle", { fg = "#ebdbb2", bold = true, nocombine = true }) -- fg1
                vim.api.nvim_set_hl(0, "SnacksPickerNormal", { fg = "#ebdbb2", bg = "#3c3836", nocombine = true }) -- fg1 + bg1
                vim.api.nvim_set_hl(0, "SnacksPickerCursorLine", { bg = "#665c54", nocombine = true }) -- bg3
                vim.api.nvim_set_hl(0, "SnacksPickerMatch", { fg = "#fb4934", bold = true, nocombine = true }) -- red
                vim.api.nvim_set_hl(0, "SnacksPickerInfo", { fg = "#83a598", nocombine = true }) -- blue
                vim.api.nvim_set_hl(0, "SnacksPickerPreview", { bg = "#282828", nocombine = true }) -- bg0
                
                -- Git (gruvbox colors)
                vim.api.nvim_set_hl(0, "SnacksGitDiffAdd", { fg = "#98971a", nocombine = true }) -- green
                vim.api.nvim_set_hl(0, "SnacksGitDiffChange", { fg = "#d79921", nocombine = true }) -- yellow
                vim.api.nvim_set_hl(0, "SnacksGitDiffDelete", { fg = "#cc241d", nocombine = true }) -- red
            end,
        })
        
        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
