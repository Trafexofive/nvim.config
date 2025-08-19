# monkeytype.nvim

A minimalist typing practice plugin for Neovim that transforms any buffer into a typing tutor. Practice typing directly on your code, documentation, or any text without leaving your editor.

## Features

- **In-buffer typing practice**: Practice on any text content in your current buffer
- **Real-time feedback**: Visual highlighting shows correct/incorrect characters as you type
- **WPM calculation**: Live words-per-minute tracking displayed at line end
- **Accuracy tracking**: Detailed statistics on completion
- **Non-destructive**: Preserves original buffer content and keymaps
- **Lightweight**: Pure Lua implementation with no external dependencies

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'your-username/monkeytype.nvim',
  config = function()
    require('monkeytype').setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'your-username/monkeytype.nvim',
  config = function()
    require('monkeytype').setup()
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'your-username/monkeytype.nvim'
```

Then add to your `init.lua`:
```lua
require('monkeytype').setup()
```

## Usage

### Basic Commands

- `:MonkeytypeStart` - Start typing practice on current buffer
- `:MonkeytypeStop` - Stop current typing practice
- `:MonkeytypeReset` - Reset current practice session
- `:MonkeytypeStats` - Show current typing statistics

### Workflow

1. Open any file with text content
2. Run `:MonkeytypeStart`
3. Switch to insert mode and start typing
4. Characters are highlighted as you type:
   - **Correct characters**: Highlighted with `Comment` group (usually dimmed)
   - **Incorrect characters**: Highlighted with `Error` group (usually red)
   - **Remaining characters**: Highlighted with `Normal` group
5. Press `<Esc>` to exit practice mode
6. View final statistics automatically displayed

### Key Bindings (in practice mode)

- `<any printable character>` - Type the character
- `<Backspace>` - Delete previous character
- `<Enter>` - Move to next line (when current line is complete)
- `<Esc>` - Exit practice mode

## Configuration

```lua
require('monkeytype').setup({
  highlight_groups = {
    correct = "Comment",      -- Highlight group for correct characters
    error = "Error",          -- Highlight group for incorrect characters  
    remaining = "Normal",     -- Highlight group for untyped characters
  },
})
```

### Custom Highlight Groups

You can create custom highlight groups for more control:

```lua
-- Define custom highlights
vim.api.nvim_set_hl(0, "MonkeytypeCorrect", { fg = "#50fa7b" })
vim.api.nvim_set_hl(0, "MonkeytypeError", { fg = "#ff5555", bg = "#44475a" })
vim.api.nvim_set_hl(0, "MonkeytypeRemaining", { fg = "#6272a4" })

-- Use in configuration
require('monkeytype').setup({
  highlight_groups = {
    correct = "MonkeytypeCorrect",
    error = "MonkeytypeError",
    remaining = "MonkeytypeRemaining",
  },
})
```

## Key Bindings Setup

Add these to your Neovim configuration for quick access:

```lua
-- Key mappings for monkeytype
vim.keymap.set('n', '<leader>mY', '<cmd>MonkeytypeStart<cr>', { desc = 'Start typing practice' })
vim.keymap.set('n', '<leader>mS', '<cmd>MonkeytypeStop<cr>', { desc = 'Stop typing practice' })
vim.keymap.set('n', '<leader>mR', '<cmd>MonkeytypeReset<cr>', { desc = 'Reset typing practice' })
vim.keymap.set('n', '<leader>mX', '<cmd>MonkeytypeStats<cr>', { desc = 'Show typing stats' })
```

## How It Works

1. **State Preservation**: The plugin saves your original buffer content, keymaps, and settings
2. **Keymap Override**: In practice mode, all insert mode keys are intercepted to handle typing logic
3. **Visual Feedback**: Uses Neovim's highlighting API to show progress in real-time
4. **Statistics**: Tracks typing speed (WPM) and accuracy throughout the session
5. **Clean Restoration**: When exiting, all original settings are restored perfectly

## Use Cases

- **Code Practice**: Improve typing speed on programming languages
- **Documentation**: Practice typing on README files, documentation
- **Learning**: Type out code examples to learn new syntax
- **Muscle Memory**: Build familiarity with special characters and symbols
- **Touch Typing**: Practice without looking at keyboard

## Technical Details

- **Language**: Pure Lua
- **Dependencies**: None (uses only Neovim built-in APIs)
- **Performance**: Minimal overhead, efficient highlighting
- **Compatibility**: Works with Neovim 0.7+

## Statistics

The plugin tracks:
- **WPM (Words Per Minute)**: Based on standard 5-character word definition
- **Accuracy**: Percentage of correctly typed characters
- **Character Count**: Total characters typed vs. correct characters
- **Real-time Updates**: Live WPM display during practice

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup

1. Clone the repository
2. Create a symlink to your Neovim plugin directory
3. Test with `:MonkeytypeStart` on any buffer with text

## License

MIT License - see LICENSE file for details.

## Inspiration

Inspired by [monkeytype.com](https://monkeytype.com) but designed specifically for developers who want to practice typing on real code and documentation within their editor.
