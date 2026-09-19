-- comment.nvim - Better commenting (v3 API)
-- Zen: Invisible until used, no UI, just works
return {
    "numToStr/Comment.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
        local ok_hook, hook = pcall(require, "ts_context_commentstring.integrations.comment_nvim")

        require("Comment").setup({
            -- Zen Mode: invisible until used; keep Comment.nvim defaults where possible.
            padding = true,
            sticky = true,
            ignore = nil,

            toggler = {
                line = "gcc",
                block = "gbc",
            },
            opleader = {
                line = "gc",
                block = "gb",
            },
            extra = {
                above = "gcO",
                below = "gco",
                eol = "gcA",
            },
            mappings = {
                basic = true,
                extra = true,
            },

            -- Correct Comment.nvim integration: return a commentstring instead of
            -- mutating ctx fields. This keeps JSX/TSX/etc. context-aware comments.
            pre_hook = ok_hook and hook.create_pre_hook() or nil,
        })

        -- ════════════════════════════════
        -- Commentstring fallbacks
        -- ════════════════════════════════
        -- Some filetypes ship without a commentstring (the JSON family is
        -- handled in after/ftplugin/{json,jsonc,json5}.lua because their runtime
        -- ftplugin actively clears it). This covers the rest — only applied
        -- when the buffer has no commentstring, so native ones win.
        local commentstring_fallback = {
            graphql = "# %s",
            prisma = "// %s",
            hcl = "# %s",
            -- extend here as needed
        }

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("CommentStringFallback", { clear = true }),
            callback = function()
                local cs = commentstring_fallback[vim.bo.filetype]
                local cur = vim.bo.commentstring
                if cs and (cur == nil or cur == "") then
                    vim.bo.commentstring = cs
                end
            end,
            desc = "Set commentstring for filetypes nvim leaves empty",
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
                    nocombine = true,
                })
            end,
        })

        vim.cmd("doautocmd ColorScheme")
    end,
}
