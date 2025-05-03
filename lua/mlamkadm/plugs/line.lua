return {
    "sontungexpt/sttusline",
    event = "VeryLazy",
    dependencies = {
        "nvim-tree/nvim-web-devicons", -- Optional but recommended for icons
    },
    opts = {
        -- Statusline general configuration
        statusline_color = "StatusLine",
        laststatus = 3, -- Global statusline

        -- Disable statusline for specific filetypes/buftypes
        disabled = {
            filetypes = {
                -- Add filetypes where you don't want the statusline
                "NvimTree",
                "TelescopePrompt",
                "alpha",
                "dashboard",
            },
            buftypes = {
                -- Add buftypes where you don't want the statusline
                "terminal",
                "prompt",
                "nofile",
            },
        },

        -- Statusline components configuration
        components = {
            "mode",                -- Vim mode (Normal, Insert, Visual, etc.)
            "filename",            -- Current file name
            "git-branch",          -- Git branch name
            "git-diff",            -- Git changes (added, modified, removed)
            "%=",                  -- Align the rest to the right
            "diagnostics",         -- LSP diagnostics
            "lsps-formatters",     -- Active LSP clients and formatters
            -- "copilot",             -- GitHub Copilot status
            "indent",              -- Indentation settings
            "encoding",            -- File encoding
            "pos-cursor",          -- Cursor position (line:column)
            "pos-cursor-progress", -- File progress percentage
        },

        -- Customize component settings
        -- mode = {
        --     colors = {
        --         NORMAL = "#8aadf4",
        --         INSERT = "#a6da95",
        --         VISUAL = "#ed8796",
        --         V_LINE = "#ed8796",
        --         V_BLOCK = "#ed8796",
        --         REPLACE = "#f5a97f",
        --         COMMAND = "#c6a0f6",
        --         TERMINAL = "#a6da95",
        --         SELECT = "#ed8796",
        --     },
        -- },

        -- Filename component configuration
        filename = {
            full_path = false,    -- Show full path
            path_sep = "/",       -- Path separator
            shorting_target = 40, -- Maximum filename length
            exclude_prefix = {    -- Excluded path prefixes
                "~",
                vim.fn.getcwd(),
            },
        },

        -- Git components configuration
        -- git = {
        --     branch = {
        --         format = "%s", -- Branch format
        --     },
        --     diff = {
        --         added = {
        --             hl = "DiffAdd",
        --         },
        --         modified = {
        --             hl = "DiffChange",
        --         },
        --         removed = {
        --             hl = "DiffDelete",
        --         },
        --     },
        -- },

        -- LSP configuration
        lsp = {
            diagnostics = {
                errors = { icon = " ", hl = "DiagnosticError" },
                warnings = { icon = " ", hl = "DiagnosticWarn" },
                info = { icon = " ", hl = "DiagnosticInfo" },
                hints = { icon = "󰌵 ", hl = "DiagnosticHint" },
            },
            formatter = {
                icon = "󰉼 ", -- Formatter icon
                format = "%s", -- Format string
            },
        },


        indent = {
            icon = "󰌒 ", -- Indent icon
            format = "%s spaces", -- Format string
        },

        encoding = {
            icon = "󰘦 ", -- Encoding icon
            exclude = { -- Excluded encodings
                "utf-8",
            },
        },

        position = {
            icon = "󰆥 ", -- Position icon
            format = "%l:%c", -- Position format
            progress_icon = "󰜎 ", -- Progress icon
        },
    },
    config = function(_, opts)
        -- Setup statusline
        require("sttusline").setup(opts)


        -- Add autocommands for dynamic updates
        vim.api.nvim_create_autocmd("User", {
            pattern = "GitSignsUpdate",
            callback = function()
                vim.cmd("redrawstatus")
            end,
        })

        -- Custom command to toggle statusline
        vim.api.nvim_create_user_command("ToggleStatusline", function()
            if vim.o.laststatus == 3 then
                vim.o.laststatus = 0
            else
                vim.o.laststatus = 3
            end
        end, {})

        -- Example keymaps for statusline control
        vim.keymap.set("n", "<leader>ts", ":ToggleStatusline<CR>", { silent = true, desc = "Toggle Statusline" })
    end,
}
