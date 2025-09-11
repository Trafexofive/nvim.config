return {
  'goolord/alpha-nvim',
  event = "VimEnter",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local alpha = require('alpha')
    local dashboard = require('alpha.themes.dashboard') -- Using dashboard's button component

    -- Re-define command to be safe on reload
    pcall(vim.api.nvim_del_user_command, 'RestoreLastSessionAlpha')
    vim.api.nvim_create_user_command('RestoreLastSessionAlpha', function()
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

    local config = {
      layout = {
        { type = 'padding', val = 2 },
        {
          type = 'text',
          val = {
            '██████╗ ███████╗██████╗  ██████╗███████╗ ██████╗',
            '██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝',
            '██║  ██║█████╗  ██║  ██║██║     █████╗  ██║     ',
            '██║  ██║██╔══╝  ██║  ██║██║     ██╔══╝  ██║     ',
            '██████╔╝███████╗██████╔╝╚██████╗███████╗╚██████╗',
            '╚═════╝ ╚══════╝╚═════╝  ╚═════╝╚══════╝ ╚═════╝',
          },
          opts = { hl = 'AlphaHeader', position = 'center' }
        },
        { type = 'padding', val = 2 },
        {
          type = 'group',
          val = {
            dashboard.button('f', '  Find file', ':Telescope find_files<CR>'),
            dashboard.button('r', '  Recent files', ':Telescope oldfiles<CR>'),
            dashboard.button('g', '  Find text', ':Telescope live_grep<CR>'),
            dashboard.button('s', '  Restore Session', '<cmd>RestoreLastSessionAlpha<CR>'),
            dashboard.button('l', '鈴  Lazy', '<cmd>Lazy<cr>'),
            dashboard.button('q', '  Quit', '<cmd>qa<CR>')
          },
          opts = { spacing = 1, hl = 'AlphaButtons' }
        },
        { type = 'padding', val = 1 },
        {
          type = 'text',
          val = "“Our democracy has been hacked.” - Mr. Robot",
          opts = { hl = 'AlphaFooter', position = 'center' }
        },
      },
      opts = {
        margin = 5,
      }
    }

    alpha.setup(config)

    -- autocmd to close alpha when a file is opened
    vim.api.nvim_create_autocmd('BufEnter', {
        pattern = '*',
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            -- Check if the new buffer is a normal file buffer and not alpha
            if vim.bo[bufnr].buftype == '' and vim.bo[bufnr].filetype ~= 'alpha' then
                -- Find and close the alpha window
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == 'alpha' then
                        -- Only close if it's not the last window
                        if #vim.api.nvim_list_wins() > 1 then
                            vim.api.nvim_win_close(win, true)
                        end
                        break
                    end
                end
            end
        end
    })
  end
}