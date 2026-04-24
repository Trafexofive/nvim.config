-- flash.nvim - Fast navigation with 2-character jumps
-- Zen: Shows labels only when you type, disappears after jump
return {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
        -- 2-character search (powers: s, S, f, F, t, T)
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesiter" },
        { "r", mode = { "o" }, function() require("flash").remote() end, desc = "Remote Flash" },
        { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash in Search" },
        
        -- Labels for f, F, t, T (native-like but with labels)
        { "f", mode = { "n", "x", "o" }, function() require("flash").jump({ fn = function(win) return require("flash").jump_targets.win_hightlight({ fn = require("flash").jump_targets.char(win, 1) }) end }) end, desc = "Flash f" },
        { "F", mode = { "n", "x", "o" }, function() require("flash").jump({ fn = function(win) return require("flash").jump_targets.win_hightlight({ fn = require("flash").jump_targets.char(win, 1, true) }) end }) end, desc = "Flash F" },
        { "t", mode = { "n", "x", "o" }, function() require("flash").jump({ fn = function(win) return require("flash").jump_targets.win_hightlight({ fn = require("flash").jump_targets.char(win, 1, false, true) }) end }) end, desc = "Flash t" },
        { "T", mode = { "n", "x", "o" }, function() require("flash").jump({ fn = function(win) return require("flash").jump_targets.win_hightlight({ fn = require("flash").jump_targets.char(win, 1, true, true) }) end }) end, desc = "Flash T" },
    },
    config = function()
        require("flash").setup({
            -- Labels: only show when typing (zen: invisible until needed)
            labels = "asdfghjklqwertyuiopzxcvbnm",
            label = {
                style = "overlay", -- Render label as overlay (zen: no text shift)
                uppercase = false, -- Use lowercase (less intimidating)
            },
            
            -- Search (s/S)
            search = {
                multi_window = true,
                recall = true, -- Remember previous search
                incremental = true, -- Show results as you type
                twist = true, -- Jump to pattern start
                prompt = { enabled = true }, -- Show prompt with search pattern
                -- Only search current window by default (zen: less distraction)
                multi_window = false,
            },
            
            -- Jump (f/F/t/T)
            jump = {
                inversion = { -- Invert labeled targets
                    match_only = true, -- Only invert the matched character
                },
                jump_position = "start", -- Jump to start of label
            },
            
            -- Treesiter (S)
            treesitter = {
                labels = "asdfghjklqwertyuiopzxcvbnm",
            },
            
            -- Remote flash (r)
            remote = {
                label = {
                    rainbow = { -- Color labels by distance (pretty!)
                        enabled = true,
                        shade = 5, -- Intensity of colors
                    },
                },
            },
            
            -- Highlight groups (gruvbox colors, subtle)
            highlight = {
                -- Label above/below target
                above = "FlashAbove",
                below = "FlashBelow",
                -- Label in current line
                current = "FlashCurrent",
                -- Label in other windows
                remote = "FlashRemote",
            },
        })

        -- ════════════════════════════════════════════
        -- Gruvbox-adapted highlights (subtle, zenful)
        -- ══════════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("FlashHighlights", { clear = true }),
            callback = function()
                -- Subtle labels that don't distract
                vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = "#7c8f8f" }) -- gruvbox gray (dim)
                vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#fb4934", bold = true, nocombine = true }) -- gruvbox red (attention)
                vim.api.nvim_set_hl(0, "FlashMatch", { bg = "#d79921", nocombine = true }) -- gruvbox yellow (highlight)
                vim.api.nvim_set_hl(0, "FlashCurrent", { fg = "#458588", bold = true, nocombine = true }) -- gruvbox blue
                vim.api.nvim_set_hl(0, "FlashAbove", { fg = "#98971a", nocombine = true }) -- gruvbox green
                vim.api.nvim_set_hl(0, "FlashBelow", { fg = "#b16286", nocombine = true }) -- gruvbox purple
                vim.api.nvim_set_hl(0, "FlashRemote", { fg = "#fabd2f", nocombine = true }) -- gruvbox yellow (bright)
            end,
        })
        
        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
