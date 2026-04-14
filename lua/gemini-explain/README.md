# Gemini Explain - Neovim Plugin

A Neovim plugin that integrates the free Google Gemini API for code explanations with contextual awareness. Select code in visual mode and get detailed explanations with repository context.

## Features

- Visual selection handler for code explanation
- Automatic context building (surrounding code, file path, git tree, file type)
- Agent file access (plugin can read additional files when requested by Gemini)
- Streaming response display (see explanation appear in real-time)
- Floating window display for explanations
- Configurable parameters (context lines, keybindings, etc.)

## Installation

### Using Lazy.nvim (recommended)

Add this to your plugins specification:

```lua
{
  "your-github-username/gemini-explain",  -- Replace with actual repo once published
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require('gemini-explain').setup({
      api_key = os.getenv("GEMINI_API_KEY"),  -- or read from file
      model = "gemini-1.5-flash",
      context_lines = 10,  -- lines above/below selection
      keybind = "<leader>ce",  -- code explain
      max_tree_files = 500,  -- limit for large repos
    })
  end,
}
```

### Manual Installation

1. Clone the repository to your Neovim plugin directory:
```bash
git clone https://github.com/your-github-username/gemini-explain.git ~/.config/nvim/lua/gemini-explain
```

2. Add to your `init.lua`:
```lua
require('gemini-explain').setup({
  api_key = os.getenv("GEMINI_API_KEY"),
  model = "gemini-1.5-flash",
  context_lines = 10,
  keybind = "<leader>ce",
  max_tree_files = 500,
})
```

## Configuration

### API Key Setup

You need a Google Gemini API key to use this plugin. You can provide it in one of these ways:

1. **Environment Variable**: Set `GEMINI_API_KEY` in your shell profile:
```bash
export GEMINI_API_KEY="your-api-key-here"
```

2. **Configuration File**: Create `~/.config/nvim/gemini_key.txt` with your API key:
```bash
echo "your-api-key-here" > ~/.config/nvim/gemini_key.txt
```

### Default Configuration

```lua
require('gemini-explain').setup({
  api_key = os.getenv("GEMINI_API_KEY"),  -- or read from file
  model = "gemini-1.5-flash",             -- Gemini model to use
  context_lines = 10,                     -- Lines above/below selection
  keybind = "<leader>ce",                 -- Keybinding for explanation
  max_tree_files = 500,                   -- Max files in git tree
})
```

## Usage

1. Select code in visual line mode (`V`)
2. Press the configured keybinding (default: `<leader>ce`)
3. View the explanation in a floating window
4. Close the window with `q`, `<Esc>`, or `<C-c>`

## How It Works

The plugin collects contextual information when you select code:

1. **Selected snippet** with configurable surrounding lines
2. **Current file path** relative to git root
3. **Git tree structure** (file listing)
4. **File type/language** detection

This context is sent to the Gemini API along with your selected code for more accurate explanations.

If the Gemini agent requests additional files (by outputting "READ_FILE: path/to/file"), the plugin will automatically read and send those files to continue the conversation.

## Dependencies

- Neovim 0.8+
- `plenary.nvim` (for HTTP requests)
- Git (for repository context)

## Troubleshooting

- **API Key Issues**: Make sure your API key is properly set via environment variable or config file
- **Network Issues**: Check your internet connection and firewall settings
- **Rate Limits**: If you hit rate limits, wait before making more requests

## Contributing

Feel free to submit issues and pull requests. For major changes, please open an issue first to discuss what you would like to change.

## License

MIT