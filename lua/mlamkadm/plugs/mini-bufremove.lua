-- mini.bufremove - Better buffer deletion
-- Zen: No prompts, just works, preserves layout
return {
    "echasnovski/mini.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
        local bufremove = require("mini.bufremove")
        
        bufremove.setup({
            -- ══════════════════════════════════════════
            -- Zen Mode: Silent, no prompts, preserve layout
            -- ══════════════════════════════════════════
            force = true, -- Force delete (no save prompt, zen!)
            setowy = 10, -- Don't delete other buffers in window (preserve layout)
        })
        
        -- ══════════════════════════════════════════
        -- Keymaps (intuitive, zen: no clutter)
        -- ══════════════════════════════════════════
        vim.keymap.set("n", "<leader>bd", function()
            bufremove.delete(0, false) -- Delete current buffer, don't force
        end, { desc = "Delete Buffer (preserve layout)" })
        
        vim.keymap.set("n", "<leader>bD", function()
            bufremove.delete(0, true) -- Force delete (no save)
        end, { desc = "Force Delete Buffer" })
        
        vim.keymap.set("n", "<leader>bw", function()
            bufremove.wipeout(0, false) -- Wipe buffer (clear from buffer list)
        end, { desc = "Wipe Buffer" })
        
        -- ══════════════════════════════════════════
        -- Gruvbox-themed highlights (subtle, zenful)
        -- ══════════════════════════════════════════
        -- Note: mini.bufremove doesn't have custom highlights
        -- It uses default Neovim behavior (zen: no distractions)
    end,
}
