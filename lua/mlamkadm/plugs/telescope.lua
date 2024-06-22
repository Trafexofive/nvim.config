return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = {
        'nvim-lua/plenary.nvim',
        'jonarrien/telescope-cmdline.nvim',
        'gbrlsnchs/telescope-lsp-handlers.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = make },
    },
    keys = {
        { ':',                '<cmd>Telescope cmdline<cr>',             desc = 'Cmdline' },
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
            fzf = {
                fuzzy = true,                   -- false will only do exact matching
                override_generic_sorter = true, -- override the generic sorterfuzzy
                override_file_sorter = true,    -- override the file sorter
                case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
            },
            cmdline = {
            },
        }
    },
    config = function(_, opts)
        require("telescope").setup(opts)
        require("telescope").load_extension('cmdline')
        require("telescope").load_extension('lsp_handlers')
        -- require('telescope').load_extension('fzf')
    end,
}
