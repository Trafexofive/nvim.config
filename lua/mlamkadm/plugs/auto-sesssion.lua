return {
    'rmagatti/auto-session',
    requires = {
        'nvim-telescope/telescope-fzf-native.nvim',
        run = 'make',
        'tzachar/fuzzy.nvim',
        requires = { 'nvim-telescope/telescope-fzf-native.nvim' }
    },
}
