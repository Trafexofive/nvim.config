local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("smelt", {
    s("mod", fmt("module {}", { i(1, "main") })),

    s("main", fmt([[module {}

int main() {{
    {}
    return 0
}}]], {
        i(1, "main"),
        i(2, 'print("hello from smelt")'),
    })),

    s("fn", fmt([[{} {}({}) {{
    {}
}}]], {
        i(1, "int"),
        i(2, "name"),
        i(3),
        i(4, "return 0"),
    })),

    s("inst", fmt([[instance {} {{
    {}

    {} new({}) {{
        {}
    }}
}}]], {
        i(1, "TypeName"),
        i(2, "int value"),
        i(3, "TypeName"),
        i(4),
        i(5),
    })),

    s("args", fmt([[args {{
    {}
}}]], {
        i(1, "int port = 8080"),
    })),

    s("imp", fmt("import {}", { i(1, "net") })),
})
