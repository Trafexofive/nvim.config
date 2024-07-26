require("mlamkadm.core")
require("mlamkadm.lazy")

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("lazy").setup("mlamkadm.plugs",
    {
        change_detection = {
            -- automatically check for config file changes and reload the ui
            enabled = false,
            notify = true, -- get a notification when changes are found
        },
    }
)

require('glow').setup({
    glow_path = "/home/linuxbrew/.linuxbrew/bin/glow",       -- will be filled automatically with your glow bin in $PATH, if any
    install_path = "~/.local/bin", -- default path for installing glow binary
    border = "shadow",    -- floating window border config
    style = "dark", -- filled automatically with your current editor background, you can override using glow json style
    pager = nil,
    width = 80,
    height = 100,
    width_ratio = 1, -- maximum width of the Glow window compared to the nvim window size (overrides `width`)
    height_ratio = 1,
})

require 'cmp_zsh'.setup {
    zshrc = true,                     -- Source the zshrc (adding all custom completions). default: false
    filetypes = { "deoledit", "zsh" } -- Filetypes to enable cmp_zsh source. default: {"*"}
}


require 'nvim-web-devicons'.setup {
    override = {
        zsh = {
            icon = "",
            color = "#428850",
            cterm_color = "65",
            name = "Zsh"
        }
    },
    color_icons = true,
    default = true,
    strict = true,
    override_by_filename = {
        [".gitignore"] = {
            icon = "",
            color = "#f1502f",
            name = "Gitignore"
        }
    },
    override_by_extension = {
        ["log"] = {
            icon = "",
            color = "#81e043",
            name = "Log"
        }
    },
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

require('Comment').setup()

require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls" }
})

require("mason-lspconfig").setup({
    ensure_installed = { "typos_lsp" }
})

require("mason-lspconfig").setup({
    ensure_installed = { "clangd" }
})

require("lspconfig").lua_ls.setup {}
require("lspconfig").clangd.setup {}
require("lspconfig").typos_lsp.setup {}

require("term").setup({
    shell = vim.o.shell,
    width = 0.7,
    height = 0.7,
    anchor = "NW",
    position = "center",
    title = {
        align = "right", -- left, center or right
    },
    border = {
        chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        hl = "TermBorder",
    },
})

require("symbols-outline").setup()

local opts = {
    log_level = 'error',
    auto_session_enable_last_session = nil,
    auto_session_root_dir = vim.fn.stdpath('data') .. "/sessions/",
    auto_session_enabled = nil,
    auto_save_enabled = nil,

    auto_restore_enabled = true,
    auto_session_suppress_dirs = nil,
    auto_session_use_git_branch = nil,
    -- the configs below are lua only
    bypass_session_save_file_types = nil,
    require("auto-session").setup {
        bypass_session_save_file_types = nil, -- table: Bypass auto save when only buffer open is one of these file types
        close_unsupported_windows = true,     -- boolean: Close windows that aren't backed by normal file
        cwd_change_handling = {               -- table: Config for handling the DirChangePre and DirChanged autocmds, can be set to nil to disable altogether
            restore_upcoming_session = true,  -- boolean: restore session for upcoming cwd on cwd change
            pre_cwd_changed_hook = nil,       -- function: This is called after auto_session code runs for the `DirChangedPre` autocmd
            post_cwd_changed_hook = nil,      -- function: This is called after auto_session code runs for the `DirChanged` autocmd
        },
    }
}

require('auto-session').setup(opts)
