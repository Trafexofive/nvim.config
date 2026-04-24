-- bufferline.nvim - Professional top bar
return {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
        require("bufferline").setup({
            options = {
                mode = "tabs", -- Only show actual tabs (no buffer clutter)
                separator_style = "slant",
                always_show_bufferline = false, -- Only show if >1 tab
                show_buffer_close_icons = false,
                show_close_icon = false,
                color_icons = true,
            },
        })
    end,
}
