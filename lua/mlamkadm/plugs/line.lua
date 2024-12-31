-- return({
--   "NTBBloodbath/galaxyline.nvim",
--   -- your statusline
--   config = function()
--     require("galaxyline.themes.eviline")
--   end,
--   -- some optional icons
--   dependencies = { "kyazdani42/nvim-web-devicons", opt = true }
-- })

-- Define custom Datetime component

return {
    {
        "sontungexpt/sttusline",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        event = { "BufEnter" },
    },
}

