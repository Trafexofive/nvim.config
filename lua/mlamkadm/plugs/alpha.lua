-- alpha-nvim - Better dashboard
-- Zen: Minimal, just the essentials, gruvbox-themed
return {
    "goolord/alpha-nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    opts = {
        -- ══════════════════════════════════════════
        -- Zen Mode: Minimal dashboard, no clutter
        -- ══════════════════════════════════════════
        layout = {
            { type = "padding", val = 5 },
            { type = "text", val = "✧", opts = { position = "center", hl = "AlphaHeader" } },
            { type = "padding", val = 1 },
            { type = "text", val = "neovim", opts = { position = "center", hl = "AlphaHeader" } },
            { type = "padding", val = 2 },
            { type = "text", val = "◆", opts = { position = "center", hl = "AlphaIcon" } },
            { type = "padding", val = 1 },
            {
                type = "text",
                val = "Session: " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
                opts = { position = "center", hl = "AlphaSession" },
            },
            { type = "padding", val = 3 },
            {
                type = "button",
                val = "  > Start Coding  ",
                on_press = function()
                    vim.cmd("enew")
                end,
                opts = { hl = "AlphaButton", hl_shortcut = "AlphaShortcut" },
            },
            { type = "padding", val = 1 },
            {
                type = "button",
                val = "  > Restore Session  ",
                on_press = function()
                    vim.cmd("SessionRestore")
                end,
                opts = { hl = "AlphaButton", hl_shortcut = "AlphaShortcut" },
            },
            { type = "padding", val = 1 },
            {
                type = "button",
                val = "  > Kill Zellij Sessions  ",
                on_press = function()
                    require("mlamkadm.core.terminal").kill_all_zellij_sessions()
                end,
                opts = { hl = "AlphaButton", hl_shortcut = "AlphaShortcut" },
            },
            { type = "padding", val = 2 },
            { type = "text", val = "◆", opts = { position = "center", hl = "AlphaIcon" } },
        },

        opts = {
            margin = 5,
            setup = function()
                -- No setup needed (zen: minimal)
            end,
            opts = {
                noautocmd = true, -- Don't trigger autocmds (zen: no interference)
            },
        },
    },
    config = function(_, opts)
        local alpha = require("alpha")
        alpha.setup(opts)

        -- ══════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ══════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("AlphaHighlights", { clear = true }),
            callback = function()
                -- Header (gruvbox yellow - warm, inviting)
                vim.api.nvim_set_hl(0, "AlphaHeader", {
                    fg = "#fabd2f",
                    bold = true,
                    nocombine = true,
                })

                -- Icon (gruvbox orange - attention)
                vim.api.nvim_set_hl(0, "AlphaIcon", {
                    fg = "#fe8019",
                    nocombine = true,
                })

                -- Session name (gruvbox blue - information)
                vim.api.nvim_set_hl(0, "AlphaSession", {
                    fg = "#458588",
                    italic = true,
                    nocombine = true,
                })

                -- Button (gruvbox bg1 - subtle)
                vim.api.nvim_set_hl(0, "AlphaButton", {
                    fg = "#ebdbb2",
                    bg = "#3c3836",
                    bold = true,
                    nocombine = true,
                })

                -- Shortcut (gruvbox gray - dimmed)
                vim.api.nvim_set_hl(0, "AlphaShortcut", {
                    fg = "#928374",
                    nocombine = true,
                })

                -- Footer (gruvbox bg1 - very subtle)
                vim.api.nvim_set_hl(0, "AlphaFooter", {
                    fg = "#665c54",
                    italic = true,
                    nocombine = true,
                })
            end,
        })

        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")

        -- ══════════════════════════════════════════
        -- Auto-open dashboard on startup (zen: clean start)
        -- ══════════════════════════════════════════
        vim.api.nvim_create_autocmd("VimEnter", {
            group = vim.api.nvim_create_augroup("AlphaAutoOpen", { clear = true }),
            callback = function()
                -- Only show dashboard if starting with empty buffer
                local buf_name = vim.api.nvim_buf_get_name(0)
                local line_count = vim.api.nvim_buf_line_count(0)
                local first_line = line_count > 0 and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""

                if buf_name == "" and (line_count == 1 and first_line == "" or line_count == 0) then
                    vim.cmd("Alpha")
                end
            end,
            once = true,
        })
    end,
}
