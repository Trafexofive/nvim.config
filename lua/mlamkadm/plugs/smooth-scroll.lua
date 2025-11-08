return {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
        mappings = {},  -- Disable default mappings, we'll use custom
        hide_cursor = true,
        stop_eof = true,
        respect_scrolloff = false,
        cursor_scrolls_alone = true,
        easing_function = "quadratic",
        performance_mode = false,
    },
    config = function(_, opts)
        require('neoscroll').setup(opts)
        
        -- Custom mappings with neoscroll helper functions
        local neoscroll = require('neoscroll')
        local keymap = {
            ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 250 }) end,
            ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 250 }) end,
            ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 450 }) end,
            ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 450 }) end,
            ["<C-y>"] = function() neoscroll.scroll(-0.1, { move_cursor = false, duration = 100 }) end,
            ["<C-e>"] = function() neoscroll.scroll(0.1, { move_cursor = false, duration = 100 }) end,
            ["zt"] = function() neoscroll.zt({ half_win_duration = 250 }) end,
            ["zz"] = function() neoscroll.zz({ half_win_duration = 250 }) end,
            ["zb"] = function() neoscroll.zb({ half_win_duration = 250 }) end,
        }
        
        local modes = { 'n', 'v', 'x' }
        for key, func in pairs(keymap) do
            vim.keymap.set(modes, key, func)
        end
        
        -- Disable neoscroll for dashboard buffers
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "snacks_dashboard",
            callback = function(event)
                -- Remove neoscroll mappings for this buffer (safely)
                local buf_opts = { buffer = event.buf }
                for key, _ in pairs(keymap) do
                    pcall(vim.keymap.del, 'n', key, buf_opts)
                end
            end,
            desc = "Disable neoscroll in dashboard"
        })
    end
}
