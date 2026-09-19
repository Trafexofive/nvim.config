-- trouble.nvim - Clean diagnostic list
-- Zen: Auto_open = false, only show when you need it
return {
    "folke/trouble.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    keys = {
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
        { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
        { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
        { "<leader>xS", "<cmd>Trouble lsp_workspace_symbols toggle<cr>", desc = "LSP Workspace Symbols (Trouble)" },
        { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
        { "<leader>xq", "<cmd>Trouble quickfix toggle<cr>", desc = "Quickfix List (Trouble)" },
        { "<leader>xr", "<cmd>Trouble lsp_references toggle<cr>", desc = "LSP References (Trouble)" },
        { "<leader>xL", "<cmd>Trouble todo toggle<cr>", desc = "Todo List (Trouble)" },
    },
    opts = {
        -- ══════════════════════════════════════════
        -- Zen Mode: Don't auto-open, only on demand
        -- ══════════════════════════════════════════
        auto_open = false, -- Manual trigger only (zen!)
        auto_close = true,
        auto_preview = true,
        auto_fold = true, -- Auto-fold groups

        -- Position & Size (subtle, not intrusive)
        position = "bottom", -- Show at bottom (less distraction)
        height = 10, -- Compact height
        width = 50, -- For side positions
        mode = "workspace_diagnostics", -- Default mode

        -- Components (minimal, clean)
        components = {
            icon = true, -- Show icons
            filename = true, -- Show filename
            directory = false, -- Hide directory (less noise)
            lnum = true, -- Show line number
            col = false, -- Hide column (cleaner)
            virt_text = true, -- Show virtual text in buffer
            code = true, -- Show code preview
        },

        -- Severity filter (show all by default)
        severity = nil, -- vim.diagnostic.severity.ERROR,

        -- ══════════════════════════════════════════
        -- UI: Gruvbox-themed, subtle
        -- ══════════════════════════════════════════
        icons = {
            code_action = "󰌵",
            current_line = "󱞋",
            folder_closed = "󰀼",
            folder_open = "󰀽",
            indent = "  ",
            last_indent = "  ",
            indent_marker = "│",
            -- Severity icons (gruvbox colors)
            error = "󰅚",
            warning = "󰀲",
            info = "󰋽",
            hint = "󰌶",
        },

        -- LSP signs (matching gitsigns style)
        signs = {
            error = "󰅚",
            warning = "󰀲",
            hint = "󰌶",
            infomation = "󰋽",
            other = "󰞫",
        },

        -- Keymaps (zen: minimal, intuitive)
        action_keys = {
            close = "q", -- Close trouble
            cancel = "<esc>", -- Cancel action
            refresh = "r", -- Refresh list
            jump = { "<cr>", "<tab>" }, -- Jump to item
            toggle_mode = "m", -- Toggle mode
            switch_win = "o", -- Switch to trouble window
            preview = "p", -- Toggle preview
            close_folds = "zM", -- Close all folds
            open_folds = "zR", -- Open all folds
            toggle_fold = "zA", -- Toggle fold
            previous = "k", -- Previous item
            next = "j", -- Next item
        },

        -- Window options (rounded border, subtle)
        win_options = {
            winhighlight = "Normal:TroubleNormal,NormalNC:TroubleNormalNC,CursorLine:TroubleCursorLine,FloatBorder:TroubleBorder",
            wrap = false,
        },
    },
    config = function(_, opts)
        require("trouble").setup(opts)

        -- ══════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ══════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("TroubleHighlights", { clear = true }),
            callback = function()
                -- Normal text (gruvbox fg1)
                vim.api.nvim_set_hl(0, "TroubleNormal", { fg = "#ebdbb2", bg = "#3c3836" })
                vim.api.nvim_set_hl(0, "TroubleNormalNC", { fg = "#a89984", bg = "#282828" })

                -- Cursor line (gruvbox bg3, subtle)
                vim.api.nvim_set_hl(0, "TroubleCursorLine", { bg = "#665c54" })

                -- Signs (gruvbox colors)
                vim.api.nvim_set_hl(0, "TroubleError", { fg = "#fb4934", bold = true }) -- red
                vim.api.nvim_set_hl(0, "TroubleWarning", { fg = "#fabd2f", bold = true }) -- yellow
                vim.api.nvim_set_hl(0, "TroubleInformation", { fg = "#83a598" }) -- blue
                vim.api.nvim_set_hl(0, "TroubleHint", { fg = "#8ec07c" }) -- green

                -- Border (gruvbox gray)
                vim.api.nvim_set_hl(0, "TroubleBorder", { fg = "#928374", bg = "#3c3836" })

                -- Preview (subtle)
                vim.api.nvim_set_hl(0, "TroublePreview", { bg = "#3c3836" })
            end,
        })

        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
