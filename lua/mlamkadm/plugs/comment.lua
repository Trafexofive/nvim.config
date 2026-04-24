-- comment.nvim - Better commenting
-- Zen: Invisible until used, no UI, just works
return {
    "numToStr/Comment.nvim",
    version = "*",
    event = "VeryLazy",
    keys = {
        -- Use default keymaps (zen: standard, intuitive)
        -- gcc: toggle line comment
        -- gc: toggle motion comment
        -- gbc: toggle block comment
        -- gb: (visual) block comment
    },
    config = function()
        require("Comment").setup({
            -- ══════════════════════════════════════════
            -- Zen Mode: Invisible until you comment
            -- ══════════════════════════════════════════
            -- Padding (subtle, not distracting)
            padding_left = " " (one space)
            padding_right = " " (one space)
            
            -- Ignore certain filetypes (zen: no interference)
            ignore = "^$", -- Ignore empty lines
            
            -- Toggler (standard behavior)
            toggler = "gcc",
            line = "gc",
            block = "gb",
            
            -- Extra mappings (minimal, standard)
            extra = {
                -- Add comment/uncomment with same mapping
                above = "gco", -- Comment above
                below = "gcb", -- Comment below
                eol = "gcA", -- Comment at end of line
            },
            
            -- Treesitter integration (enhanced commenting)
            pre_hook = function(ctx)
                -- Only use treesitter if available
                local ok, ts_context_commentstring = pcall(require, "ts_context_commentstring")
                if not ok then return end
                
                -- Get commentstring based on treesitter context
                local uopts = ts_context_commentstring.calculate_commentstring({
                    bufnr = ctx.bufnr,
                    lnum = ctx.range.srow,
                })
                
                if uopts then
                    ctx.ctype = uopts.ctype
                    ctx.cmtstring = uopts.cmtstring
                end
            end,
            
            -- Post hook (do nothing, zen: no notifications)
            post_hook = nil,
        })
        
        -- ══════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ══════════════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("CommentHighlights", { clear = true }),
            callback = function()
                -- Comment color (gruvbox gray, subtle)
                vim.api.nvim_set_hl(0, "Comment", {
                    fg = "#928374",
                    italic = true,
                    nocombine = true
                })
                
                -- Optional: make comments slightly dimmer background
                vim.api.nvim_set_hl(0, "CommentSign", {
                    fg = "#7c6f64",
                    nocombine = true
                })
            end,
        })
        
        -- Trigger initial highlight setup
        vim.cmd("doautocmd ColorScheme")
    end,
}
