return {
    'goolord/alpha-nvim',
    event = "VimEnter",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function ()
        local alpha = require('alpha')
        local dashboard = require('alpha.themes.dashboard')

        -- ASCII Art Header
        dashboard.section.header.val = {
            '██████╗ ███████╗██████╗  ██████╗███████╗ ██████╗',
            '██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝',
            '██║  ██║█████╗  ██║  ██║██║     █████╗  ██║     ',
            '██║  ██║██╔══╝  ██║  ██║██║     ██╔══╝  ██║     ',
            '██████╔╝███████╗██████╔╝╚██████╗███████╗╚██████╗',
            '╚═════╝ ╚══════╝╚═════╝  ╚═════╝╚══════╝ ╚═════╝',
        }

        -- Buttons
        dashboard.section.buttons.val = {
            dashboard.button('f', '  Find file', ':Telescope find_files<CR>'),
            dashboard.button('r', '  Recent files', ':Telescope oldfiles<CR>'),
            dashboard.button('g', '  Find text', ':Telescope live_grep<CR>'),
            dashboard.button('s', '  Restore Session', function()
                local ok, session = pcall(require, "auto-session.lib")
                if ok and session.RestoreLastSession then
                    session.RestoreLastSession()
                else
                    vim.notify("auto-session not available", vim.log.levels.WARN)
                end
            end),
            dashboard.button('l', '鈴  Lazy', '<cmd>Lazy<cr>'),
            dashboard.button('q', '  Quit', '<cmd>qa<cr>')
        }

        -- Footer
        dashboard.section.footer.val = "“Our democracy has been hacked.” - Mr. Robot"

        -- Layout
        dashboard.config.layout = {
            { type = 'padding', val = 2 },
            { type = 'header' },
            { type = 'padding', val = 2 },
            { type = 'buttons' },
            { type = 'padding', val = 1 },
            { type = 'footer' }
        }
        
        -- Set custom highlights
        local highlights = {
            AlphaHeader   = { fg = '#00FFFF' }, -- Cyan
            AlphaButtons  = { fg = '#FFFFFF' }, -- White
            AlphaFooter   = { fg = '#FF0000' }, -- Red
            AlphaShortcut = { fg = '#FF00FF' }, -- Magenta
        }
        
        for group, hl in pairs(highlights) do
            vim.api.nvim_set_hl(0, group, hl)
        end

        -- Set up alpha
        alpha.setup(dashboard.opts)

        -- autocmd to close alpha if it's not the last window
        vim.api.nvim_create_autocmd('BufEnter', {
            pattern = '*',
            callback = function()
                local bufnr = vim.api.nvim_get_current_buf()
                if vim.bo[bufnr].filetype ~= 'alpha' and #vim.api.nvim_list_wins() > 1 then
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].filetype == 'alpha' then
                            vim.api.nvim_win_close(win, true)
                        end
                    end
                end
            end
        })
    end
}