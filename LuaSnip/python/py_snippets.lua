-- Python-specific snippets
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  -- Function definition
  s("def", {
    t("def "), i(1, "function_name"), t("("), i(2, "args"), t("):"),
    t({"", "\t"}), i(0)
  }),
  
  -- Class definition
  s("class", {
    t("class "), i(1, "ClassName"), t(":"),
    t({"", "\tdef __init__(self, "}), i(2, "args"), t({"):","","\t\t"}), i(0)
  }),
  
  -- If statement
  s("if", {
    t("if "), i(1, "condition"), t(":"),
    t({"", "\t"}), i(0)
  }),
  
  -- For loop
  s("for", {
    t("for "), i(1, "item"), t(" in "), i(2, "iterable"), t(":"),
    t({"", "\t"}), i(0)
  }),
  
  -- Print statement
  s("print", {
    t("print("), i(1, "value"), t(")")
  }),
  
  -- List comprehension
  s("lc", {
    t("["), i(1, "expr"), t(" for "), i(2, "item"), t(" in "), i(3, "iterable"), t(" if "), i(4, "condition"), t("]")
  }),
}