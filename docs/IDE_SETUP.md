# IDE Setup & Language Support

This configuration has been streamlined to provide a full IDE experience for the following languages, with lazy-loading enabled to minimize resource usage.

## Supported Languages

| Language | LSP (Intellisense) | Formatter | Linter | Debugger |
| :--- | :--- | :--- | :--- | :--- |
| **C/C++** | `clangd` | `clang-format` | `clang-tidy` (via clangd) | `codelldb` |
| **JS/TS** | `ts_ls` | `prettierd` | `eslint_d` | `js-debug-adapter` |
| **Python** | `pyright` | `isort` + `black` | `pylint` | `debugpy` |
| **Java** | `jdtls` | `google-java-format` | `checkstyle` (manual) | `java-debug-adapter` |
| **Go** | `gopls` | `gofumpt` | `golangci-lint` | `delve` |
| **Rust** | `rust_analyzer` | `rustfmt` | - | `codelldb` |
| **Lua** | `lua_ls` | `stylua` | `selene` | - |
| **Bash** | `bashls` | `shfmt` | `shellcheck` | - |
| **Make** | Treesitter | - | `checkmake` | - |
| **Markdown**| `marksman` | `prettierd` | `markdownlint` | - |
| **Compose** | `dockerls`, `yamlls`| `yamlfmt` | `hadolint`, `yamllint`| - |

## Lazy Loading Strategy

- **LSP**: Loaded on `BufReadPre` or `BufNewFile` (when you open a file).
- **Treesitter**: Loaded on `BufReadPost` (after file content is read).
- **Completion**: Loaded on `InsertEnter` (when you start typing).
- **Formatters**: Loaded on demand via `conform.nvim`.
- **Linters**: Loaded on `BufWritePost`/`InsertLeave` via `nvim-lint`.

## Key Commands

- `gd`: Go to definition
- `K`: Hover documentation
- `<leader>ca`: Code action
- `<leader>rn`: Rename
- `:Format`: Format current buffer (or auto-save)
- `:Mason`: Manage installed tools

## Notes

- **Java**: Uses `jdtls` via `nvim-lspconfig`. For complex Spring Boot projects, consider adding `nvim-java` in the future.
- **Tools**: All external tools are managed by **Mason** and automatically installed/updated.
