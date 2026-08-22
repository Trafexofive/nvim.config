return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
    },
    keys = {
        -- Primary file manager: floating NeoTree, revealed at the current file.
        { "<leader><tab>", "<cmd>Neotree float reveal<cr>", desc = "File Manager (NeoTree float)" },
    },
    config = function()
        -- If you want icons for diagnostic errors, you'll need to define them somewhere:
        vim.fn.sign_define("DiagnosticSignError",
            { text = " ", texthl = "DiagnosticSignError" })
        vim.fn.sign_define("DiagnosticSignWarn",
            { text = " ", texthl = "DiagnosticSignWarn" })
        vim.fn.sign_define("DiagnosticSignInfo",
            { text = " ", texthl = "DiagnosticSignInfo" })
        vim.fn.sign_define("DiagnosticSignHint",
            { text = "󰌵", texthl = "DiagnosticSignHint" })

        require("neo-tree").setup({
            close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
            popup_border_style = "rounded",
            enable_git_status = true,
            enable_diagnostics = true,
            enable_normal_mode_for_inputs = false,
            -- Clickable tabs (filesystem / buffers / git_status) in the float's
            -- top bar, so you can flip sources without leaving the float.
            source_selector = {
                winbar = true,
                statusline = false,
            },
            open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
            sort_case_insensitive = false,
            sort_function = nil,
            default_component_configs = {
                container = {
                    enable_character_fade = true
                },
                indent = {
                    indent_size = 4,
                    padding = 1,
                    with_markers = true,
                    indent_marker = "│",
                    last_indent_marker = "└",
                    highlight = "NeoTreeIndentMarker",
                    expander_collapsed = "",
                    expander_expanded = "",
                    expander_highlight = "NeoTreeExpander",
                },
                icon = {
                    folder_closed = "",
                    folder_open = "",
                    folder_empty = "󰜌",
                    default = "󰈚",
                    highlight = "NeoTreeFileIcon"
                },
                modified = {
                    symbol = "[+]",
                    highlight = "NeoTreeModified",
                },
                name = {
                    trailing_slash = false,
                    use_git_status_colors = true,
                    highlight = "NeoTreeFileName",
                },
                git_status = {
                    symbols = {
                        -- Change type
                        added     = "✚",
                        modified  = "",
                        deleted   = "✖",
                        renamed   = "󰁕",
                        -- Status type
                        untracked = "",
                        ignored   = "",
                        unstaged  = "󰄱",
                        staged    = "",
                        conflict  = "",
                    }
                },
                file_size = {
                    enabled = true,
                    required_width = 64,
                },
                type = {
                    enabled = true,
                    required_width = 122,
                },
                last_modified = {
                    enabled = true,
                    required_width = 88,
                },
                created = {
                    enabled = true,
                    required_width = 110,
                },
                symlink_target = {
                    enabled = false,
                },
            },
            commands = {
                -- Format-aware open: executable files open in a new terminal
                -- (ctrl-t pane/session); everything else opens normally.
                smart_open = function(state)
                    local node = state.tree:get_node()
                    if not node then return end
                    local path = node:get_id()
                    if node.type == "file" and vim.fn.executable(path) == 1 then
                        local ok, term = pcall(require, "mlamkadm.core.terminal")
                        if ok and term and term.new_term then
                            term.new_term(path, { use_theme = false })
                        else
                            vim.cmd("split | terminal " .. vim.fn.fnameescape(path))
                        end
                        return
                    end
                    -- Fall back to the built-in filesystem open (handles
                    -- directory toggling and normal file opens).
                    pcall(require("neo-tree.sources.filesystem.commands").open, state)
                end,
                -- Create a symlink pointing to the node under the cursor.
                symlink = function(state)
                    local node = state.tree:get_node()
                    if not node then return end
                    local target = node:get_id()
                    local base = vim.fn.fnamemodify(target, ":t")
                    local parent = vim.fn.fnamemodify(target, ":h")
                    local inputs = require("neo-tree.ui.inputs")
                    inputs.input("Symlink name (points to " .. base .. "):", parent .. "/", function(link_path)
                        if not link_path or link_path == "" then return end
                        link_path = vim.fn.fnamemodify(link_path, ":p")
                        local out = vim.fn.system({ "ln", "-s", target, link_path })
                        if vim.v.shell_error ~= 0 then
                            vim.notify("ln -s failed: " .. vim.trim(out), vim.log.levels.ERROR)
                            return
                        end
                        vim.notify("Created symlink: " .. link_path, vim.log.levels.INFO)
                        require("neo-tree.sources.filesystem.commands").refresh(state)
                    end)
                end,
            },
            window = {
                position = "left",
                width = 30,
                -- The floating window (used by <leader><tab>): big enough for
                -- multi-file/multi-folder work, centered.
                popup = {
                    size = {
                        height = "88%",
                        width = "85%",
                    },
                    position = "50%",
                    border = "rounded",
                },
                mapping_options = {
                    noremap = true,
                    nowait = true,
                },
                mappings = {
                    ["<leader>"] = {
                        "toggle_node",
                        nowait = true,
                    },
                    ["<cr>"] = "smart_open",
                    ["<esc>"] = "cancel",
                    ["P"] = { "toggle_preview", config = { use_float = true } },
                    ["l"] = "focus_preview",
                    ["-"] = "open_split",
                    ["="] = "open_vsplit",
                    ["t"] = "open_tabnew",
                    ["w"] = "open_with_window_picker",
                    ["C"] = "close_node",
                    ["z"] = "close_all_nodes",
                    ["a"] = {
                        "add",
                        config = {
                            show_path = "none"
                        }
                    },
                    ["A"] = "add_directory",
                    -- Multi-file ops: V (visual line) to select many nodes, then
                    -- d/y/x operate on ALL selected; p pastes the whole batch.
                    ["d"] = "delete",
                    ["r"] = "rename",
                    ["y"] = "copy_to_clipboard",
                    ["x"] = "cut_to_clipboard",
                    ["p"] = "paste_from_clipboard",
                    ["c"] = "copy",
                    ["m"] = "move",
                    ["q"] = "close_window",
                    ["R"] = "refresh",
                    ["?"] = "show_help",
                    ["<"] = "prev_source",
                    [">"] = "next_source",
                    -- <C-j>/<C-k> cycle sources (files → buffers → git_status),
                    -- mirroring the terminal manager's cycle muscle-memory.
                    ["<C-j>"] = "prev_source",
                    ["<C-k>"] = "next_source",
                    ["i"] = "show_file_details",
                    ["L"] = "symlink",
                }
            },
            nesting_rules = {},
            filesystem = {
                filtered_items = {
                    visible = false,
                    hide_dotfiles = false,
                    hide_gitignored = true,
                    hide_hidden = nil,
                    hide_by_name = {
                        ".git",
                        "node_modules",
                        ".venv",
                        "__pycache__",
                    },
                    hide_by_pattern = {
                        "*.meta",
                        "*/src/*/tsconfig.json",
                    },
                    always_show = {},
                    never_show = {
                        ".DS_Store",
                        "thumbs.db"
                    },
                    never_show_by_pattern = {
                        ".null-ls_*",
                    },
                },
                follow_current_file = {
                    enabled = true, -- Follow the current file in the tree
                    leave_dirs_open = false,
                },
                group_empty_dirs = true,
                hijack_netrw_behavior = "open_default",
                use_libuv_file_watcher = true, -- Use OS file watcher for better performance
                window = {
                    mappings = {
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root",
                        ["H"] = "toggle_hidden",
                        ["/"] = "fuzzy_finder",
                        ["D"] = "fuzzy_finder_directory",
                        ["#"] = "fuzzy_sorter",
                        ["f"] = "filter_on_submit",
                        ["<c-x>"] = "clear_filter",
                        ["[g"] = "prev_git_modified",
                        ["]g"] = "next_git_modified",
                        ["o"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
                        ["oc"] = { "order_by_created", nowait = false },
                        ["od"] = { "order_by_diagnostics", nowait = false },
                        ["og"] = { "order_by_git_status", nowait = false },
                        ["om"] = { "order_by_modified", nowait = false },
                        ["on"] = { "order_by_name", nowait = false },
                        ["os"] = { "order_by_size", nowait = false },
                        ["ot"] = { "order_by_type", nowait = false },
                    },
                    fuzzy_finder_mappings = {
                        ["<down>"] = "move_cursor_down",
                        ["<C-n>"] = "move_cursor_down",
                        ["<up>"] = "move_cursor_up",
                        ["<C-p>"] = "move_cursor_up",
                    },
                },
                commands = {}
            },
            buffers = {
                follow_current_file = {
                    enabled = true,
                    leave_dirs_open = false,
                },
                group_empty_dirs = true,
                show_unloaded = true,
                window = {
                    mappings = {
                        ["bd"] = "buffer_delete",
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root",
                        ["o"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
                        ["oc"] = { "order_by_created", nowait = false },
                        ["od"] = { "order_by_diagnostics", nowait = false },
                        ["om"] = { "order_by_modified", nowait = false },
                        ["on"] = { "order_by_name", nowait = false },
                        ["os"] = { "order_by_size", nowait = false },
                        ["ot"] = { "order_by_type", nowait = false },
                    }
                },
            },
            git_status = {
                window = {
                    position = "float",
                    mappings = {
                        ["A"]  = "git_add_all",
                        ["gu"] = "git_unstage_file",
                        ["ga"] = "git_add_file",
                        ["gr"] = "git_revert_file",
                        ["gc"] = "git_commit",
                        ["gp"] = "git_push",
                        ["gg"] = "git_commit_and_push",
                        ["o"]  = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
                        ["oc"] = { "order_by_created", nowait = false },
                        ["od"] = { "order_by_diagnostics", nowait = false },
                        ["om"] = { "order_by_modified", nowait = false },
                        ["on"] = { "order_by_name", nowait = false },
                        ["os"] = { "order_by_size", nowait = false },
                        ["ot"] = { "order_by_type", nowait = false },
                    }
                }
            }
        })

        -- Sidebar (persistent, non-float) reveal of the current file.
        vim.keymap.set("n", "<leader>n", "<cmd>Neotree reveal<cr>", { desc = "Reveal current file in NeoTree (sidebar)" })
    end,
}
