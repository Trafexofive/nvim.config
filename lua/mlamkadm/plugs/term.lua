return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup({
      size = function(term)
        if term.direction == 'horizontal' then
          return 15
        elseif term.direction == 'vertical' then
          return vim.o.columns * 0.4
        end
        return vim.o.lines * 0.8 -- Default to float
      end,
      open_mapping = [[<c-t>]],
      hide_numbers = true,
      shade_terminals = true,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      direction = 'float',
      close_on_exit = true,
      float_opts = {
        border = 'curved',
        winblend = 3,
      },
    })

    -- Define a reusable global function to create and toggle a floating terminal
    local Terminal = require('toggleterm.terminal').Terminal
    function _G.Poptui(cmd)
        local existing_term = require('toggleterm.terminal').get_by_cmd(cmd)
        if existing_term then
            existing_term:toggle()
            return
        end
        Terminal:new({
            cmd = cmd,
            direction = "float",
            hidden = true,
            on_open = function(term)
                vim.cmd("startinsert!")
            end,
        }):toggle()
    end

    -- Setup keymaps for various terminal commands
    local map = vim.keymap.set
    map('n', '<leader>gg', function() _G.Poptui('lazygit') end, { desc = 'Toggle Lazygit' })
    map('n', '<leader>gd', function() _G.Poptui('lazydocker') end, { desc = 'Toggle Lazydocker' })
    map('n', '<leader>gt', function() _G.Poptui('btop') end, { desc = 'Toggle Btop' })
    map('n', '<leader>gf', function() _G.Poptui('yazi') end, { desc = 'Toggle File Manager (Yazi)' })

    -- Makefile commands
    map('n', '<leader>mr', function() _G.Poptui('make run') end, { desc = 'Make: Run' })
    map('n', '<leader>mm', 'make<CR>', { desc = 'Make: Build' })
    map('n', '<leader>mc', function() _G.Poptui('make clean') end, { desc = 'Make: Clean' })

    -- Consistent escape mapping for terminal mode
    map('t', '<Esc>', '<C-><C-n>', { desc = 'Terminal -> Normal Mode' })
  end,
}