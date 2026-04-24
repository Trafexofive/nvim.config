-- comment.nvim - Better commenting (v3 API)
-- Zen: Invisible until used, no UI, just works
return {
    "numToStr/Comment.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
        require("Comment").setup({
            -- ════════════════════════════════
            -- Zen Mode: Invisible until you comment
            -- ════════════════════════════════
            -- Padding (subtle, not distracting)
            padding_left = " ",
            padding_right = " ",
            
            -- Ignore certain filetypes (zen: no interference)
            ignore = "^$",
            
            -- Toggler (standard behavior)
            toggler = {
                line = "gcc",
                block = "gbc",
            },
            opleader = {
                line = "gc",
                block = "gb",
            },
            
            -- Extra mappings (minimal, standard)
            extra = {
                above = "gco",
                below = "gcb",
                eol = "gcA",
            },
            
            -- Treesitter integration (enhanced commenting)
            pre_hook = function(ctx)
                local ok, ts_context_commentstring = pcall(require, "ts_context_commentstring")
                if not ok then return end
                
                local uopts = ts_context_commentstring.calculate_commentstring({
                    bufnr = ctx.bufnr,
                    lnum = ctx.range.srow,
                })
                
                if uopts then
                    ctx.ctype = uopts.ctype
                    ctx.cmtstring = uopts.cmtstring
                end
            end,
        })
        
        -- ════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ════════════════════════════════
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("CommentHighlights", { clear = true }),
            callback = function()
                vim.api.nvim_set_hl(0, "Comment", {
                    fg = "#928374",
                    italic = true,
                    nocombine = true
                })
            end,
        })
        
        vim.cmd("doautocmd ColorScheme")
    end,
}
