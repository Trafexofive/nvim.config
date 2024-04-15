return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {'nvim-lua/plenary.nvim'},
  keys = {
    {'<leader><leader>', '<cmd>Telescope find_files<cr>'},
    {'<leader>b', '<cmd>Telescope buffers<cr>'},
  },
}

