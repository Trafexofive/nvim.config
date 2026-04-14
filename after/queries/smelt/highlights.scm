; inherits: cpp

((identifier) @keyword
 (#match? @keyword "^(module|import|instance|priv|comptime|args|extern|match|loop|in|typeof|as|self|null|true|false|and|or)$"))

((identifier) @type.builtin
 (#match? @type.builtin "^(i8|i16|i32|i64|u8|u16|u32|u64|f32|f64|int|uint|float|byte|bool|char|str|void|any)$"))

((identifier) @constant
 (#match? @constant "^[A-Z_][A-Z0-9_]*$"))
