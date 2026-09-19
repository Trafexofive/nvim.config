-- pi.lua — Pi Agent bridge integration for nvim
-- Zen: Instant pi access from within the IDE
-- Commands:
--   :Pi <prompt>        Send buffer context + prompt to pi in terminal
--   :PiSelection         Send visual selection + prompt to pi in terminal
--   :PiPrompt            Pick a prompt from the registry, apply to buffer
--   <leader>pi           Quick prompt input
--   <leader>ps           Pick pi session (list active terminals)

local M = {}

-- Cache pi executable location
local pi_bin = nil
local function get_pi_bin()
    if pi_bin then
        return pi_bin
    end
    -- Try common locations
    local candidates = {
        "pi",
        vim.fn.expand("~/.local/bin/pi"),
        vim.fn.expand("~/.npm-global/bin/pi"),
    }
    for _, p in ipairs(candidates) do
        if vim.fn.executable(p) == 1 then
            pi_bin = p
            return p
        end
    end
    return nil
end

-- Temp directory for pi context files
local function temp_dir()
    local dir = vim.fn.stdpath("data") .. "/pi_temp"
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
    return dir
end

-- Smart context: full file if < 200 lines, otherwise visible range
local function get_smart_context()
    local bufnr = vim.api.nvim_get_current_buf()
    local total = vim.api.nvim_buf_line_count(bufnr)

    if total <= 200 then
        -- Full file
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        return table.concat(lines, "\n"), 1, total
    else
        -- Visible range (what you're looking at)
        local win = vim.api.nvim_get_current_win()
        local first = vim.fn.line("w0")
        local last = vim.fn.line("w$")
        local lines = vim.api.nvim_buf_get_lines(bufnr, first - 1, last, false)
        return table.concat(lines, "\n"), first, last
    end
end

-- Build a temp file with context + prompt
local function build_context_file(content, prompt, filepath, line_start, line_end)
    local ts = os.date("%Y%m%d_%H%M%S")
    local path = temp_dir() .. "/pi_" .. ts .. ".txt"

    local buf = {}
    table.insert(buf, "-- Context from nvim")
    table.insert(buf, "-- File: " .. filepath)

    if line_start and line_end then
        table.insert(buf, string.format("-- Lines: %d-%d", line_start, line_end))
    end

    table.insert(buf, "")
    table.insert(buf, "-- User instruction:")
    table.insert(buf, prompt or "analyze/improve this code")
    table.insert(buf, "")
    table.insert(buf, "-- Code:")
    table.insert(buf, content)

    local text = table.concat(buf, "\n")
    vim.fn.writefile(vim.split(text, "\n"), path)
    return path
end

-- Open pi in a terminal buffer (split below)
local function open_pi_terminal(cmd, title)
    -- Create a split for the terminal
    vim.cmd("botright split")
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_buf_set_option(buf, "buftype", "terminal")

    -- Title the window
    local title_text = title and ("pi: " .. title) or "pi"
    vim.api.nvim_buf_set_name(buf, title_text)

    -- Start the terminal with pi
    vim.fn.termopen(cmd, {
        on_exit = function(_, code, _)
            if code == 0 then
                vim.api.nvim_buf_set_option(buf, "modifiable", false)
                vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
                vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
            end
        end,
    })

    vim.cmd("startinsert")
    return buf, win
end

-- ──────────────────────────────────────
-- Public API
-- ──────────────────────────────────────

--- Send buffer context to pi agent
--- @param prompt string: User's instruction/query
--- @param selection_only boolean: Use visual selection instead of full buffer
function M.send_to_pi(prompt, selection_only)
    local pi = get_pi_bin()
    if not pi then
        vim.notify("pi not found in PATH. Install pi agent first.", vim.log.levels.ERROR)
        return
    end

    local filepath = vim.fn.expand("%:p") or "untitled"
    local content, line_start, line_end

    if selection_only then
        -- Use visual selection
        local _, sl, _ = unpack(vim.fn.getpos("'<"))
        local _, el, _ = unpack(vim.fn.getpos("'>"))
        content = table.concat(vim.fn.getline(sl, el), "\n")
        line_start = sl
        line_end = el

        -- Get the selection type (linewise, charwise, blockwise)
        local mode = vim.fn.visualmode()
        if mode ~= "V" then
            -- For charwise/blockwise, mark the range
            prompt = (prompt or "") .. string.format("\n\n[Selection: lines %d-%d, mode: %s]", sl, el, mode)
        end
    else
        content, line_start, line_end = get_smart_context()
    end

    if not content or content == "" then
        vim.notify("No content to send. Open a file or select text first.", vim.log.levels.WARN)
        return
    end

    -- Short title for the terminal tab
    local title_preview = (prompt or "analyze"):sub(1, 40)
    local fname = vim.fn.fnamemodify(filepath, ":t"):sub(1, 20)

    -- Build the pi command: pi @contextfile "prompt"
    local ctx_file = build_context_file(content, prompt, filepath, line_start, line_end)

    -- Escape prompt for shell
    local safe_prompt = (prompt or "analyze/improve this code"):gsub('"', '\\"')
    local cmd = string.format('%s @"%s" "%s" ', pi, ctx_file, safe_prompt)

    -- Open terminal
    local title = string.format("%s · %s", fname, title_preview)
    open_pi_terminal(cmd, title)
end

--- Pick a prompt from the registry and apply to current context
function M.pick_prompt()
    local ok, registry = pcall(require, "mlamkadm.core.LLM.prompts")
    if not ok or not registry or not registry.list then
        -- Fallback: use telescope to pick from pi prompt directory
        M.pick_pi_prompt_from_dir()
        return
    end

    local prompts = registry.list()
    if not prompts or vim.tbl_isempty(prompts) then
        vim.notify("No prompts in registry. Use :Pi <prompt> directly.", vim.log.levels.WARN)
        return
    end

    -- Use vim.ui.input with completion for prompt selection
    -- Simpler: use snacks/telescope picker
    local has_snacks, snacks = pcall(require, "snacks")
    if has_snacks then
        -- Build picker items from prompt registry
        local items = {}
        for name, info in pairs(prompts) do
            table.insert(items, {
                text = name,
                prompt_text = info.text or info,
                desc = info.desc or "",
            })
        end

        snacks.picker.pick(items, {
            title = "Pi Prompts",
            format = function(item)
                return item.text .. (item.desc and "  · " .. item.desc or "")
            end,
            confirm = function(picked)
                if picked then
                    M.send_to_pi(picked.prompt_text, false)
                end
            end,
        })
    else
        -- Fallback: plain input
        vim.ui.select(vim.tbl_keys(prompts), {
            prompt = "Select prompt:",
            format_item = function(name)
                return name .. (type(prompts[name]) == "table" and " · " .. (prompts[name].desc or "") or "")
            end,
        }, function(choice)
            if choice then
                local p = prompts[choice]
                M.send_to_pi(type(p) == "table" and p.text or p, false)
            end
        end)
    end
end

--- Pick a prompt from the pi agent prompts directory
function M.pick_pi_prompt_from_dir()
    local prompt_dir = vim.fn.expand("~/.pi/agent/prompts")
    if vim.fn.isdirectory(prompt_dir) == 0 then
        vim.notify("Pi prompts directory not found.", vim.log.levels.WARN)
        return
    end

    local has_snacks, snacks = pcall(require, "snacks")
    if has_snacks then
        snacks.picker.files({
            cwd = prompt_dir,
            title = "Pi Prompts",
            confirm = function(picked)
                if picked then
                    local prompt_path = prompt_dir .. "/" .. picked.file
                    local prompt_content = vim.fn.readfile(prompt_path)
                    -- Use the prompt as instruction
                    M.send_to_pi(table.concat(prompt_content, "\n"), false)
                end
            end,
        })
    else
        vim.cmd("e " .. prompt_dir)
    end
end

--- Quick prompt input — ask for instruction then send
function M.quick_prompt()
    vim.ui.input({
        prompt = "Pi prompt: ",
        default = "",
    }, function(input)
        if input and input ~= "" then
            M.send_to_pi(input, false)
        end
    end)
end

--- Quick prompt for visual selection
function M.quick_selection()
    vim.ui.input({
        prompt = "Pi (selection): ",
        default = "",
    }, function(input)
        M.send_to_pi(input or "analyze/improve this selection", true)
    end)
end

-- ──────────────────────────────────────
-- Setup
-- ──────────────────────────────────────

function M.setup()
    -- Create pi commands
    vim.api.nvim_create_user_command("Pi", function(opts)
        M.send_to_pi(opts.args ~= "" and opts.args or nil, false)
    end, {
        nargs = "?",
        desc = "Send buffer context to pi agent with optional prompt",
    })

    vim.api.nvim_create_user_command("PiSelection", function(opts)
        M.send_to_pi(opts.args ~= "" and opts.args or nil, true)
    end, {
        nargs = "?",
        range = true,
        desc = "Send visual selection to pi agent with optional prompt",
    })

    vim.api.nvim_create_user_command("PiPrompt", function()
        M.pick_prompt()
    end, {
        desc = "Pick a prompt from the pi prompt registry",
    })

    -- Keymaps
    vim.keymap.set("n", "<leader>pi", M.quick_prompt, { desc = "Pi: Quick prompt" })
    vim.keymap.set("v", "<leader>pi", M.quick_selection, { desc = "Pi: Selection + prompt" })
    vim.keymap.set("n", "<leader>pp", M.pick_prompt, { desc = "Pi: Pick prompt" })
end

return M
