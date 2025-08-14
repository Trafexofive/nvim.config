return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup({
      -- Size of terminal window
      size = function(term)
        if term.direction == 'horizontal' then
          return 15
        elseif term.direction == 'vertical' then
          return math.floor(vim.o.columns * 0.4)
        else
          return math.floor(vim.o.lines * 0.7)
        end
      end,
      -- Open mapping for toggleterm
      open_mapping = [[<c-t>]],
      -- Hide line numbers in terminal
      hide_numbers = true,
      -- Shade terminal background
      shade_terminals = true,
      -- Start terminal in insert mode
      start_in_insert = true,
      -- Insert mode mappings
      insert_mappings = true,
      -- Terminal mode mappings
      terminal_mappings = true,
      -- Persist terminal size
      persist_size = true,
      -- Default direction for terminal
      direction = 'float',
      -- Close terminal on exit
      close_on_exit = true,
      -- Float window options
      float_opts = {
        -- Border style
        border = 'curved',
        -- Window blending
        winblend = 3,
        -- Highlight group for border
        highlights = {
          border = 'Normal',
          background = 'Normal',
        },
      },
    })

    -- Create a new terminal with custom settings
    local Terminal = require('toggleterm.terminal').Terminal
    local function create_term(cmd, opts)
      local default = {
        cmd = cmd,
        dir = 'git_dir',
        direction = 'float',
        float_opts = { 
          border = 'curved', 
          winblend = 3,
        },
        shade_terminals = true,
        hidden = true,
        on_open = function(term)
          vim.cmd('startinsert!')
          -- Set up escape key mapping for terminal
          vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<esc>', '<cmd>close<CR>',
            { noremap = true, silent = true })
        end,
      }
      return Terminal:new(vim.tbl_deep_extend('force', default, opts or {}))
    end

    -- Global function to toggle a terminal with a command
    function _G.Poptui(cmd, opts)
      create_term(cmd, opts):toggle()
    end

    -- Set up keymaps for various terminal commands
    local map = vim.keymap.set

    -- Git terminal
    map('n', '<leader>gg', function() 
      create_term('lazygit', { close_on_exit = false }):toggle() 
    end, { desc = 'Toggle Lazygit (keep open on exit)' })
    
    -- System monitor
    map('n', '<leader>jt', function() 
      create_term('btop'):toggle() 
    end, { desc = 'Toggle Btop' })
    
    -- Docker terminal
    map('n', '<leader>jd', function() 
      create_term('lazydocker', { close_on_exit = false }):toggle() 
    end, { desc = 'Toggle Lazydocker (keep open on exit)' })
    
    -- File manager
    map('n', '<leader>jy', function() 
      create_term('yazi'):toggle() 
    end, { desc = 'Toggle Yazi' })
    
    -- AI shell
    map('n', '<leader>ja', function() 
      create_term('agent'):toggle() 
    end, { desc = 'Toggle AI Shell' })
    
    -- Markdown preview
    map('n', '<leader>jg', function() 
      create_term('glow ' .. vim.fn.expand('%')):toggle() 
    end, { desc = 'Glow Preview' })

    -- Make commands
    map('n', '<leader>mr', function() 
      create_term('make run'):toggle() 
    end, { desc = 'Make: Run' })
    map('n', '<leader>mm', function() 
      create_term('make'):toggle() 
    end, { desc = 'Make: Build' })
    map('n', '<leader>mc', function() 
      create_term('make clean'):toggle() 
    end, { desc = 'Make: Clean' })
    map('n', '<leader>mf', function() 
      create_term('make fclean'):toggle() 
    end, { desc = 'Make: Fclean' })

    -- Consistent escape mapping for terminal mode
    map('t', '<Esc>', '<C-\\><C-n>', { desc = 'Terminal → Normal Mode' })

    -- Clean up terminal jobs on close
    vim.api.nvim_create_autocmd('TermClose', {
      pattern = 'term://*',
      callback = function(args)
        local job_id = vim.b[args.buf].terminal_job_id
        if job_id and job_id > 0 then
          vim.fn.jobstop(job_id)
        end
      end,
    })
  end,
}
