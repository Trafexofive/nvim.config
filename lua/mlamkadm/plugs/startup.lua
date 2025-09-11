return {
    'goolord/alpha-nvim',
    event = "VimEnter",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function ()
        local alpha = require('alpha')
        local dashboard = require('alpha.themes.dashboard')

        -- Minimal header
        dashboard.section.header.val = {
            '██████╗ ███████╗██████╗  ██████╗███████╗ ██████╗',
            '██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝',
            '██║  ██║█████╗  ██║  ██║██║     █████╗  ██║     ',
            '██║  ██║██╔══╝  ██║  ██║██║     ██╔══╝  ██║     ',
            '██████╔╝███████╗██████╔╝╚██████╗███████╗╚██████╗',
            '╚═════╝ ╚══════╝╚═════╝  ╚═════╝╚══════╝ ╚═════╝',
        }

        -- Minimal buttons
        dashboard.section.buttons.val = {
            dashboard.button('q', '  Quit', '<cmd>qa<cr>')
        }

        -- Minimal footer
        dashboard.section.footer.val = ""

        -- Set up alpha with the minimal dashboard config
        alpha.setup(dashboard.opts)
    end
}