return {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        -- Set theme colors
        local highlights = {
            AlphaHeader = { fg = "#00FFFF" }, -- Cyan
            AlphaButtons = { fg = "#FFFFFF" }, -- White
            AlphaFooter = { fg = "#FF0000" }, -- Red
            AlphaShortcut = { fg = "#FF00FF" }, -- Magenta
        }
        for group, hl in pairs(highlights) do
            vim.api.nvim_set_hl(0, group, hl)
        end

        -- DedSec ASCII Art Header
        dashboard.section.header.val = {
            "██████╗ ███████╗██████╗  ██████╗███████╗ ██████╗",
            "██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝",
            "██║  ██║█████╗  ██║  ██║██║     █████╗  ██║     ",
            "██║  ██║██╔══╝  ██║  ██║██║     ██╔══╝  ██║     ",
            "██████╔╝███████╗██████╔╝╚██████╗███████╗╚██████╗",
            "╚═════╝ ╚══════╝╚═════╝  ╚═════╝╚══════╝ ╚═════╝",
        }

        -- Buttons for common actions
        dashboard.section.buttons.val = {
            dashboard.button("f", "  Find File", ":Telescope find_files<CR>"),
            dashboard.button("r", "  Recent Files", ":Telescope oldfiles<CR>"),
            dashboard.button("g", "  Find Text", ":Telescope live_grep<CR>"),
            dashboard.button("s", "  Restore Session", ":lua require('auto-session').RestoreLastSession()<CR>"),
            dashboard.button("l", "鈴  Lazy", ":Lazy<CR>"),
            dashboard.button("q", "  Quit", ":xa<CR>"),
        }

        -- Footer with a quote
        dashboard.section.footer.val = "“Our democracy has been hacked.” - Mr. Robot"

        -- Layout configuration
        dashboard.config.layout = {
            { type = "padding", val = 2 },
            { type = "header" },
            { type = "padding", val = 2 },
            { type = "buttons" },
            { type = "padding", val = 1 },
            { type = "footer" },
        }

        alpha.setup(dashboard.opts)

        -- Disable alpha buffer on file open
        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "*",
            callback = function()
                if vim.bo.filetype ~= "alpha" and vim.bo.filetype ~= "" then
                    -- Close the alpha buffer
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].filetype == "alpha" then
                            vim.api.nvim_win_close(win, true)
                        end
                    end
                end
            end
        })
    end,
}
