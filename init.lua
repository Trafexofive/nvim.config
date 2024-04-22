require("mlamkadm.core")
require("mlamkadm.lazy")

require("lazy").setup("mlamkadm.plugs",
    {
        change_detection = {
            -- automatically check for config file changes and reload the ui
            enabled = true,
            notify = nil, -- get a notification when changes are found
        },
    }
)

require('buffertabs').toggle()

require('buffertabs').setup({
    ---@type 'none'|'single'|'double'|'rounded'|'solid'|'shadow'|table
    border = 'rounded',
    ---@type integer
    padding = 1,
    ---@type boolean
    icons = true,
    ---@type string
    modified = " ",
    ---@type string use hl Group or hex color
    hl_group = 'Keyword',
    ---@type string use hl Group or hex color
    hl_group_inactive = 'Comment',
    ---@type boolean
    show_all = false,
    ---@type 'row'|'column'
    display = 'row',
    ---@type 'left'|'right'|'center'
    horizontal = 'center',
    ---@type 'top'|'bottom'|'center'
    vertical = 'top',
    ---@type number in ms (recommend 2000)
    timeout = 0
})

require 'nvim-web-devicons'.setup {
    -- your personnal icons can go here (to override)
    -- you can specify color or cterm_color instead of specifying both of them
    -- DevIcon will be appended to `name`
    override = {
        zsh = {
            icon = "",
            color = "#428850",
            cterm_color = "65",
            name = "Zsh"
        }
    },
    -- globally enable different highlight colors per icon (default to true)
    -- if set to false all icons will have the default icon's color
    color_icons = true,
    -- globally enable default icons (default to false)
    -- will get overriden by `get_icons` option
    default = true,
    -- globally enable "strict" selection of icons - icon will be looked up in
    -- different tables, first by filename, and if not found by extension; this
    -- prevents cases when file doesn't have any extension but still gets some icon
    -- because its name happened to match some extension (default to false)
    strict = true,
    -- same as `override` but specifically for overrides by filename
    -- takes effect when `strict` is true
    override_by_filename = {
        [".gitignore"] = {
            icon = "",
            color = "#f1502f",
            name = "Gitignore"
        }
    },
    -- same as `override` but specifically for overrides by extension
    -- takes effect when `strict` is true
    override_by_extension = {
        ["log"] = {
            icon = "",
            color = "#81e043",
            name = "Log"
        }
    },
    -- same as `override` but specifically for operating system
    -- takes effect when `strict` is true
    override_by_operating_system = {
        ["apple"] = {
            icon = "",
            color = "#A2AAAD",
            cterm_color = "248",
            name = "Apple",
        },
    },
}


-- require("neoconf").setup({
--     -- override any of the default settings here
-- })

-- require("winshift").setup({
--   highlight_moving_win = true,  -- Highlight the window being moved
--   focused_hl_group = "Visual",  -- The highlight group used for the moving window
--   moving_win_options = {
--     -- These are local options applied to the moving window while it's
--     -- being moved. They are unset when you leave Win-Move mode.
--     wrap = false,
--     cursorline = false,
--     cursorcolumn = false,
--     colorcolumn = "",
--   },
--   keymaps = {
--     disable_defaults = false, -- Disable the default keymaps
--     win_move_mode = {
--       ["h"] = "left",
--       ["j"] = "down",
--       ["k"] = "up",
--       ["l"] = "right",
--       ["H"] = "far_left",
--       ["J"] = "far_down",
--       ["K"] = "far_up",
--       ["L"] = "far_right",
--       ["<left>"] = "left",
--       ["<down>"] = "down",
--       ["<up>"] = "up",
--       ["<right>"] = "right",
--       ["<S-left>"] = "far_left",
--       ["<S-down>"] = "far_down",
--       ["<S-up>"] = "far_up",
--       ["<S-right>"] = "far_right",
--     },
--   },
--   ---A function that should prompt the user to select a window.
--   ---
--   ---The window picker is used to select a window while swapping windows with
--   ---`:WinShift swap`.
--   ---@return integer? winid # Either the selected window ID, or `nil` to
--   ---   indicate that the user cancelled / gave an invalid selection.
--   window_picker = function()
--     return require("winshift.lib").pick_window({
--       -- A string of chars used as identifiers by the window picker.
--       picker_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
--       filter_rules = {
--         -- This table allows you to indicate to the window picker that a window
--         -- should be ignored if its buffer matches any of the following criteria.
--         cur_win = true, -- Filter out the current window
--         floats = true,  -- Filter out floating windows
--         filetype = {},  -- List of ignored file types
--         buftype = {},   -- List of ignored buftypes
--         bufname = {},   -- List of vim regex patterns matching ignored buffer names
--       },
--       ---A function used to filter the list of selectable windows.
--       ---@param winids integer[] # The list of selectable window IDs.
--       ---@return integer[] filtered # The filtered list of window IDs.
--       filter_func = nil,
--     })
--   end,
-- })


require('Comment').setup()
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls" }
})
require("mason-lspconfig").setup({
    ensure_installed = { "clangd" }
})
require("lspconfig").lua_ls.setup {}
require("lspconfig").clangd.setup {}

require("term").setup({
    shell = vim.o.shell,
    width = 0.5,
    height = 0.5,
    anchor = "NW",
    position = "center",
    title = {
        align = "center", -- left, center or right
    },
    border = {
        chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        hl = "TermBorder",
    },
})
