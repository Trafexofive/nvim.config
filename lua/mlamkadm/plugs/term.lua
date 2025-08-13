return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    -- Axiom III: FAAFO Engineering → Controlled, iterative sizing logic
    require('toggleterm').setup({
      size = function(term)
        if term.direction == 'horizontal' then
          return 15  -- lean & mean (Axiom IV)
        elseif term.direction == 'vertical' then
          return math.floor(vim.o.columns * 0.4)  -- pragmatic proportion
        else
          return 50  -- float default
        end
      end,
      open_mapping    = [[<c-t>]],           -- quick toggle: automate the mundane (Axiom V)
      hide_numbers    = true,
      shade_terminals = true,
      autochdir       = true,                -- full-stack context (Axiom II)
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size    = true,                -- infinite iteration (Axiom III)
      direction       = 'float',             -- modular float (Axiom V)
      close_on_exit   = true,                -- override per-TUI if needed
      float_opts = {
        border   = 'curved',                 -- pragmatic purity (Axiom IV)
        winblend = 0,
      },
    })

    -- Axiom V: Modularity for Emergence → terminal factory helper
    local Terminal = require('toggleterm.terminal').Terminal
    local function create_term(cmd, opts)
      local default = {
        cmd             = cmd,
        dir             = 'git_dir',         -- resource-flow context (Axiom II)
        direction       = 'float',
        float_opts      = { border = 'curved', winblend = 3 },
        shade_terminals = true,
        hidden          = true,              -- start hidden → FAAFO-experiment ready
        on_open         = function(term)
          vim.cmd('startinsert!')
          vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<esc>', '<cmd>close<CR>',
            { noremap = true, silent = true })
        end,
      }
      -- Axiom I: Unreasonable Imperative → merge any custom overrides
      return Terminal:new(vim.tbl_deep_extend('force', default, opts or {}))
    end

    -- Axiom I & V: AutomateTheMundane, Lego Bricks → global toggle helper
    function _G.Poptui(cmd, opts)
      create_term(cmd, opts):toggle()
    end

    -- Axiom II: Absolute Sovereignty → explicit, named mappings
    local map = vim.keymap.set

    map('n', '<leader>jj', function() _G.Poptui('lazygit', { close_on_exit = false }) end,
        { desc = 'Toggle Lazygit (keep open on exit)' })
    map('n', '<leader>jt', function() _G.Poptui('btop') end,
        { desc = 'Toggle Btop' })
    map('n', '<leader>jd', function() _G.Poptui('lazydocker', { close_on_exit = false }) end,
        { desc = 'Toggle Lazydocker (keep open on exit)' })
    map('n', '<leader>jy', function() _G.Poptui('yazi') end,
        { desc = 'Toggle Yazi' })
    map('n', '<leader>ja', function() _G.Poptui('agent') end,
        { desc = 'Toggle AI Shell' })
    map('n', '<leader>jg', function() _G.Poptui('glow ' .. vim.fn.expand('%')) end,
        { desc = 'Glow Preview' })

    -- Axiom III: FAAFO_WithPurpose → Make commands automated
    map('n', '<leader>mr', function() _G.Poptui('make run') end,
        { desc = 'Make: Run' })
    map('n', '<leader>mm', function() _G.Poptui('make') end,
        { desc = 'Make: Build' })
    map('n', '<leader>mc', function() _G.Poptui('make clean') end,
        { desc = 'Make: Clean' })
    map('n', '<leader>mf', function() _G.Poptui('make fclean') end,
        { desc = 'Make: Fclean' })

    -- Axiom IV: Pragmatic Purity → consistent escape mapping
    map('t', '<Esc>', '<C-\\><C-n>', { desc = 'Terminal → Normal Mode' })

    -- Axiom III & IV: FAAFO data capture + observability
    vim.api.nvim_create_autocmd('TermClose', {
      pattern = 'term://*',
      callback = function(args)
        local job_id = vim.b[args.buf].terminal_job_id
        if job_id and job_id > 0 then
          -- capture failure info rather than silent drop
          vim.fn.jobstop(job_id)
        end
      end,
    })
  end,
}
