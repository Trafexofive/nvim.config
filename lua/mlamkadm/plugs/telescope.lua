return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.5",
  dependencies = {
    'nvim-lua/plenary.nvim',
    'jonarrien/telescope-cmdline.nvim',
    'gbrlsnchs/telescope-lsp-handlers.nvim',
  },
  keys = {
    { ':', '<cmd>Telescope cmdline<cr>', desc = 'Cmdline' },
        { '<leader><leader>', '<cmd>Telescope find_files<cr>' },
        { '<leader>b',        '<cmd>Telescope buffers<cr>' },
        { '<leader>i',        '<cmd>Telescope git_files<cr>' },
        { '<leader>/',        '<cmd>Telescope live_grep<cr>' },
        { 'gd',               '<cmd>Telescope lsp_definitions<cr>' },
        { 'gr',               '<cmd>Telescope lsp_references<cr>' },
        { 'gl',               '<cmd>Telescope lsp_implementations<cr>' },
        { 'gs',               '<cmd>Telescope lsp_document_symbols<cr>' },
  },
  opts = {
    extensions = {
      cmdline = {
      },
    }
  },
  config = function(_, opts)
    require("telescope").setup(opts)
    require("telescope").load_extension('cmdline')
    require("telescope").load_extension('lsp_handlers')
  end,
}
