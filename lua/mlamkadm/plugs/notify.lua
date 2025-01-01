return {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    keys = {
        { "<leader>fn", "<cmd>Telescope notify<cr>", desc = "List Notifications" },
    },
    opts = {
        -- Configure animations
        stages = "fade", -- fade|slide|fade_in_slide_out|static

        -- Set timeout for notifications (in ms)
        timeout = 1000,

        -- Maximum width of notifications
        max_width = function()
            return math.floor(vim.o.columns * 0.75)
        end,

        -- Maximum height of notifications
        max_height = function()
            return math.floor(vim.o.lines * 0.75)
        end,

        -- Minimal width for notifications
        minimum_width = 50,

        -- Icons for different levels (using nerdfont)
        icons = {
            -- ERROR = "",
            -- WARN = "",
            -- INFO = "",
            -- DEBUG = "",
            TRACE = "✎",
        },

        -- Background color by notification level
        background_colour = function()
            return "#000000"
        end,

        -- Set default level for vim.notify()
        level = 3,

        -- Render style
        render = "default", -- default|minimal|simple

        -- Animation FPS
        fps = 60,

        -- Top position for notifications
        top_down = true,

        -- Time format
        time_formats = {
            notification_history = "%FT%T",
            notification = "%T",
        },

        -- Max notification history
        max_history = 100,
    },
    config = function(_, opts)
        local notify = require("notify")

        -- Setup notify
        notify.setup(opts)

        -- Override vim.notify
        vim.notify = notify

        -- Create highlight groups
        vim.api.nvim_set_hl(0, "NotifyERRORBorder", { fg = "#8A1F1F" })
        vim.api.nvim_set_hl(0, "NotifyWARNBorder", { fg = "#79491D" })
        vim.api.nvim_set_hl(0, "NotifyINFOBorder", { fg = "#4F6752" })
        vim.api.nvim_set_hl(0, "NotifyDEBUGBorder", { fg = "#8B8B8B" })
        vim.api.nvim_set_hl(0, "NotifyTRACEBorder", { fg = "#4F3552" })

        -- Sample Usage Commands
        vim.api.nvim_create_user_command("NotifyDismiss", function()
            notify.dismiss()
        end, {})

        -- Example usage of notification history in Telescope
        require("telescope").load_extension("notify")

        -- Helper function for common notifications
        _G.notify_custom = function(msg, level, opts)
            opts = opts or {}
            level = level or "INFO"

            local default_opts = {
                title = string.format("[%s] Notification", os.date("%H:%M:%S")),
                timeout = 3000,
                on_open = function(win)
                    local buf = vim.api.nvim_win_get_buf(win)
                    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
                end,
            }

            opts = vim.tbl_deep_extend("force", default_opts, opts)
            vim.notify(msg, level, opts)
        end

        -- Create some example keymaps for common actions
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
        end

        -- Dismiss all notifications
        map("n", "<leader>nd", function()
            notify.dismiss()
        end, "Dismiss all notifications")

        -- Example notification levels
        map("n", "<leader>ni", function()
            notify_custom("This is an info message", "INFO")
        end, "Info notification")

        map("n", "<leader>nw", function()
            notify_custom("This is a warning message", "WARN")
        end, "Warning notification")

        map("n", "<leader>ne", function()
            notify_custom("This is an error message", "ERROR")
        end, "Error notification")

        -- Example usage in your configuration:
        -- vim.notify("Configuration loaded!", "INFO", {
        --     title = "Neovim",
        --     timeout = 2000,
        -- })

        -- Add autocommands for automatic notifications
        vim.api.nvim_create_autocmd("User", {
            pattern = "LazyLoad",
            callback = function(event)
                notify_custom(string.format("Plugin loaded: %s", event.data), "INFO", {
                    title = "Plugin Manager",
                    timeout = 2000,
                })
            end,
        })

        -- Notification for long running operations
        vim.api.nvim_create_autocmd("LspProgress", {
            callback = function(event)
                if event.data and event.data.message then
                    notify_custom(event.data.message, "INFO", {
                        title = "LSP Progress",
                        timeout = false,
                        hide_from_history = true,
                    })
                end
            end,
        })
    end,
}
