# Markdown Setup for Neovim

This configuration provides a complete Markdown editing experience in Neovim with preview, LSP support, snippets, and utilities.

## Plugins Included

1. **jakewvincent/mkdnflow.nvim** - Navigation and utilities for Markdown files
2. **iamcco/markdown-preview.nvim** - Real-time Markdown preview in browser
3. **lukas-reineke/headlines.nvim** - Better headings and code block highlighting
4. **michaelb/sniprun** - Execute code blocks directly from Markdown files

## Key Features

### LSP Support
- **Marksman** LSP for Markdown files providing:
  - Syntax checking
  - Reference finding
  - Rename support
  - Document symbols

### Syntax Highlighting
- Enhanced highlighting with Treesitter for both `markdown` and `markdown_inline`
- Visual distinction for headings, code blocks, and lists
- Custom highlights for different heading levels

### Snippets
- Heading shortcuts (h1, h2, h3)
- Link and image templates
- Code block snippets with language support

### Preview Options
1. **Browser Preview** - Real-time preview in your default browser
2. **Terminal Preview** - Using `glow` for a terminal-based preview

## Keybindings

### Preview
- `<leader>mp` - Start Markdown preview
- `<leader>ms` - Stop Markdown preview
- `<leader>mt` - Toggle Markdown preview
- `<leader>gp` - Preview with Glow (terminal-based)

### Code Execution
- `<leader>rr` - Run code block (normal mode)
- `<leader>rr` - Run selected code (visual mode)

### Utilities
- `<leader>ml` - Paste clipboard content as Markdown link
- `<leader>mt` - Toggle checkbox state in task lists
- `<leader>mc` - Insert a code block with appropriate language

### Navigation (mkdnflow)
- `<CR>` - Follow link or create missing file
- `<Tab>` - Next link
- `<S-Tab>` - Previous link
- `]]` - Next heading
- `[[` - Previous heading

## Custom Functions

### Paste as Markdown Link
Automatically converts clipboard URLs into Markdown link format:
```
[<CURSOR>](https://example.com)
```

### Toggle Checkbox
Cycles between checked/unchecked states in task lists:
```
- [ ] Task (unchecked)
- [x] Task (checked)
```

### Insert Code Block
Inserts a properly formatted code block with language detection:
```markdown
```python
<CURSOR>
```
```

## Requirements

1. **Node.js** for markdown-preview.nvim
2. **glow** for terminal-based preview (Optional)
3. **Marksman** LSP server (automatically installed via Mason)

Install glow (on macOS with Homebrew):
```bash
brew install glow
```

Install glow (on Ubuntu/Debian):
```bash
sudo apt install glow
```