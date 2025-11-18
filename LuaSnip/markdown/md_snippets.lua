-- Markdown-specific snippets
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  -- Heading 1
  s("h1", { t("# "), i(1, "Heading") }),
  
  -- Heading 2
  s("h2", { t("## "), i(1, "Heading") }),
  
  -- Heading 3
  s("h3", { t("### "), i(1, "Heading") }),
  
  -- Link
  s("link", { t("["), i(1, "text"), t("]("), i(2, "url"), t(")") }),
  
  -- Image
  s("img", { t("!["), i(1, "alt"), t("]("), i(2, "url"), t(")") }),
  
  -- Inline code
  s("codeb", { t("`"), i(1, "code"), t("`") }),
  
  -- Code block
  s("codeblock", { t("```"), i(1, "language"), t("\n"), i(2), t("\n```") }),
  
  -- To-do item
  s("todo", { t("- [ ] "), i(1, "todo item") }),
  
  -- Completed item
  s("done", { t("- [x] "), i(1, "completed item") }),
  
  -- Bold text
  s("bold", { t("**"), i(1, "text"), t("**") }),
  
  -- Italic text
  s("italic", { t("*"), i(1, "text"), t("*") }),
}