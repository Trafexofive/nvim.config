-- Mini.nvim - Collection of small, independent, and fast plugins
-- Using specific modules: statusline + indentscope for zenful experience
return {
    {
        "echasnovski/mini.nvim",
        version = "*",
        event = "VeryLazy",
        config = function()
            -- ════════════════════════════════════════════
            -- Mini Statusline - Clean, minimal, informative
            -- ════════════════════════════════════════════
            local statusline = require("mini.statusline")
            
            -- Custom content sections
            local function is_active()
                return vim.api.nvim_get_current_win() == vim.fn.getlastknownwin()
            end

            statusline.setup({
                content = {
                    active = function()
                        local mode = statusline.combine_groups({
                            { hl = "MiniStatuslineMode" .. statusline.section_mode()[1], strings = { statusline.section_mode()[2] } },
                            { hl = "MiniStatusline", strings = { " " } },
                            { hl = "MiniStatuslineFilename", strings = { statusline.section_filename({ trunc_width = 80 }) } },
                        })
                        
                        return statusline.combine_groups({
                            { hl = "MiniStatusline", strings = { mode } },
                            { hl = "MiniStatusline", strings = { statusline.section_git({ trunc_width = 40 }) } },
                            { hl = "MiniStatusline", strings = { "%=" } }, -- Right align
                            { hl = "MiniStatusline", strings = { statusline.section_diagnostics({ trunc_width = 90 }) } },
                            { hl = "MiniStatusline", strings = { statusline.section_lsp({ trunc_width = 75 }) } },
                            { hl = "MiniStatusline", strings = { " " } },
                            { hl = "MiniStatusline", strings = { statusline.section_location({ trunc_width = 75 }) } },
                        })
                    end,
                    inactive = function()
                        return statusline.combine_groups({
                            { hl = "MiniStatuslineInactive", strings = { statusline.section_filename({ trunc_width = 60 }) } },
                            { hl = "MiniStatuslineInactive", strings = { "%=" } },
                            { hl = "MiniStatuslineInactive", strings = { statusline.section_location({ trunc_width = 75 }) } },
                        })
                    end,
                },
                
                -- Use default highlighting (adapts to your colorscheme)
                use_icons = true,
                caret_in_line_number = true,
            })

            -- ════════════════════════════════════════════
            -- Mini CursorWord - Subtle highlight of word under cursor
            -- ════════════════════════════════════════════
            local cursorword = require("mini.cursorword")
            cursorword.setup({
                -- Only highlight when not typing (zen: no distraction while editing)
                delay = 150, -- Small delay to avoid flicker during fast typing
                gen_hl_group = function(word)
                    return "MiniCursorword"
                end,
            })

            -- Subtle highlight for cursorword (gruvbox colors)
            vim.api.nvim_set_hl(0, "MiniCursorword", { underline = true, sp = "#a89984" }) -- gruvbox gray, subtle
            vim.api.nvim_set_hl(0, "MiniCursorwordCurrent", { underline = true, bold = true, sp = "#fabd2f" }) -- gruvbox yellow, current

            -- ════════════════════════════════════════════
            -- Mini Indentscope - Subtle indent guides
            -- Only shows in active scope, invisible otherwise
            -- ════════════════════════════════════════════
            local indentscope = require("mini.indentscope")
            
            indentscope.setup({
                -- Only show in active scope
                draw = {
                    delay = 100, -- Small delay to avoid flicker
                    animation = function(direction, left, top, bottom)
                        if direction == "open" then
                            vim.cmd("redrawstatus")
                        end
                    end,
                },
                
                -- Symbol configuration (thin, subtle)
                symbol = "│", -- Simple vertical line
                
                -- Options
                options = {
                    -- Only show for reasonable indent levels
                    indent_at = function(line)
                        return vim.bo.indentexpr ~= "" and vim.bo.indentexpr or vim.fn.indent(line)
                    end,
                    
                    -- Disable for certain filetypes
                    disable = function(bufnr)
                        local ft = vim.bo[bufnr].filetype
                        local disabled = { "help", "alpha", "dashboard", "neo-tree", "TelescopePrompt", "snacks_dashboard" }
                        return vim.tbl_contains(disabled, ft)
                    end,
                },
                
                -- Only show in active window
                scope = "cursor", -- Show indent at cursor position
            })

            -- ════════════════════════════════════════════
            -- Highlight Groups (Gruvbox-adapted, subtle)
            -- ════════════════════════════════════════════
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = vim.api.nvim_create_augroup("MiniHighlights", { clear = true }),
                callback = function()
                    -- Statusline mode colors (gruvbox palette)
                    vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = "#282828", bg = "#458588", bold = true })
                    vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { fg = "#282828", bg = "#b8bb26", bold = true })
                    vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { fg = "#282828", bg = "#d79921", bold = true })
                    vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = "#282828", bg = "#fb4934", bold = true })
                    vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = "#282828", bg = "#b16286", bold = true })
                    
                    -- Active/Inactive statusline
                    vim.api.nvim_set_hl(0, "MiniStatusline", { fg = "#ebdbb2", bg = "#3c3836" })
                    vim.api.nvim_set_hl(0, "MiniStatuslineInactive", { fg = "#a89984", bg = "#282828" })
                    
                    -- Filename
                    vim.api.nvim_set_hl(0, "MiniStatuslineFilename", { fg = "#ebdbb2", bold = true })
                    
                    -- Diagnostics (using diagnostic colors)
                    vim.api.nvim_set_hl(0, "MiniStatuslineError", { fg = "#fb4934" })
                    vim.api.nvim_set_hl(0, "MiniStatuslineWarn", { fg = "#fabd2f" })
                    vim.api.nvim_set_hl(0, "MiniStatuslineInfo", { fg = "#83a598" })
                    vim.api.nvim_set_hl(0, "MiniStatuslineHint", { fg = "#8ec07c" })
                    
                    -- Indentscope (subtle gruvbox colors)
                    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#665c54", nocombine = true }) -- gruvbox bg3
                end,
            })
            
            -- Trigger initial highlight setup
            vim.cmd("doautocmd ColorScheme")
        end,
    },
}
