-- mini.tabline - Clean tabline for buffer management
-- Zen: Minimal, shows only essentials, gruvbox-themed
return {
    "echasnovski/mini.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
        local tabline = require("mini.tabline")
        
        tabline.setup({
            -- ════════════════════════════════════════
            -- Zen Mode: Minimal, only show essentials
            -- ════════════════════════════════════════
            -- Which tabline part to show (zen: only show tabs + truncation)
            show = {
                file = true,      -- Show file icon + name
                bufflag = true,   -- Show buffer flags (modified, readonly)
                tabpages = false, -- Hide tabpages (distraction)
            },
            
            -- Truncation (keep it short and clean)
            trunc_method = "left", -- Truncate from left
            max_noen = 2,          -- Max non-file buffers to show (zen: less noise)
            max_tabs = 10,        -- Max tabs to show
            
            -- Format (minimal, clean)
            format = {
                name = function(buf_id)
                    -- Get filename (zen: short, no path)
                    local name = vim.api.nvim_buf_get_name(buf_id)
                    if name == '' then return '[No Name]' end
                    name = vim.fn.fnamemodify(name, ':t') -- Just filename
                    
                    -- Add icon if devicons available
                    local icon = ''
                    local ok, web_devicons = pcall(require, 'nvim-web-devicons')
                    if ok then
                        local ft = vim.bo[buf_id].filetype
                        icon = web_devicons.get_icon(name, ft, { default = true })
                    end
                    
                    return icon .. ' ' .. name
                end,
                
                bufflag = function(buf_id)
                    local flags = ''
                    if vim.bo[buf_id].modified then flags = flags .. '[+]' end
                    if not vim.bo[buf_id].modifiable then flags = flags .. '[=]' end
                    if vim.bo[buf_id].readonly then flags = flags .. '[RO]' end
                    return flags
                end,
            },
            
            -- Styling (gruvbox-themed, subtle)
            style = {
                current = 'MiniTablineCurrent',
                default = 'MiniTablineDefault',
                tabpage = 'MiniTablineTabpage',
                fill = 'MiniTablineFill',
            },
        })
        
        -- ════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("MiniTablineHighlights", { clear = true }),
            callback = function()
                -- Current tab (gruvbox yellow - attention but not blinding)
                vim.api.nvim_set_hl(0, "MiniTablineCurrent", {
                    fg = "#282828",
                    bg = "#fabd2f",
                    bold = true,
                    nocombine = true
                })
                
                -- Default tab (gruvbox bg1 - subtle)
                vim.api.nvim_set_hl(0, "MiniTablineDefault", {
                    fg = "#ebdbb2",
                    bg = "#3c3836",
                    nocombine = true
                })
                
                -- Tabpage (gruvbox gray - dimmed)
                vim.api.nvim_set_hl(0, "MiniTablineTabpage", {
                    fg = "#a89984",
                    bg = "#3c3836",
                    nocombine = true
                })
                
                -- Fill (gruvbox bg0 - matches background)
                vim.api.nvim_set_hl(0, "MiniTablineFill", {
                    bg = "#282828",
                    nocombine = true
                })
                
                -- Modified flag (gruvbox orange-red)
                vim.api.nvim_set_hl(0, "MiniTablineModifiedCurrent", {
                    fg = "#fb4934",
                    bg = "#fabd2f",
                    bold = true
                })
                vim.api.nvim_set_hl(0, "MiniTablineModifiedDefault", {
                    fg = "#fb4934",
                    bg = "#3c3836"
                })
                
                -- Selected (gruvbox blue)
                vim.api.nvim_set_hl(0, "MiniTablineSelected", {
                    fg = "#458588",
                    bg = "#3c3836",
                    bold = true
                })
            end,
        })
        
        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
