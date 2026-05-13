return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter-textobjects",
        "nvim-treesitter/nvim-treesitter-context",
        "windwp/nvim-ts-autotag",
        "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
        vim.filetype.add({
            extension = {
                smt = "smelt",
            },
        })

        -- Reuse cpp parser for smelt until a native tree-sitter-smelt grammar exists.
        pcall(vim.treesitter.language.register, "cpp", "smelt")

        -- Skip backwards compatibility routines and speed up loading
        vim.g.skip_ts_context_commentstring_module = true
        
        -- Setup context_commentstring directly
        require('ts_context_commentstring').setup {
            enable_autocmd = false,
        }

        local configs = require("nvim-treesitter.configs")

        configs.setup({
            ensure_installed = {
                "c", "cpp", "markdown", "markdown_inline", "lua", "vim", "vimdoc", "query",
                "javascript", "html", "css", "python", "go", "rust", "bash", "yaml", "json",
                "toml", "tsx", "typescript", "regex", "sql", "http", "dockerfile", "make", "java"
            },
            sync_install = false,
            highlight = {
                enable = true,
                -- Neovim 0.12 + current markdown injection queries can throw
                -- `node:range()` errors in the decoration provider. Use regex
                -- markdown highlighting until the parser/query stack is updated.
                disable = { "markdown", "markdown_inline" },
            },
            indent = {
                enable = true,
                disable = { "markdown", "markdown_inline" },
            },
            
            -- Incremental selection for better editing
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<CR>",  -- Start selection
                    node_incremental = "<CR>",  -- Expand to node
                    scope_incremental = "<S-CR>", -- Expand to scope
                    node_decremental = "<Tab>",  -- Shrink selection
                },
            },
            
            -- Autotag (HTML/JSX)
            autotag = {
                enable = true,
            },
            
            -- Text Objects (select, move, swap)
            textobjects = {
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
            },
        })
        
        -- Sticky Context Header
        require("treesitter-context").setup({
            enable = true,
            max_lines = 3,
            min_window_height = 0,
            line_numbers = true,
            multiline_threshold = 20,
            trim_scope = 'outer',
            mode = 'cursor',
            separator = nil,
            zindex = 20,
            on_attach = function(bufnr)
                local ft = vim.bo[bufnr].filetype
                return ft ~= "markdown" and ft ~= "snacks_dashboard"
            end,
        })
    end,
}
