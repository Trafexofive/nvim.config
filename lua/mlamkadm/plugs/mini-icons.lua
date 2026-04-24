-- mini.icons - Icon provider for all plugins
-- Zen: Fast, consistent, gruvbox-themed
return {
    "echasnovski/mini.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
        local icons = require("mini.icons")
        
        icons.setup({
            -- ════════════════════════════════════════
            -- Zen Mode: Minimal, just the essentials
            -- ════════════════════════════════════════
            -- Style (subtle, not distracting)
            style = "codepoint", -- Use codepoints (fast, no images)
            
            -- Categories (only enable what we use, zen: less overhead)
            extensions = true, -- File extension icons
            filetypes = true, -- Filetype icons
            lsp = true,       -- LSP/diagnostic icons
            
            -- Default icon (gruvbox gray, subtle)
            default = { glyph = "󱀾", hl = "MiniIconsDefault" },
            
            -- Catalog (minimal, just what we need)
            catalog = {
                -- File extensions (common ones)
                extensions = {
                    -- Code
                    { name = "js",    glyph = "󰊄", hl = "MiniIconsJs" },
                    { name = "ts",    glyph = "󰊆", hl = "MiniIconsTs" },
                    { name = "jsx",   glyph = "󰊄", hl = "MiniIconsJsx" },
                    { name = "tsx",   glyph = "󰊆", hl = "MiniIconsTsx" },
                    { name = "lua",   glyph = "󰓆", hl = "MiniIconsLua" },
                    { name = "py",    glyph = "󰊏", hl = "MiniIconsPy" },
                    { name = "go",    glyph = "󰖈", hl = "MiniIconsGo" },
                    { name = "rs",    glyph = "󰖇", hl = "MiniIconsRs" },
                    { name = "c",     glyph = "󰉞", hl = "MiniIconsC" },
                    { name = "cpp",   glyph = "󰉞", hl = "MiniIconsCpp" },
                    -- Config
                    { name = "json",  glyph = "󰊄", hl = "MiniIconsJson" },
                    { name = "yaml",  glyph = "󰊄", hl = "MiniIconsYaml" },
                    { name = "toml",  glyph = "󰊄", hl = "MiniIconsToml" },
                    { name = "lua",   glyph = "󰓆", hl = "MiniIconsLua" },
                    -- Web
                    { name = "html",  glyph = "󰊅", hl = "MiniIconsHtml" },
                    { name = "css",   glyph = "󰊂", hl = "MiniIconsCss" },
                    { name = "scss",  glyph = "󰊂", hl = "MiniIconsScss" },
                    -- Docs
                    { name = "md",    glyph = "󰊑", hl = "MiniIconsMd" },
                    { name = "txt",   glyph = "󰊓", hl = "MiniIconsTxt" },
                    { name = "pdf",   glyph = "󰊒", hl = "MiniIconsPdf" },
                },
                
                -- Filetypes (common ones)
                filetypes = {
                    { name = "lua",       glyph = "󰓆", hl = "MiniIconsLua" },
                    { name = "javascript", glyph = "󰊄", hl = "MiniIconsJs" },
                    { name = "typescript", glyph = "󰊆", hl = "MiniIconsTs" },
                    { name = "python",     glyph = "󰊏", hl = "MiniIconsPy" },
                    { name = "rust",       glyph = "󰖇", hl = "MiniIconsRs" },
                    { name = "go",         glyph = "󰖈", hl = "MiniIconsGo" },
                    { name = "c",          glyph = "󰉞", hl = "MiniIconsC" },
                    { name = "cpp",        glyph = "󰉞", hl = "MiniIconsCpp" },
                },
                
                -- LSP (diagnostic icons)
                lsp = {
                    { name = "Error",       glyph = "󰅚", hl = "MiniIconsLspError" },
                    { name = "Warning",     glyph = "󰀲", hl = "MiniIconsLspWarning" },
                    { name = "Information", glyph = "󰋽", hl = "MiniIconsLspInfo" },
                    { name = "Hint",        glyph = "󰌶", hl = "MiniIconsLspHint" },
                },
            },
        })
        
        -- ════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("MiniIconsHighlights", { clear = true }),
            callback = function()
                -- Default (gruvbox gray)
                vim.api.nvim_set_hl(0, "MiniIconsDefault", { fg = "#a89984", nocombine = true })
                
                -- File extensions (gruvbox colors)
                vim.api.nvim_set_hl(0, "MiniIconsJs",    { fg = "#fabd2f", nocombine = true }) -- JS: yellow
                vim.api.nvim_set_hl(0, "MiniIconsTs",    { fg = "#fabd2f", nocombine = true }) -- TS: yellow
                vim.api.nvim_set_hl(0, "MiniIconsJsx",   { fg = "#fabd2f", nocombine = true }) -- JSX: yellow
                vim.api.nvim_set_hl(0, "MiniIconsLua",   { fg = "#458588", nocombine = true }) -- Lua: blue
                vim.api.nvim_set_hl(0, "MiniIconsPy",    { fg = "#458588", nocombine = true }) -- Python: blue
                vim.api.nvim_set_hl(0, "MiniIconsGo",    { fg = "#458588", nocombine = true }) -- Go: blue
                vim.api.nvim_set_hl(0, "MiniIconsRs",    { fg = "#458588", nocombine = true }) -- Rust: blue
                vim.api.nvim_set_hl(0, "MiniIconsC",     { fg = "#458588", nocombine = true }) -- C: blue
                vim.api.nvim_set_hl(0, "MiniIconsCpp",  { fg = "#458588", nocombine = true }) -- C++: blue
                vim.api.nvim_set_hl(0, "MiniIconsHtml",  { fg = "#fb4934", nocombine = true }) -- HTML: red
                vim.api.nvim_set_hl(0, "MiniIconsCss",   { fg = "#b16286", nocombine = true }) -- CSS: purple
                vim.api.nvim_set_hl(0, "MiniIconsJson",  { fg = "#fb4934", nocombine = true }) -- JSON: red
                vim.api.nvim_set_hl(0, "MiniIconsYaml",  { fg = "#fb4934", nocombine = true }) -- YAML: red
                vim.api.nvim_set_hl(0, "MiniIconsMd",    { fg = "#b8bb26", nocombine = true }) -- MD: green
                vim.api.nvim_set_hl(0, "MiniIconsTxt",   { fg = "#a89984", nocombine = true }) -- TXT: gray
                vim.api.nvim_set_hl(0, "MiniIconsPdf",   { fg = "#fb4934", nocombine = true }) -- PDF: red
                vim.api.nvim_set_hl(0, "MiniIconsScss",  { fg = "#b16286", nocombine = true }) -- SCSS: purple
                vim.api.nvim_set_hl(0, "MiniIconsToml",  { fg = "#fb4934", nocombine = true }) -- TOML: red
                
                -- LSP (gruvbox diagnostic colors)
                vim.api.nvim_set_hl(0, "MiniIconsLspError",    { fg = "#fb4934", bold = true, nocombine = true }) -- red
                vim.api.nvim_set_hl(0, "MiniIconsLspWarning",  { fg = "#fabd2f", nocombine = true }) -- yellow
                vim.api.nvim_set_hl(0, "MiniIconsLspInfo",     { fg = "#83a598", nocombine = true }) -- blue
                vim.api.nvim_set_hl(0, "MiniIconsLspHint",     { fg = "#8ec07c", nocombine = true }) -- green
            end,
        })
        
        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
