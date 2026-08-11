-- snacks.nvim — Ultimate QOL pack (dashboard, picker, git)
-- Merged from snacks.lua + snacks-dashboard.lua
-- Zen: modular, only enable what you use
return {
    "folke/snacks.nvim",
    version = "*",
    priority = 1000,
    lazy = false,
    keys = {
        -- Dashboard
        { "<leader>d",  function() require("snacks").dashboard() end,           desc = "Dashboard" },

        -- Picker
        { "<leader>f",  function() require("snacks").picker.files() end,        desc = "Find File" },
        { "<leader>F",  function() require("snacks").picker.grep() end,         desc = "Grep Text" },
        { "<leader>b",  function() require("snacks").picker.buffers() end,      desc = "Buffers" },
        { "<leader>r",  function() require("snacks").picker.recent() end,       desc = "Recent Files" },
        { "<leader>gd", function() require("snacks").picker.git_diff() end,     desc = "Git Diff" },
        { "<leader>gB", function() require("snacks").picker.git_branches() end, desc = "Git Branches" },
        { "<leader>gs", function() require("snacks").picker.git_status() end,   desc = "Git Status" },

        -- Notifications
        { "<leader>un", function() require("snacks").notify.clean() end,        desc = "Clear Notifications" },
    },
    opts = {
        -- ══════════════════════════════════════════
        -- Dashboard (snacks-dashboard.lua merge)
        -- ══════════════════════════════════════════
        dashboard = {
            enabled = true,
            autokeys = "", -- Disable autokeys
            preset = {
                header = nil,
                keys = {
                    { icon = "󰈞", key = "f", desc = "Find File", action = ":Telescope find_files" },
                    { icon = "", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
                    { icon = "󱍾", key = "s", desc = "Sessions", action = function() require(
                        "mlamkadm.core.session_manager").sessions_with_readme() end },
                    { icon = "󰽤", key = "S", desc = "Restore Session", action = ":SessionRestore" },
                    { icon = "󱌣", key = "n", desc = "New Session", action = function() require(
                        "mlamkadm.core.session_manager").create_new_session() end },
                    { icon = "󰦉", key = "w", desc = "Temp Workspace", action = function() require(
                        "mlamkadm.core.session_manager").create_temp_session() end },
                    { icon = "", key = "D", desc = "Delete Session", action = function() require(
                        "mlamkadm.core.session_manager").delete_session() end },
                    { icon = "", key = "t", desc = "TUI Commands", action = function() require("mlamkadm.core.terminal")
                            .show_tui_registry() end },
                    { icon = "󱌣", key = "b", desc = "btop", action = function() require("mlamkadm.core.ui").open_page(
                        "btop") end },
                    { icon = "󰺢", key = "d", desc = "lazydocker", action = function() require("mlamkadm.core.ui")
                            .open_page("lazydocker") end },
                    { icon = "󰺢", key = "h", desc = "Change Theme", action = function() require("mlamkadm.core.theme")
                            .select_theme() end },
                    { icon = "󰒲", key = "l", desc = "Lazy", action = ":Lazy" },
                    { icon = "", key = "q", desc = "Quit", action = ":qa" },
                },
            },
            formats = {
                key = function(item)
                    return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
                end,
            },
            sections = {
                -- ASCII art header
                {
                    section = "terminal",
                    cmd = vim.fn.expand("~/repos/active/aart/aart") ..
                    " --raw --center " .. vim.fn.expand("~/.config/aart/dashboard-art.aa"),
                    height = 26,
                    padding = 1,
                    ttl = 0,
                    indent = 0,
                    opts = {
                        interactive = false,
                        bo = { scrollback = 1 },
                    },
                },
                -- Terminal launcher section
                {
                    title = "Terminal",
                    icon = "",
                    padding = 1,
                    {
                        icon = "",
                        key = "T",
                        desc = "Open persistent Zellij",
                        action = function() require("mlamkadm.core.terminal").open_zellij() end,
                    },
                },
                { section = "keys",   gap = 1, padding = 1 },
                { section = "startup" },
            },
        },

        -- ══════════════════════════════════════════
        -- Picker (fast, zenful)
        -- ══════════════════════════════════════════
        picker = {
            enabled = true,
            formatters = {
                file = function(item)
                    item.text = vim.fn.fnamemodify(item.file, ":t")
                    return item
                end,
            },
            layouts = {
                default = {
                    layout = {
                        box = "vertical",
                        { win = "input",   height = 1,     border = "bottom" },
                        { win = "list",    border = "none" },
                        { win = "preview", border = "left" },
                    },
                },
            },
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

        -- Notifications (disabled — using nvim-notify)
        notify = { enabled = false },

        -- Git
        git = { enabled = true },

        -- Terminal (disabled for now)
        terminal = { enabled = false },
    },
    config = function(_, opts)
        local snacks = require("snacks")
        snacks.setup(opts)

        -- Show a hint when dashboard opens
        vim.api.nvim_create_autocmd("User", {
            pattern = "SnacksDashboardOpened",
            callback = function()
                vim.defer_fn(function()
                    vim.notify("Press 'b' for btop, 'd' for lazydocker, 'h' to change theme", vim.log.levels.INFO,
                        { timeout = 2000 })
                end, 1000)
            end,
        })

        -- ══════════════════════════════════════════
        -- Gruvbox-themed highlights
        -- ══════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("SnacksHighlights", { clear = true }),
            callback = function()
                -- Dashboard
                vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#fabd2f", bold = true, nocombine = true }) -- yellow
                vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = "#b16286", bold = true, nocombine = true }) -- purple
                vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = "#a89984", nocombine = true })          -- gray
                vim.api.nvim_set_hl(0, "SnacksDashboardFooter", { fg = "#665c54", italic = true, nocombine = true }) -- dark gray
                -- Picker
                vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#928374", bg = "#3c3836", nocombine = true })
                vim.api.nvim_set_hl(0, "SnacksPickerTitle", { fg = "#ebdbb2", bold = true, nocombine = true })
                vim.api.nvim_set_hl(0, "SnacksPickerNormal", { fg = "#ebdbb2", bg = "#3c3836", nocombine = true })
                vim.api.nvim_set_hl(0, "SnacksPickerCursorLine", { bg = "#665c54", nocombine = true })
                vim.api.nvim_set_hl(0, "SnacksPickerMatch", { fg = "#fb4934", bold = true, nocombine = true })
                vim.api.nvim_set_hl(0, "SnacksPickerInfo", { fg = "#83a598", nocombine = true })
                vim.api.nvim_set_hl(0, "SnacksPickerPreview", { bg = "#282828", nocombine = true })
                -- Git
                vim.api.nvim_set_hl(0, "SnacksGitDiffAdd", { fg = "#98971a", nocombine = true })
                vim.api.nvim_set_hl(0, "SnacksGitDiffChange", { fg = "#d79921", nocombine = true })
                vim.api.nvim_set_hl(0, "SnacksGitDiffDelete", { fg = "#cc241d", nocombine = true })
            end,
        })
        vim.cmd("doautocmd ColorScheme")
    end,
}
