-- aart.nvim - ASCII Art Animation Plugin
return {
    dir = vim.fn.expand("~/repos/aart"),
    name = "aart",
    lazy = false,
    config = function()
        -- Add lua directory to package path
        local aart_path = vim.fn.expand("~/repos/aart/lua")
        package.path = package.path .. ";" .. aart_path .. "/?.lua;" .. aart_path .. "/?/init.lua"
        
        -- Setup plugin
        require('aart').setup({
            binary_path = vim.fn.expand("~/repos/aart/aart"),  -- Use the built binary
        })
        
        -- Register commands
        require('aart').setup_commands()
        
        -- Keybinding to open animations
        vim.keymap.set('n', '<leader>aa', ':AartOpen ~/.config/nvim/logo.aart<CR>', { desc = "Play ASCII animation" })
    end
}
