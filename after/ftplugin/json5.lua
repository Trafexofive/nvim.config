-- after/ftplugin/json5.lua
-- Ensure JSON5 buffers get a `//` commentstring so gc/gcc work. Runs after the
-- runtime ftplugin/json5.vim to guarantee it wins.
vim.bo.commentstring = "// %s"
