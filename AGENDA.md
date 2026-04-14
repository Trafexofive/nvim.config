# Project Agenda & IDE Vision

This document tracks the evolution of the configuration towards the "Neovim IDE Dream": a lightning-fast, persistent, and intelligent development environment that respects system resources while offering full-featured tooling.

## 🌟 The Vision

1.  **Zero Friction**: Terminals, sessions, and cursors should be exactly where you left them.
2.  **Polyglot Power**: First-class support for C/C++, Rust, Go, Python, Lua, Web (JS/TS), and Infrastructure (Docker/Terraform).
3.  **Resource Efficiency**: Heavy processes (LSP, Treesitter, Linters) only load when needed.
4.  **Consistency**: Uniform formatting (4 spaces), keybindings, and UI behavior across all languages.

---

## ✅ Completed Improvements

### Core Workflow
- [x] **Terminal Overhaul**: Multi-instance management, persistence per project, TUI registry (`lazygit`, `btop`, etc.).
- [x] **Session Management**: Auto-save/restore on exit/enter, integrated with terminal sessions.
- [x] **File Explorer**: Neo-tree with "Smart Float" (reveals current file) and git integration.

### Language Server Protocol (LSP) & Tools
- [x] **Lazy Loading**: LSP connects only on `BufReadPre` to save RAM.
- [x] **Fix "Jump to Definition"**: Implemented robust `LspAttach` autocommand for reliable navigation (`gd`, `gr`, `K`).
- [x] **Tool Management**: Mason automatically installs/updates LSPs, Linters, and Formatters.
- [x] **Formatting Standard**: Enforced **4-space indentation** globally (C++, JS, Lua, Bash, Java).

### Language Specifics
- [x] **C/C++**: Clangd + Clang-Format (4 spaces).
- [x] **Java**: JDTLS + Google Java Format (AOSP style).
- [x] **Treesitter**: Added Text Objects (`af`, `if`), Sticky Context Headers, and Auto-tagging.

---

## 📋 Current Agenda

### 1. 📝 Markdown System (Next Priority)
We need to overhaul the Markdown writing experience to match tools like Obsidian or VS Code.
- [ ] **Live Preview**: Seamless synchronized scrolling preview (e.g., `markdown-preview.nvim` or `glow`).
- [ ] **Table Management**: Auto-formatting tables.
- [ ] **Syntax Enhancements**: Better highlighting for math (LaTeX), code blocks, and frontmatter.
- [ ] **Wiki Features**: Easy link navigation and creation.
- [ ] **Zen Mode**: Distraction-free writing integration.

### 2. 🐞 Debugging (DAP)
- [x] Configure `nvim-dap` and `nvim-dap-ui` (Added `dap.lua`).
- [x] Set up language-specific adapter configs (Go, Python, Java via Mason).
- [x] Standardize keymaps for breakpoints/stepping (`<F5>`, `<F10>`, `<F11>`, `<F12>`).

### 3. 🧪 Testing Integration
Bring unit testing inside the editor.
- [ ] Integrate `neotest`.
- [ ] Support for GTest (C++), Pytest (Python), Jest (JS/TS), and Go tests.

### 4. 🧠 AI Workflow
Refine how we interact with LLMs.
- [ ] Streamline `gemini-explain` workflow.
- [ ] Review Copilot / Codeium integration for inline completion vs chat.

### 5. 🧹 Refactoring Tools
- [ ] Search and Replace: Integrate `nvim-spectre` for project-wide replacements.
- [ ] Trouble.nvim: Better diagnostics list management.

---

## 💡 Workflow Notes

- **Formatting**: Use `:Format` manually, or rely on Auto-Save/Format-on-Save.
- **Terminals**: Use `<C-t>` for quick shell, `<leader>tn` for new instance, `<leader>ts` to switch.
- **Explorer**: Use `<leader><tab>` to float the explorer and jump to your current file.
- **Sessions**: Use `<leader>ss` to switch projects. The terminal state follows you.
