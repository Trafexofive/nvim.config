-- Mini.nvim - Collection of small, independent, and fast plugins
-- Unified configuration for a Zen experience
return {
    {
        "echasnovski/mini.nvim",
        version = "*",
        event = "VeryLazy",
        config = function()
            -- 1. Indentscope: Subtle scope indicators
            require("mini.indentscope").setup({
                symbol = "│",
                options = { try_as_border = true }
            })

            -- 2. Cursorword: Subtle highlight of word under cursor
            require("mini.cursorword").setup({ delay = 200 })

            -- 3. Bufremove: Delete buffers without breaking layout
            require("mini.bufremove").setup()

            -- 4. Icons: Standard icon provider
            require("mini.icons").setup()

            -- 5. Files: Minimal file explorer
            require("mini.files").setup({
                windows = {
                    preview = true, -- Enable preview
                    width_focus = 30,
                    width_nofocus = 15,
                }
            })

            -- 6. Jump2d: Fast 2-char navigation
            require("mini.jump2d").setup({
                labels = "asdfghjklqwertyuiopzxcvbnm",
                view = {
                    dim = true, -- Dim background for focus
                },
                mappings = {
                    start_jump = "<leader>j",
                },
            })

            -- ════════════════════════════════════════════
            -- Mappings for Mini Modules
            -- ════════════════════════════════════════════
            local map = vim.keymap.set
            
            -- mini.bufremove
            map("n", "<leader>bd", function() require("mini.bufremove").delete(0, false) end, { desc = "Delete Buffer" })
            map("n", "<leader>bD", function() require("mini.bufremove").delete(0, true) end, { desc = "Force Delete Buffer" })
            
            -- mini.files
            map("n", "<leader>fe", function() require("mini.files").open() end, { desc = "Open File Explorer (Mini)" })
            
            -- ════════════════════════════════════════════
            -- Highlights (Subtle Gruvbox integration)
            -- ════════════════════════════════════════════
            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = function()
                    local bg3 = "#665c54"
                    local gray = "#928374"
                    local yellow = "#fabd2f"

                    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = bg3, nocombine = true })
                    vim.api.nvim_set_hl(0, "MiniCursorword", { underline = true })
                    vim.api.nvim_set_hl(0, "MiniJump2dHint", { fg = "#282828", bg = yellow, bold = true })
                end,
            })
            vim.cmd("doautocmd ColorScheme")
        end,
    },
}
