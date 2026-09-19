-- GitSigns - Zenful Git integration
return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        -- ═══════════════════════════════════════════════════════
        -- Subtle Signs (thin, minimal distraction)
        -- ═══════════════════════════════════════════════════════
        signs = {
            add = { text = "│", hl = "GitSignsAdd" },
            change = { text = "│", hl = "GitSignsChange" },
            delete = { text = " ", hl = "GitSignsDelete" },
            topdelete = { text = "‾", hl = "GitSignsDelete" },
            changedelete = { text = "~", hl = "GitSignsChange" },
            untracked = { text = "┆", hl = "GitSignsUntracked" },
        },
        signs_staged = {
            add = { text = "│", hl = "GitSignsStagedAdd" },
            change = { text = "│", hl = "GitSignsStagedChange" },
            delete = { text = " ", hl = "GitSignsStagedDelete" },
            topdelete = { text = "‾", hl = "GitSignsStagedDelete" },
            changedelete = { text = "~", hl = "GitSignsStagedChange" },
        },
        signs_staged_enable = true,

        -- ═══════════════════════════════════════════════════════
        -- Minimal UI (zen mode)
        -- ═══════════════════════════════════════════════════════
        signcolumn = true, -- Show signs in signcolumn only
        numhl = false, -- No number highlights (cleaner)
        linehl = false, -- No line highlights (distraction-free)
        word_diff = false, -- No word-level diff (performance + zen)

        -- Current line blame (disabled by default)
        current_line_blame = false,
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = "eol", -- Show at end of line
            delay = 500, -- Faster response
            ignore_whitespace = false,
        },

        -- ═══════════════════════════════════════════════════════
        -- Performance & Behavior
        -- ═══════════════════════════════════════════════════════
        watch_gitdir = { follow_files = true },
        auto_attach = true,
        attach_to_untracked = true,
        sign_priority = 6, -- Lower than diagnostics
        update_debounce = 200, -- Slightly slower for performance
        status_formatter = nil, -- Use default
        max_file_length = 50000, -- Increased threshold

        -- ═══════════════════════════════════════════════════════
        -- Preview window (minimal)
        -- ═══════════════════════════════════════════════════════
        preview_config = {
            border = "rounded",
            style = "minimal",
            relative = "cursor",
            row = 1,
            col = 0,
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- Essential Keymaps (zen-optimized)
    -- ═══════════════════════════════════════════════════════
    keys = {
        -- Hunk operations
        {
            "]h",
            function()
                require("gitsigns.actions").next_hunk()
            end,
            desc = "Next Hunk",
        },
        {
            "[h",
            function()
                require("gitsigns.actions").prev_hunk()
            end,
            desc = "Prev Hunk",
        },
        { "<leader>hs", "<cmd>GitSigns stage_hunk<CR>", desc = "Stage Hunk" },
        { "<leader>hr", "<cmd>GitSigns reset_hunk<CR>", desc = "Reset Hunk" },
        { "<leader>hp", "<cmd>GitSigns preview_hunk<CR>", desc = "Preview Hunk" },

        -- Buffer operations
        { "<leader>gS", "<cmd>GitSigns stage_buffer<CR>", desc = "Stage Buffer" },
        { "<leader>gU", "<cmd>GitSigns undo_stage_buffer<CR>", desc = "Undo Stage" },
        { "<leader>gR", "<cmd>GitSigns reset_buffer<CR>", desc = "Reset Buffer" },

        -- Toggle features
        { "<leader>gb", "<cmd>GitSigns toggle_current_line_blame<CR>", desc = "Toggle Blame" },
        { "<leader>gd", "<cmd>GitSigns toggle_linehl<CR>", desc = "Toggle Line HL" },
        { "<leader>gD", "<cmd>GitSigns toggle_word_diff<CR>", desc = "Toggle Word Diff" },
    },

    -- ═══════════════════════════════════════════════════════
    -- Config with Gruvbox-colored highlights
    -- ═══════════════════════════════════════════════════════
    config = function(_, opts)
        require("gitsigns").setup(opts)

        -- Add subtle highlights for gitsigns (gruvbox colors, subtle)
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("GitSignsHighlights", { clear = true }),
            callback = function()
                -- Subtle colors that don't distract (gruvbox palette)
                vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#689d6a", bg = "NONE" }) -- gruvbox green (dim)
                vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#d79921", bg = "NONE" }) -- gruvbox yellow
                vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#cc241d", bg = "NONE" }) -- gruvbox red
                vim.api.nvim_set_hl(0, "GitSignsUntracked", { fg = "#7c6f64", bg = "NONE" }) -- gruvbox gray

                -- Staged variants (slightly brighter)
                vim.api.nvim_set_hl(0, "GitSignsStagedAdd", { fg = "#98971a", bg = "NONE" }) -- brighter green
                vim.api.nvim_set_hl(0, "GitSignsStagedChange", { fg = "#fabd2f", bg = "NONE" }) -- brighter yellow
                vim.api.nvim_set_hl(0, "GitSignsStagedDelete", { fg = "#fb4934", bg = "NONE" }) -- brighter red
            end,
        })

        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
