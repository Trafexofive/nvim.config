return {
    -- If you are using Packer
    'marko-cerovac/material.nvim',
    priority = 1000,
    config = function()
        vim.cmd("colorscheme material")
    end
}
