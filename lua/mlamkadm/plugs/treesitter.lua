return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- nvim 0.12 requires the rewritten main branch (master is frozen/broken)
    build = ":TSUpdate",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
        { "nvim-treesitter/nvim-treesitter-context", branch = "master" },
        { "windwp/nvim-ts-autotag", branch = "main" },
        { "JoosepAlviste/nvim-ts-context-commentstring", branch = "main" },
    },
    config = function()
        -- nvim 0.12 + nvim-treesitter `main` branch migration.
        -- `main` only manages parser install: require("nvim-treesitter").setup().
        -- Highlight + indent are nvim 0.12 BUILT-INS (vim.treesitter.start/indent).
        -- Text objects / autotag live in their own satellites with their own modules.

        vim.filetype.add({
            extension = {
                smt = "smelt",
            },
        })

        -- Reuse cpp parser for smelt until a native tree-sitter-smelt grammar exists.
        -- DISABLED: Missing injection queries cause `node:range()` nil crash on Neovim 0.12.
        -- Re-enable when after/queries/smelt/ has full query coverage (injections, indents, folds).
        -- pcall(vim.treesitter.language.register, "cpp", "smelt")

        -- Skip backwards compatibility routines and speed up loading
        vim.g.skip_ts_context_commentstring_module = true

        -- Setup context_commentstring directly
        require("ts_context_commentstring").setup({
            enable_autocmd = false,
        })

        -- New nvim-treesitter setup (parsers only).
        require("nvim-treesitter").setup()

        -- Ensure parsers are installed (replaces old `ensure_installed`).
        -- Diff against installed so we don't reinstall on every startup.
        local ensure = {
            "c",
            "cpp",
            "lua",
            "vim",
            "vimdoc",
            "query",
            "javascript",
            "html",
            "css",
            "python",
            "go",
            "rust",
            "bash",
            "yaml",
            "json",
            "toml",
            "tsx",
            "typescript",
            "regex",
            "sql",
            "http",
            "dockerfile",
            "make",
            "java",
        }
        local installed = vim.treesitter.language.get_languages and vim.treesitter.language.get_languages() or {}
        local to_install = {}
        for _, lang in ipairs(ensure) do
            if not vim.tbl_contains(installed, lang) then
                to_install[#to_install + 1] = lang
            end
        end
        if #to_install > 0 then
            require("nvim-treesitter").install(to_install)
        end

        -- Enable highlighting + indentation via nvim 0.12 built-ins.
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                local ft = vim.bo[args.buf].filetype
                if ft == "smelt" then
                    return
                end -- no grammar yet
                pcall(vim.treesitter.start, args.buf)
                -- Indentation is provided by nvim-treesitter main via indentexpr().
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })

        -- Autotag (HTML/JSX) — separate plugin.
        pcall(function()
            require("nvim-ts-autotag").setup()
        end)

        -- Text Objects (select + move) — satellite, module name unchanged.
        pcall(function()
            require("nvim-treesitter-textobjects").setup({
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        ["ic"] = "@class.inner",
                        ["aa"] = "@parameter.outer",
                        ["ia"] = "@parameter.inner",
                    },
                },
                move = {
                    enable = true,
                    set_jumps = true,
                    goto_next_start = {
                        ["]m"] = "@function.outer",
                        ["]]"] = "@class.outer",
                    },
                    goto_next_end = {
                        ["]M"] = "@function.outer",
                        ["]["] = "@class.outer",
                    },
                    goto_previous_start = {
                        ["[m"] = "@function.outer",
                        ["[["] = "@class.outer",
                    },
                    goto_previous_end = {
                        ["[M"] = "@function.outer",
                        ["[]"] = "@class.outer",
                    },
                },
            })
        end)

        -- Sticky Context Header
        require("treesitter-context").setup({
            enable = true,
            max_lines = 3,
            min_window_height = 0,
            line_numbers = true,
            multiline_threshold = 20,
            trim_scope = "outer",
            mode = "cursor",
            separator = nil,
            zindex = 20,
            on_attach = function(bufnr)
                local ft = vim.bo[bufnr].filetype
                return ft ~= "markdown" and ft ~= "snacks_dashboard"
            end,
        })
    end,
}
