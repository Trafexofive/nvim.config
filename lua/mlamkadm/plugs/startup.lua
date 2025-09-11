return {
    'goolord/alpha-nvim',
    event = "VimEnter",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function ()
        local alpha = require('alpha')
        local dashboard = require('alpha.themes.dashboard')

        -- Define a command for restoring the session, used by the dashboard button
        vim.api.nvim_create_user_command('RestoreLastSessionAlpha', function()
            -- pcall to safely require auto-session, as it might be lazy-loaded
            local ok, session = pcall(require, "auto-session")
            if ok and session.RestoreLastSession then
                session.RestoreLastSession()
            else
                vim.notify("auto-session is not available to restore session.", vim.log.levels.WARN)
            end
        end, {})

        -- Set theme colors
        local highlights = {
            AlphaHeader   = { fg = '#00FFFF' }, -- Cyan
            AlphaButtons  = { fg = '#FFFFFF' }, -- White
            AlphaFooter   = { fg = '#FF0000' }, -- Red
            AlphaShortcut = { fg = '#FF00FF' }, -- Magenta
        }
        for group, hl in pairs(highlights) do
            vim.api.nvim_set_hl(0, group, hl)
        end

        -- DedSec ASCII Art Header
        dashboard.section.header.val = {
            '██████╗ ███████╗██████╗  ██████╗███████╗ ██████╗',
            '██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝',
            '██║  ██║█████╗  ██║  ██║██║     █████╗  ██║     ',
            '██║  ██║██╔══╝  ██║  ██║██║     ██╔══╝  ██║     ',
            '██████╔╝███████╗██████╔╝╚██████╗███████╗╚██████╗',
            '╚═════╝ ╚══════╝╚═════╝  ╚═════╝╚══════╝ ╚═════╝',
        }
        dashboard.section.header.opts.hl = "AlphaHeader"

        -- Buttons for common actions
        dashboard.section.buttons.val = {
            dashboard.button('f', '  Find file', ':Telescope find_files<CR>'),
            dashboard.button('r', '  Recent files', ':Telescope oldfiles<CR>'),
            dashboard.button('g', '  Find text', ':Telescope live_grep<CR>'),
            dashboard.button('s', '  Restore Session', '<cmd>RestoreLastSessionAlpha<CR>'),
            dashboard.button('l', '鈴  Lazy', '<cmd>Lazy<cr>'),
            dashboard.button('q', '  Quit', '<cmd>qa<cr>')
        }
        dashboard.section.buttons.opts.hl = "AlphaButtons"

        -- Footer with a quote
        dashboard.section.footer.val = "“Our democracy has been hacked.” - Mr. Robot"
        dashboard.section.footer.opts.hl = "AlphaFooter"

        -- Layout configuration
        dashboard.config.layout = {
            { type = 'padding', val = 2 },
            { type = 'header' },
            { type = 'padding', val = 2 },
            { type = 'buttons' },
            { type = 'padding', val = 1 },
            { type = 'footer' }
        }

        alpha.setup(dashboard.opts)

        -- autocmd to close alpha if it's not the last window
        vim.api.nvim_create_autocmd('BufEnter', {
            pattern = '*',
            callback = function()
                -- Check if the buffer is not alpha and there's more than one window
                if vim.bo.filetype ~= 'alpha' and #vim.api.nvim_list_wins() > 1 then
                    -- Find and close the alpha window
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].filetype == 'alpha' then
                            vim.api.nvim_win_close(win, true)
                            break
                        end
                    end
                end
            end
        })
    end,
}
