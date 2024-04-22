-- return({
--   "NTBBloodbath/galaxyline.nvim",
--   -- your statusline
--   config = function()
--     require("galaxyline.themes.eviline")
--   end,
--   -- some optional icons
--   dependencies = { "kyazdani42/nvim-web-devicons", opt = true }
-- })

return {
    {
        "sontungexpt/sttusline",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        event = { "BufEnter" },
        config = function(_, opts)
            require("sttusline").setup {
                -- statusline_color = "#000000",
                statusline_color = "StatusLine",

                -- | 1 | 2 | 3
                -- recommended: 3
                laststatus = 3,
                disabled = {
                    filetypes = {
                        -- "NvimTree",
                        -- "lazy",
                    },
                    buftypes = {
                        -- "terminal",
                    },
                },
                components = {
                    "mode",
                    "filename",
                    "git-branch",
                    "git-diff",
                    "%=",
                    "diagnostics",
                    "lsps-formatters",
                    "copilot",
                    "indent",
                    "encoding",
                    "pos-cursor",
                    "pos-cursor-progress",
                },
            }
        end,
    },
}
