-- after/ftplugin/jsonc.lua
-- Ensure JSONC buffers get a `//` commentstring so gc/gcc work. Runs after the
-- runtime ftplugin/jsonc.vim to guarantee it wins.
vim.bo.commentstring = "// %s"
