-- mini.jump2d - Smart 2-character jump with labels
-- Zen: Labels appear only when you type, disappear after jump
return {
    "echasnovski/mini.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
        local jump2d = require("mini.jump2d")
        
        jump2d.setup({
            -- Labels: only show when typing (zen!)
            labels = "asdfghjklqwertyuiopzxcvbnm",
            --spotter = nil, -- Use default spotter (word start + unique spots)
            
            -- Visual style (subtle, gruvbox-adapted)
            hint_hl_group = "MiniJump2dHint",
            -- No animations (zen: no distraction)
            delay = { text_change = 100, position_change = 150 },
            
            -- Search options
            search_scope = "all", -- Search all windows
            allowed_lines = { cursor_before = 100, cursor_after = 100 },
            --allowed_windows = function(win) return vim.api.nvim_win_get_config(win).focusable end,
            
            -- Mappings (zen: intuitive, suggested)
            mappings = {
                start_jump = "<leader>j", -- Start jump mode
                start_spotter = "<leader><leader>j", -- Start with spotter
            },
        })
        
        -- ════════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ════════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("MiniJump2dHighlights", { clear = true }),
            callback = function()
                -- Subtle hint color (gruvbox yellow, not too bright)
                vim.api.nvim_set_hl(0, "MiniJump2dHint", {
                    fg = "#282828", -- Dark text
                    bg = "#fabd2f", -- Gruvbox yellow (bright but not blinding)
                    bold = true,
                    nocombine = true
                })
            end,
        })
        
        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
