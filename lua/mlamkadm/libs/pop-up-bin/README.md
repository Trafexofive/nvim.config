# Pop-Up Bin

A simple, self-contained Neovim plugin to run terminal commands in a floating pop-up window.

## Features

- Runs any shell command in a floating terminal.
- Toggles the terminal window for the same command.
- Customizable window dimensions, border, and title.
- Lightweight, with no external dependencies.

## Usage

This plugin is configured to define a global function `_G.Poptui(cmd)`. You can use this function to open any command in a popup.

Example keymap:
```lua
vim.keymap.set('n', '<leader>gg', function() _G.Poptui('lazygit') end, { desc = 'Toggle Lazygit' })
```

This plugin provides a lightweight alternative to `toggleterm.nvim` for simple pop-up terminals.
