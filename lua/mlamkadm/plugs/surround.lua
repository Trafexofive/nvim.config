-- nvim-surround - Surround text with brackets, quotes, tags
-- Zen: Invisible until you use it, no UI, just works
return {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup({
            -- Keymaps (zen: use default, no extra UI)
            keymaps = {
                insert = '<C-g>s',
                insert_line = '<C-g>S',
                normal = 's',
                normal_cur_line = 'S',
                visual = 's',
                visual_line = 'gS',
                delete = 'ds',
                change = 'cs',
            },
            
            -- Surrounders (add your own as needed)
            -- Default: brackets, quotes, tags, etc.
            delimiters = {
                -- Brackets and quotes
                { id = 'a', trigger = 'a', pair = { '<>', '<>' } }, -- Angle brackets
                { id = 'b', trigger = 'b', pair = { '{ ', ' }' } }, -- Curly brackets with space
                { id = 'B', trigger = 'B', pair = { '{', '}' } }, -- Curly brackets
                { id = 'r', trigger = 'r', pair = { '[ ', ' ]' } }, -- Square brackets with space
                { id = 'R', trigger = 'R', pair = { '[', ']' } }, -- Square brackets
                { id = 'q', trigger = 'q', pair = { '"', '"' } }, -- Double quotes
                { id = 'Q', trigger = 'Q', pair = { "'", "'" } }, -- Single quotes
                { id = 'g', trigger = 'g', pair = { '`', '`' } }, -- Backticks
                
                -- Aliases for common pairs
                { id = '(', pair = { '(', ')' } },
                { id = '{', pair = { '{', '}' } },
                { id = '[', pair = { '[', ']' } },
                { id = '<', pair = { '<', '>' } },
                { id = '"', pair = { '"', '"' } },
                { id = "'", pair = { "'", "'" } },
                { id = '`', pair = { '`', '`' } },
            },
            
            -- Treesitter integration (enhanced delimiters)
            treesitter = {
                -- Enable treesitter-based surrounding
                enable = true,
            },
        })
    end,
}
