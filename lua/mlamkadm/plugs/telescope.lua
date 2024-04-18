return {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
        { '<leader><leader>', '<cmd>Telescope find_files<cr>' },
        { '<leader>b',        '<cmd>Telescope buffers<cr>' },
        { '<leader>i',        '<cmd>Telescope git_files<cr>' },
        { 'gd',               '<cmd>Telescope lsp_definitions<cr>' },
        { 'gr',               '<cmd>Telescope lsp_references<cr>' },
        { 'gl',               '<cmd>Telescope lsp_implementations<cr>' },
        { 'gs',               '<cmd>Telescope lsp_document_symbols<cr>' },
    },
    defaults = {
        -- Default configuration for telescope goes here:
        -- config_key = value,
        mappings = {
            i = {
                -- map actions.which_key to <C-h> (default: <C-/>)
                -- actions.which_key shows the mappings for your picker,
                -- e.g. git_{create, delete, ...}_branch for the git_branches picker
                ["<C-h>"] = "which_key"
            }
        }
    },
    pickers = {
        -- Default configuration for builtin pickers goes here:
        -- picker_name = {
        --   picker_config_key = value,
        --   ...
        -- }
        -- Now the picker_config_key will be applied every time you call this
        -- builtin picker
    },
    -- extensions = {
    --     = {
    --       extension_config_key = value,
    --     }
}
