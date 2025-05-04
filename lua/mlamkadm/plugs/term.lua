-- lua/mlamkadm/plugs/term.lua
return {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
        require("toggleterm").setup {
            -- Your full config from core/terminal.lua
            size = function(term)
                if term.direction == "horizontal" then
                    return 15
                elseif term.direction == "vertical" then
                    return vim.o.columns * 0.4
                else          -- Float
                    return 50 -- Keep your original float size
                end
            end,
            open_mapping = [[<c-t>]], -- Changed from <c-\>
            hide_numbers = true,
            shade_filetypes = {},
            autochdir = true,
            shade_terminals = true,
            start_in_insert = true,
            insert_mappings = true, -- Allow mapping in insert mode
            terminal_mappings = true,
            persist_size = true,
            direction = 'float', -- Keep float as default
            close_on_exit = true,
            float_opts = {
                border = 'curved',
                -- winblend = 0, -- Remove default winblend if you set it per terminal
            },
            -- Add other options from core/terminal.lua
        }

        -- Define terminal helper function and keymaps here
        local Terminal = require('toggleterm.terminal').Terminal

        local function get_term(cmd, opts)
            local default_opts = {
                cmd = cmd,
                dir = "git_dir",
                direction = "float",
                float_opts = {
                    border = "curved",
                    winblend = 3, -- Default transparency
                },
                shade_terminals = true,
                hidden = true, -- Create hidden initially
                on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<esc>", "<cmd>close<CR>",
                        { noremap = true, silent = true })
                end,
                on_close = function(term)
                    -- Actions on close if needed
                end,
            }
            return Terminal:new(vim.tbl_deep_extend("force", default_opts, opts or {}))
        end

        function Poptui(cmd, opts)
            local term = get_term(cmd, opts)
            term:toggle()
        end

        -- Your keymaps using Poptui
        vim.keymap.set("n", "<leader>jh",
            function()
                Poptui(
                    "python3 /home/mlamkadm/repos/IRC-TUI-python/irc_tui.py --password Alilepro135! --user testuser --port 16000 --nick testnick --real testreal")
            end,
            { desc = "Toggle IRC TUI" })
        vim.keymap.set("n", "<leader>jj", function() Poptui('lazygit') end, { desc = "Toggle Lazygit" })
        vim.keymap.set("n", "<leader>jt", function() Poptui('btop') end, { desc = "Toggle Btop" })
        vim.keymap.set("n", "<leader>jd", function() Poptui('lazydocker') end, { desc = "Toggle Lazydocker" })
        vim.keymap.set("n", "<leader>jy", function() Poptui('yazi') end, { desc = "Toggle Yazi" })
        vim.keymap.set("n", "<leader>ja", function() Poptui('ai') end, { desc = "Toggle AI Shell" })
        vim.keymap.set("n", "<leader>jg", function() Poptui("glow " .. vim.fn.expand("%")) end,
            { desc = "Toggle Glow Preview" })
        -- vim.keymap.set("n", "<leader>jo", function() Poptui("md-tui " .. vim.fn.expand("%")) end, { desc = "Toggle md-tui Preview" }) -- If md-tui is installed

        -- Makefile keymaps
        vim.keymap.set("n", "<leader>mr", function() Poptui('make run') end, { desc = "Makefile Run" })
        vim.keymap.set("n", "<leader>mm", function() Poptui('make') end, { desc = "Makefile Build" })         -- Changed from jm -> mm
        vim.keymap.set("n", "<leader>mc", function() Poptui('make clean') end, { desc = "Makefile Clean" })   -- Example for clean
        vim.keymap.set("n", "<leader>mf", function() Poptui('make fclean') end, { desc = "Makefile Fclean" }) -- Example for fclean

        -- Terminal specific keymap (remapped from init.lua)
        -- This maps Escape in Terminal mode back to Normal mode *within the terminal*
        -- To exit ToggleTerm completely use the open_mapping (<c-t>) again or map another key
        vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { desc = "Terminal Normal Mode" })

        -- Autocmd for stopping job (moved from init.lua)
        vim.api.nvim_create_autocmd("TermClose", {
            pattern = "term://*", -- Apply to all terminals
            callback = function(args)
                -- Check if it's a toggleterm terminal before trying to stop job
                -- This is a bit tricky, might need more robust check depending on toggleterm internals
                if args.buf and vim.bo[args.buf].term_job_id then
                    vim.cmd("silent! call jobstop(" .. vim.bo[args.buf].term_job_id .. ")")
                end
            end,
        })
    end
}
