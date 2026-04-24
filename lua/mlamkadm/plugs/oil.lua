-- oil.nvim - Edit directories like files
-- Zen: Opens in current window, no clutter, just works
return {
    "stevearc/oil.nvim",
    version = "*",
    event = "VeryLazy",
    keys = {
        { "-", "<cmd>Oil --float<CR>", desc = "Open Parent Directory (Float)" },
        { "_", "<cmd>Oil<CR>", desc = "Open Current Directory" },
    },
    opts = {
        -- ══════════════════════════════════════════
        -- Zen Mode: Minimal, clean, no distractions
        -- ══════════════════════════════════════════
        columns = {
            "icon",
            "permissions",
            "size",
            "mtime",
        },
        
        -- Window settings (subtle, not intrusive)
        float = {
            padding = 4,
            max_width = 0.5,
            max_height = 0.5,
            border = "rounded",
            win_options = {
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            },
        },
        
        -- Keymaps (zen: intuitive, minimal)
        keymaps = {
            ["g?"] = "actions.show_help",
            ["<CR>"] = "actions.select",
            ["<C-s>"] = "actions.select_split",
            ["<C-v>"] = "actions.select_vsplit",
            ["<C-t>"] = "actions.select_tab",
            ["<C-p>"] = "actions.preview",
            ["<C-c>"] = "actions.close",
            ["<C-l>"] = "actions.refresh",
            ["-"] = "actions.parent",
            ["_"] = "actions.open_cwd",
            ["`"] = "actions.cd",
            ["~"] = "actions.tcd",
            ["gs"] = "actions.change_sort",
            ["gx"] = "actions.open_external",
            ["g."] = "actions.toggle_hidden",
            ["g\\"] = "actions.toggle_trash",
        },
        
        -- Display settings (clean, minimal)
        show_hidden = false,
        skip_confirm_for_simple_operations = true,
        watch_for_changes = true,
       自然 = false, -- No natural sorting (zen: predictable)
        
        -- Icons (using devicons if available)
        icons = {
            file = { icon = "󰈚", hl = "Normal" },
            folder = { icon = "󰉋", hl = "Directory" },
            folder_open = { icon = "󰉊", hl = "Directory" },
        },
    },
    config = function(_, opts)
        local oil = require("oil")
        oil.setup(opts)
        
        -- ══════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ══════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("OilHighlights", { clear = true }),
            callback = function()
                -- Directory colors (gruvbox blue)
                vim.api.nvim_set_hl(0, "OilDir", { fg = "#458588", bold = true })
                vim.api.nvim_set_hl(0, "OilDirHidden", { fg = "#665c54" })
                
                -- File type colors (gruvbox palette)
                vim.api.nvim_set_hl(0, "OilFile", { fg = "#ebdbb2" })
                vim.api.nvim_set_hl(0, "OilFileHidden", { fg = "#7c6f64" })
                
                -- Special files (gruvbox colors)
                vim.api.nvim_set_hl(0, "OilLink", { fg = "#8ec07c", italic = true }) -- green
                vim.api.nvim_set_hl(0, "OilLinkDir", { fg = "#83a598", italic = true }) -- blue
                vim.api.nvim_set_hl(0, "OilSocket", { fg = "#d3869b" }) -- purple
                vim.api.nvim_set_hl(0, "OilPipe", { fg = "#fabd2f" }) -- yellow
                
                -- Actions/UI (subtle)
                vim.api.nvim_set_hl(0, "OilPrompt", { fg = "#282828", bg = "#fabd2f", bold = true }) -- yellow bg
                vim.api.nvim_set_hl(0, "OilBorder", { fg = "#928374" }) -- gray
            end,
        })
        
        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
