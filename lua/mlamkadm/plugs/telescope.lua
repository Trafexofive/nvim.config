
return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    event = "VeryLazy", -- Lazy load for better startup time
    dependencies = {
        'nvim-lua/plenary.nvim',
        'jonarrien/telescope-cmdline.nvim',
        'gbrlsnchs/telescope-lsp-handlers.nvim',
        -- Highly recommended performance extension
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            build =
            'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
        },
        -- Additional powerful extensions
        'nvim-telescope/telescope-frecency.nvim',       -- Frecent file sorting
        'nvim-telescope/telescope-live-grep-args.nvim', -- Better grep with args
        { 'nvim-telescope/telescope-ui-select.nvim', version = '^1.0.0' },
        'debugloop/telescope-undo.nvim',                -- Visual undo tree
    },
    keys = {
        -- Essential operations
        { ':',                '<cmd>Telescope cmdline<cr>',                          desc = 'Command Line' },
        { '<leader><leader>', '<cmd>Telescope find_files hidden=true<cr>',           desc = 'Find Files' },
        { '<leader>b',        '<cmd>Telescope buffers sort_mru=true<cr>',            desc = 'Buffers' },
        { '<leader>i',        '<cmd>Telescope git_files<cr>',                        desc = 'Git Files' },

        -- Advanced search
        { '<leader>/',        '<cmd>Telescope live_grep_args<cr>',                   desc = 'Live Grep with Args' },
        { '<leader>fw',       '<cmd>Telescope grep_string<cr>',                      desc = 'Find Word Under Cursor' },
        { '<leader>fr',       '<cmd>Telescope frecency<cr>',                         desc = 'Recent Files' },
        { '<leader>fu',       '<cmd>Telescope undo<cr>',                             desc = 'Undo Tree' },

        -- LSP operations
        { 'gd',               '<cmd>Telescope lsp_definitions jump_type=vsplit<cr>', desc = 'Go to Definition' },
        { 'gr',               '<cmd>Telescope lsp_references<cr>',                   desc = 'Find References' },
        { 'gl',               '<cmd>Telescope lsp_implementations<cr>',              desc = 'Find Implementations' },
        { 'gs',               '<cmd>Telescope lsp_document_symbols<cr>',             desc = 'Document Symbols' },
        { '<leader>ws',       '<cmd>Telescope lsp_workspace_symbols<cr>',            desc = 'Workspace Symbols' },

        -- Git operations
        { '<leader>gc',       '<cmd>Telescope git_commits<cr>',                      desc = 'Git Commits' },
        { '<leader>gb',       '<cmd>Telescope git_branches<cr>',                     desc = 'Git Branches' },
        { '<leader>gs',       '<cmd>Telescope git_status<cr>',                       desc = 'Git Status' },
    },
    opts = {
        defaults = {
            -- Performance optimizations
            file_ignore_patterns = {
                "%.git/", "node_modules/", "%.cache/", "%.DS_Store",
                "%.class", "%.pdf", "%.mkv", "%.mp4", "%.zip"
            },
            vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
                "--hidden",
            },

            -- Better UI
            layout_strategy = 'flex',
            layout_config = {
                horizontal = {
                    preview_width = 0.6,
                    prompt_position = "top",
                },
                vertical = {
                    mirror = false,
                    preview_height = 0.7,
                },
                flex = {
                    flip_columns = 140,
                },
            },

            -- Improved UX
            path_display = { "truncate" },
            winblend = 0,
            border = true,
            sorting_strategy = "ascending",
            scroll_strategy = "cycle",
            color_devicons = true,

            -- Better mappings in preview
            mappings = {
                i = {
                    ["<C-j>"] = "move_selection_next",
                    ["<C-k>"] = "move_selection_previous",
                    ["<C-u>"] = "preview_scrolling_up",
                    ["<C-d>"] = "preview_scrolling_down",
                },
            },
        },

        pickers = {
            find_files = {
                hidden = true,
                no_ignore = false,
                follow = true,
            },
            live_grep = {
                additional_args = function()
                    return { "--hidden" }
                end,
            },
            buffers = {
                sort_lastused = true,
                sort_mru = true,
                show_all_buffers = true,
                ignore_current_buffer = true,
                mappings = {
                    i = {
                        ["<c-d>"] = "delete_buffer",
                    },
                },
            },
        },

        extensions = {
            fzf = {
                fuzzy = true,
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = "smart_case",
            },
            cmdline = {
                history = true,
                previewer = true,
                history_style = 'dropdown',
                mappings = {
                    i = {
                        ["<C-j>"] = require('telescope.actions').move_selection_next,
                        ["<C-k>"] = require('telescope.actions').move_selection_previous,
                        -- ["<C-j>"] = "move_selection_next",
                        -- ["<C-k>"] = "move_selection_previous",
                        -- Optionally, you might want to add these for consistent navigation
                        ["<C-n>"] = false,  -- Disable default next
                        ["<C-p>"] = false,  -- Disable default previous
                        ["<Down>"] = false, -- Optionally disable arrows
                        ["<Up>"] = false,   -- Optionally disable arrows
                    },
                },
            },
            ["ui-select"] = {
                require("telescope.themes").get_dropdown(),
            },
            undo = {
                use_delta = true,
                side_by_side = true,
                layout_strategy = "vertical",
                layout_config = {
                    preview_height = 0.8,
                },
            },
            frecency = {
                show_scores = true,
                show_unindexed = true,
                ignore_patterns = { "*.git/*", "*/tmp/*" },
                workspaces = {
                    ["conf"] = "/home/mlamkadm/.config",
                    ["project"] = "/home/mlamkadm/repos",
                    ["services"] = "/home/mlamkadm/services",
                },
            },
        }
    },
    config = function(_, opts)
        local telescope = require("telescope")

        -- Setup telescope
        telescope.setup(opts)

        -- Load extensions
        local extensions = {
            'cmdline',
            'lsp_handlers',
            'fzf',
            'ui-select',
            'frecency',
            'undo',
            'live_grep_args',
        }

        -- Safely load extensions
        for _, extension in ipairs(extensions) do
            pcall(function()
                telescope.load_extension(extension)
            end)
        end

        -- Custom action to open files in splits
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        telescope.setup({
            defaults = {
                mappings = {
                    i = {
                        ["<C-s>"] = function()
                            local selection = action_state.get_selected_entry()
                            if selection then
                                actions.close(vim.api.nvim_get_current_buf())
                                vim.cmd("split " .. selection.path)
                            end
                        end,
                        ["<C-v>"] = function()
                            local selection = action_state.get_selected_entry()
                            if selection then
                                actions.close(vim.api.nvim_get_current_buf())
                                vim.cmd("vsplit " .. selection.path)
                            end
                        end,
                    },
                },
            },
        })
    end,
}
