# Utility Library

This directory contains shared Lua modules with utility functions that can be used across the Neovim configuration, including custom plugins.

## Usage

To use the main utils module, simply `require` it:

```lua
local utils = require("mlamkadm.utils")

-- Now you can use the functions from the main init.lua
utils.log("This is a test message.", "info", "MyPlugin")

-- You can also use SmpNotify directly
utils.SmpNotify.success("File saved!")

if utils.is_plugin_available("telescope.nvim") then
  -- do something with telescope
end
```

## Modules

### `SmpNotify`

A simple notification library. See `lua/mlamkadm/utils/SmpNotify/README.md` for more details.

### `log(message, level, title)`

A simple logger/notification wrapper that uses `SmpNotify`.

* `message` (string): The message to display.
* `level` (string): The notification level. Can be `"info"`, `"warn"`, `"error"`, or `"success"`.
* `title` (string, optional): The title of the notification.

### `is_plugin_available(name)`

Checks if a lazy.nvim plugin is loaded.

* `name` (string): The name of the plugin (e.g., "telescope.nvim").

### `safe_require(mod)`

Safely requires a module and shows a notification on failure.

* `mod` (string): The module name to require.