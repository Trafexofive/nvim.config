-- /lua/mlamkadm/utils/init.lua

local M = {}

M.SmpNotify = require("mlamkadm.utils.SmpNotify")

--- Safely require a module.
-- @param mod (string) The module name to require.
-- @return (table|nil) The module if successful, otherwise nil.
function M.safe_require(mod)
    local ok, module = pcall(require, mod)
    if ok then
        return module
    else
        local msg = "Failed to require module: " .. mod
        if M.SmpNotify then
            M.SmpNotify.warn(msg, "Utils")
        else
            -- Fallback to vim.notify if SmpNotify is not available
            vim.schedule(function()
                pcall(vim.notify, msg, vim.log.levels.WARN, { title = "Utils" })
            end)
        end
        return nil
    end
end

--- Check if a plugin is installed and available.
-- @param name (string) The name of the plugin (e.g., "telescope.nvim").
-- @return (boolean) True if the plugin is available, false otherwise.
function M.is_plugin_available(name)
    local lazy_config = M.safe_require("lazy.core.config")
    if lazy_config and lazy_config.plugins[name] then
        -- Using ._.loaded seems to be the way to check if a plugin is loaded with lazy.nvim
        return lazy_config.plugins[name]._.loaded == true
    end
    return false
end

--- A simple logger/notification wrapper.
-- @param message (string) The message to display.
-- @param level (string|number) The log level (e.g., vim.log.levels.INFO).
-- @param title (string, optional) The title for the notification.
function M.log(message, level, title)
    M.SmpNotify.notify(message, level, title)
end

return M