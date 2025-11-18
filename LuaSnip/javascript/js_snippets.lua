-- JavaScript-specific snippets
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
  -- Import statement
  s("imp", {
    t("import "), i(1, "moduleName"), t(" from "), i(2, "'modulePath'"), t(";")
  }),
  
  -- Function declaration
  s("func", {
    t("function "), i(1, "name"), t("("), i(2, ""), t(") {"),
    t({"", "\t"}), i(0), t({"", "}"})
  }),
  
  -- Arrow function
  s("afunc", {
    i(1, "param"), t(" => "), i(2, "expression")
  }),
  
  -- Console log
  s("log", {
    t("console.log("), i(1, "value"), t(");")
  }),
  
  -- If statement
  s("if", {
    t("if ("), i(1, "condition"), t(") {"),
    t({"", "\t"}), i(0), t({"", "}"})
  }),
  
  -- For loop
  s("for", {
    t("for (let "), i(1, "i"), t(" = 0; "), i(1), t(" < "), i(2, "length"), t("; "), i(1), t("++) {"),
    t({"", "\t"}), i(0), t({"", "}"})
  }),
}