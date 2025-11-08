# SmpNotify

A stupid simple notification library for Neovim, built on top of `nvim-notify`.

## Usage

First, make sure you have `nvim-notify` installed.

Then, you can use `SmpNotify` in your Neovim configuration as follows:

```lua
local smp_notify = require("mlamkadm.utils.SmpNotify")

-- Show an info notification
smp_notify.info("This is an informational message.")

-- Show a warning notification with a custom title
smp_notify.warn("Something might be wrong.", "Warning Zone")

-- Show an error notification
smp_notify.error("An error has occurred!")

-- Show a success notification
smp_notify.success("Operation completed successfully.")

-- Use the generic notify function for more control
smp_notify.notify("Custom notification", "info", "Custom Title")
```

## API

### `SmpNotify.notify(message, level, title)`

*   `message` (string): The message to display.
*   `level` (string): The notification level. Can be `"info"`, `"warn"`, `"error"`, or `"success"`.
*   `title` (string, optional): The title of the notification.

### `SmpNotify.info(message, title)`

*   `message` (string): The message to display.
*   `title` (string, optional): The title of the notification. Defaults to `"Info"`.

### `SmpNotify.warn(message, title)`

*   `message` (string): The message to display.
*   `title` (string, optional): The title of the notification. Defaults to `"Warning"`.

### `SmpNotify.error(message, title)`

*   `message` (string): The message to display.
*   `title` (string, optional): The title of the notification. Defaults to `"Error"`.

### `SmpNotify.success(message, title)`

*   `message` (string): The message to display.
*   `title` (string, optional): The title of the notification. Defaults to `"Success"`.
