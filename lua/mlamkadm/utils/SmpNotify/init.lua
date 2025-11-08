-- /lua/mlamkadm/utils/SmpNotify/init.lua

local M = {}

--- Sends a notification.
-- @param message (string) The message to display.
-- @param level (string|number) The log level (e.g., "info", "warn", "error", "success").
-- @param title (string, optional) The title for the notification.
function M.notify(message, level, title)
    local notify_lib = require("notify")
    level = level or "info"
    title = title or "Notification"

    -- Map simple level strings to vim.log.levels and add a success level
    local level_map = {
        info = vim.log.levels.INFO,
        warn = vim.log.levels.WARN,
        error = vim.log.levels.ERROR,
        success = vim.log.levels.INFO, -- Using INFO for success, but can be customized
    }
    local icon_map = {
        info = "",
        warn = "",
        error = "",
        success = "",
    }

    local notification_level = level_map[level:lower()] or vim.log.levels.INFO
    local icon = icon_map[level:lower()] or ""

    notify_lib(message, notification_level, {
        title = title,
        icon = icon,
        -- You can add more nvim-notify options here
    })
end

--- Shows an informational notification.
-- @param message (string) The message to display.
-- @param title (string, optional) The title for the notification.
function M.info(message, title)
    M.notify(message, "info", title or "Info")
end

--- Shows a warning notification.
-- @param message (string) The message to display.
-- @param title (string, optional) The title for the notification.
function M.warn(message, title)
    M.notify(message, "warn", title or "Warning")
end

--- Shows an error notification.
-- @param message (string) The message to display.
-- @param title (string, optional) The title for the notification.
function M.error(message, title)
    M.notify(message, "error", title or "Error")
end

--- Shows a success notification.
-- @param message (string) The message to display.
-- @param title (string, optional) The title for the notification.
function M.success(message, title)
    M.notify(message, "success", title or "Success")
end

return M
