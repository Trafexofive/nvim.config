-- mini.files - Lightweight file explorer
-- Zen: Minimal, fast, gruvbox-themed
return {
    "echasnovski/mini.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
        local files = require("mini.files")
        
        files.setup({
            -- ════════════════════════════════════════
            -- Zen Mode: Minimal, just the essentials
            -- ════════════════════════════════════════
            -- Windows (subtle, not intrusive)
            windows = {
                preview = {
                    height = 0.5,
                    width = 0.5,
                    border = "rounded",
                    win_options = {
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
                    },
                },
            },
            
            -- Mappings (zen: intuitive, minimal)
            mappings = {
                close = '<C-c>',
                reset = '<C-r>',
                apply = '<CR>',
                sync = 's',
            },
            
            -- Options (clean, no distractions)
            options = {
                use_cursor_hl = true,  -- Highlight cursor line
                permanent = false,      -- Don't keep around (zen: less clutter)
            },
        })
        
        -- Keymaps
        vim.keymap.set("n", "<leader>fe", function() require("mini.files").open() end, { desc = "Open File Explorer" })
        vim.keymap.set("n", "<leader>fc", function() require("mini.files").close() end, { desc = "Close File Explorer" })
        vim.keymap.set("n", "<leader>fs", function() require("mini.files").synchronize() end, { desc = "Sync File Explorer" })
        
        -- ════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("MiniFilesHighlights", { clear = true }),
            callback = function()
                -- Directory (gruvbox blue)
                vim.api.nvim_set_hl(0, "MiniFilesDirectory", { fg = "#458588", bold = true })
                
                -- File (gruvbox fg1)
                vim.api.nvim_set_hl(0, "MiniFilesFile", { fg = "#ebdbb2" })
                
                -- Cursor (gruvbox bg3)
                vim.api.nvim_set_hl(0, "MiniFilesCursorLine", { bg = "#665c54" })
                
                -- Border (gruvbox gray)
                vim.api.nvim_set_hl(0, "MiniFilesBorder", { fg = "#928374" })
                
                -- Title (gruvbox yellow)
                vim.api.nvim_set_hl(0, "MiniFilesTitle", { fg = "#fabd2f", bold = true })
                
                -- Normal (gruvbox bg1)
                vim.api.nvim_set_hl(0, "MiniFilesNormal", { fg = "#ebdbb2", bg = "#3c3836" })
            end,
        })
        
        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
