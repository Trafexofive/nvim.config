-- Global snippets that work in all filetypes
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local f = ls.function_node

return {
  -- Current date snippet
  s("date", {
    f(function() return os.date('%Y-%m-%d') end)
  }),
  
  -- Current time snippet
  s("time", {
    f(function() return os.date('%H:%M:%S') end)
  }),
  
  -- Current datetime snippet
  s("datetime", {
    f(function() return os.date('%Y-%m-%d %H:%M:%S') end)
  }),
}