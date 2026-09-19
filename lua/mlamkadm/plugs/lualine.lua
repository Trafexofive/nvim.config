-- lualine.nvim - The gold standard statusline
-- Sexy gruvbox statusbar: mode-colored block, per-filetype icons,
-- session-aware widgets (● saved / ◍ dirty / ○ none), live LSP clients.
--
--   [ NORMAL ]  ● nvim · 2m  master  +3 ~1  1E 2W  src/app.lua   ● 2  lua  10%  Ln 12, Col 5
return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false, -- statusline must load eagerly at startup (no trigger otherwise)
    config = function()
        -- Codepoint helper (LuaJIT has no \u{} escapes)
        local function u(c)
            return vim.fn.nr2char(c)
        end

        -- Gruvbox palette
        local bg = "#282828"
        local bg1 = "#3c3836"
        local fg1 = "#ebdbb2"
        local gray = "#928374"
        local blue = "#83a598"
        local green = "#b8bb26"
        local purple = "#d3869b"
        local red = "#fb4934"
        local yellow = "#fabd2f"
        local aqua = "#8ec07c"
        local orange = "#fe8019"

        -- ── Session name from auto-session (or CWD basename) ──────────────
        local function session_name()
            local this = vim.v.this_session
            if this and this ~= "" then
                local name = vim.fn.fnamemodify(this, ":t:r")
                -- auto-session URL-encodes paths: %2Fhome%2Fuser%2Fproj
                name = name:gsub("%%(%x%x)", function(h)
                    return string.char(tonumber(h, 16))
                end)
                name = vim.fn.fnamemodify(name, ":t")
                if name ~= "" then
                    return name
                end
            end
            local name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
            return name ~= "" and name or "~"
        end

        -- ── Session widget: ● saved · ◍ dirty · ○ no session ──────────────
        -- Click opens the session picker (README preview).
        local function session_widget()
            local ok, sm = pcall(require, "mlamkadm.core.session_manager")
            if not ok then
                return session_name()
            end

            -- Any modified buffer => session is dirty (unsaved work)
            local dirty = false
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if
                    vim.api.nvim_buf_is_valid(buf)
                    and vim.api.nvim_buf_is_loaded(buf)
                    and vim.api.nvim_buf_get_option(buf, "modified")
                then
                    dirty = true
                    break
                end
            end

            local info = sm.current_session_info and sm.current_session_info()
            if info then
                local dot = dirty and u(0x25cd) or u(0x25cf) -- ◍ / ●
                local age = info.age and info.age ~= "" and (" " .. info.age) or ""
                return dot .. " " .. info.name .. age
            end
            return u(0x25cb) .. " " .. session_name() -- ○ no session
        end

        local function session_picker()
            local ok, sm = pcall(require, "mlamkadm.core.session_manager")
            if ok and sm.sessions_with_readme then
                sm.sessions_with_readme()
            else
                pcall(vim.cmd, "SessionSearch")
            end
        end

        -- ── Terminal widget: live Zellij session count (async) ────────────
        -- The user's real terminals live as Zellij CLI sessions (persist across
        -- nvim), so the widget reflects those, not just nvim's in-memory floats.
        -- `zellij list-sessions` runs async to avoid blocking statusline render.
        local zellij_live = 0
        local zellij_any = false
        local zellij_busy = false

        local function refresh_zellij()
            if zellij_busy or vim.fn.executable("zellij") ~= 1 then
                return
            end
            zellij_busy = true
            vim.system({ "zellij", "list-sessions" }, { text = true }, function(out)
                zellij_busy = false
                local live, any = 0, false
                for line in (out.stdout or ""):gmatch("[^\n]+") do
                    if not line:find("EXITED", 1, true) then
                        live = live + 1
                    end
                    any = true
                end
                if live ~= zellij_live or any ~= zellij_any then
                    zellij_live, zellij_any = live, any
                    pcall(vim.cmd, "redrawstatus")
                end
            end)
        end

        local function terminal_status()
            refresh_zellij()
            if zellij_live > 0 then
                return u(0x25cf) .. " " .. zellij_live -- ● n live sessions
            end
            -- fallback: nvim-tracked float terminals
            local ok, term = pcall(require, "mlamkadm.core.terminal")
            local n = ok and #term.list_terminals() or 0
            if n > 0 then
                return u(0x25cb) .. " " .. n
            end
            if zellij_any then
                return u(0x25cb) .. " 0"
            end -- sessions, all EXITED
            return ""
        end

        -- Click toggles the last-active terminal (matches <C-t>, which is
        -- `toggle_last_active`, not the old no-arg `toggle()`).
        local function terminal_toggle()
            local ok, term = pcall(require, "mlamkadm.core.terminal")
            if ok and term.toggle_last_active then
                term.toggle_last_active()
            end
        end

        -- ── Insert-mode context widget (only shows while typing) ──────────
        -- While a completion menu is open: show the active source + item count.
        -- While inside a Luasnip snippet: show the jump position.
        local function insert_context()
            local m = vim.fn.mode()
            if m ~= "i" and m ~= "ic" then
                return ""
            end

            local ok_cmp, cmp = pcall(require, "cmp")
            if ok_cmp and cmp.visible and pcall(cmp.visible) and cmp.visible() then
                local name = ""
                local entry = cmp.get_selected_entry and cmp.get_selected_entry()
                if entry and entry.source and entry.source.name then
                    name = entry.source.name
                end
                local n = 0
                if cmp.get_entries then
                    n = #(cmp.get_entries() or {})
                end
                return (name ~= "" and name or "cmp") .. " " .. n
            end

            local ok_ls, ls = pcall(require, "luasnip")
            if ok_ls and ls.get_current_snippet then
                local s = ls.get_current_snippet()
                if s then
                    local idx = s.index or 0
                    local total = (s.nodes and #s.nodes) or 0
                    return "⎘ " .. idx .. "/" .. total
                end
            end
            return ""
        end

        -- ── Active LSP clients for the current buffer ─────────────────────
        local function lsp_clients()
            local clients = vim.lsp.get_clients({ bufnr = 0 })
            if #clients == 0 then
                return ""
            end
            local names = {}
            for _, c in ipairs(clients) do
                table.insert(names, c.name)
            end
            return table.concat(names, " ")
        end

        -- ── Colored per-filetype icon via devicons ────────────────────────
        local function file_icon()
            local ok, devicons = pcall(require, "nvim-web-devicons")
            if not ok then
                return ""
            end
            local fname = vim.fn.expand("%:t")
            if fname == "" then
                return ""
            end
            local icon, hl = devicons.get_icon(fname, vim.bo.filetype, { default = true })
            if not icon then
                return ""
            end
            return "%#" .. (hl or "DevIconDefault") .. "#" .. icon .. "%*"
        end

        -- ── Custom theme: mode-colored block on gruvbox neutrals ──────────
        local theme = {
            normal = {
                a = { fg = bg, bg = blue, gui = "bold" },
                b = { fg = fg1, bg = bg1 },
                c = { fg = fg1, bg = bg },
                x = { fg = gray, bg = bg },
                y = { fg = fg1, bg = bg1 },
                z = { fg = bg, bg = orange, gui = "bold" },
            },
            insert = { a = { fg = bg, bg = green, gui = "bold" } },
            visual = { a = { fg = bg, bg = purple, gui = "bold" } },
            replace = { a = { fg = bg, bg = red, gui = "bold" } },
            command = { a = { fg = bg, bg = yellow, gui = "bold" } },
            terminal = { a = { fg = bg, bg = aqua, gui = "bold" } },
            inactive = {
                a = { fg = gray, bg = bg },
                b = { fg = gray, bg = bg },
                c = { fg = gray, bg = bg },
                x = { fg = gray, bg = bg },
                y = { fg = gray, bg = bg },
                z = { fg = gray, bg = bg },
            },
        }

        require("lualine").setup({
            options = {
                theme = theme,
                component_separators = { left = u(0xe0b1), right = u(0xe0b3) },
                section_separators = { left = u(0xe0b0), right = u(0xe0b2) },
                globalstatus = true,
                disabled_filetypes = {
                    statusline = { "alpha", "snacks_dashboard", "neo-tree" },
                },
            },
            sections = {
                lualine_a = {
                    {
                        "mode",
                        fmt = function(m)
                            return " " .. m:upper() .. " "
                        end,
                    },
                },
                lualine_b = {
                    { session_widget, color = { fg = aqua }, on_click = session_picker },
                    { "branch", icon = u(0xe0a0), color = { fg = yellow } },
                    {
                        "diff",
                        colored = true,
                        symbols = { added = "+", modified = "~", removed = "-" },
                    },
                },
                lualine_c = {
                    { insert_context, update_in_insert = true, color = { fg = yellow } },
                    {
                        "diagnostics",
                        symbols = {
                            error = u(0xea87),
                            warn = u(0xea8a),
                            info = u(0xea8b),
                            hint = u(0xea8d),
                        },
                    },
                    { file_icon },
                    {
                        "filename",
                        path = 1,
                        symbols = { modified = " " .. u(0x25cf), readonly = " ", unnamed = "" },
                    },
                },
                lualine_x = {
                    { terminal_status, icon = u(0xf120), color = { fg = orange }, on_click = terminal_toggle },
                    { lsp_clients, icon = u(0xf085), color = { fg = blue } },
                    { "searchcount", max = 999, timeout = 500 },
                    "filetype",
                },
                lualine_y = { "progress" },
                lualine_z = {
                    { "location", left_padding = 2 },
                },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = {},
                lualine_y = {},
                lualine_z = { "location" },
            },
        })

        -- Keep the bar honest: session save/load, cwd changes, window switches
        local group = vim.api.nvim_create_augroup("LualineRefresh", { clear = true })
        vim.api.nvim_create_autocmd(
            { "SessionLoadPost", "SessionWritePost", "DirChanged", "VimEnter", "WinEnter", "BufWritePost" },
            {
                group = group,
                callback = function()
                    refresh_zellij()
                    vim.cmd("redrawstatus")
                end,
                desc = "Refresh statusline on session/terminal/window changes",
            }
        )
    end,
}
