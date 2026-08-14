-- after/ftplugin/json.lua
-- The runtime ftplugin/json.vim does `setlocal commentstring=` (empty) because
-- strict JSON forbids comments. But JSONC/JSON5 tooling (VS Code, Prettier,
-- treesitter json parser) all accept `//`, and `Comment.nvim` needs a
-- commentstring for gc/gcc to work. This runs AFTER the runtime ftplugin, so
-- it wins. Use with ts_context_commentstring for context-aware comments.
vim.bo.commentstring = "// %s"
