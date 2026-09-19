-- cortex.lua — Cortex-Prime MK3 harness integration
--
-- Launches the cortex-mk3 binary in a managed terminal float and lets you pipe
-- context + a prompt from the current buffer into a running session, or run a
-- one-shot and capture the streaming XML protocol into a scratch buffer.
--
-- Commands:
--   :Cortex                 Open the harness TUI (interactive)
--   :CortexAgent [name]     Open the harness with a specific agent manifest
--   :CortexRun [prompt]     One-shot: prompt + capture XML into a buffer
--   :CortexPrompt           Quick prompt input (sends current buffer context)
--   :CortexResume           Pick a session to resume (-r)
--
-- Keymaps:
--   <leader>cx   open harness TUI
--   <leader>ca   open agent (manifest browser via bare -m)
--   <leader>cr   one-shot run with buffer context
--   <leader>cs   resume session

local M = {}

local default_bin = "cortex-mk3"

-- Resolve the harness binary: PATH first, then known repo locations.
local function get_bin()
    if vim.fn.executable(default_bin) == 1 then
        return default_bin
    end
    local candidates = {
        vim.fn.expand("~/repos/active/agent-lib-cpp/cortex-mk3"),
        vim.fn.expand("~/repos/active/Cortex-MK1/cortex-mk3"),
        vim.fn.expand("~/.local/bin/cortex-mk3"),
    }
    for _, p in ipairs(candidates) do
        if vim.fn.executable(p) == 1 then
            return p
        end
    end
    return nil
end

-- Smart context: full file if small, else the visible window.
local function get_smart_context()
    local bufnr = vim.api.nvim_get_current_buf()
    local total = vim.api.nvim_buf_line_count(bufnr)
    if total <= 200 then
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        return table.concat(lines, "\n"), vim.fn.expand("%:p")
    end
    local first = vim.fn.line("w0")
    local last = vim.fn.line("w$")
    local lines = vim.api.nvim_buf_get_lines(bufnr, first - 1, last, false)
    return table.concat(lines, "\n"), vim.fn.expand("%:p")
end

-- Open the harness in a managed terminal float (via the terminal manager), so
-- it participates in <C-j>/<C-k> cycling and the winbar dots.
local function open_harness(args, title)
    local bin = get_bin()
    if not bin then
        vim.notify("cortex-mk3 not found on PATH or in ~/repos/active", vim.log.levels.ERROR)
        return
    end
    local cmd = bin .. (args and (" " .. args) or "")
    local ok, term = pcall(require, "mlamkadm.core.terminal")
    if ok and term and term.toggle then
        term.toggle(cmd, { use_theme = false, title = title })
    else
        -- Fallback: plain split terminal (terminal manager not available).
        term = term or {}
        vim.cmd("split")
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, "buftype", "terminal")
        vim.api.nvim_set_current_buf(buf)
        vim.fn.termopen(cmd, { env = { TERM = "xterm-256color" } })
        vim.cmd("startinsert")
    end
end

-- Prompt -> one-shot --raw -> capture XML into a scratch buffer.
local function run_oneshot(prompt)
    local bin = get_bin()
    if not bin then
        vim.notify("cortex-mk3 not found", vim.log.levels.ERROR)
        return
    end
    prompt = prompt or ""
    local cmd =
        string.format("%s --raw --prompt %s --no-session --ephemeral --no-ansi", bin, vim.fn.shellescape(prompt))
    vim.notify("Running cortex-mk3 one-shot…", vim.log.levels.INFO)
    vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if not data then
                return
            end
            vim.schedule(function()
                local buf = vim.api.nvim_get_current_buf()
                local lines = vim.api.nvim_buf_get_lines(buf, -1, -1, true)
                local append = {}
                for _, l in ipairs(data) do
                    if l ~= "" then
                        append[#append + 1] = l
                    end
                end
                vim.api.nvim_buf_set_lines(buf, -1, -1, true, append)
            end)
        end,
        on_stderr = function(_, data)
            if data then
                vim.schedule(function()
                    vim.notify(vim.trim(table.concat(data, " ")), vim.log.levels.WARN)
                end)
            end
        end,
        on_exit = function(_, code)
            vim.schedule(function()
                vim.notify("cortex-mk3 exited (" .. tostring(code) .. ")", vim.log.levels.INFO)
            end)
        end,
    })
end

function M.open()
    open_harness(nil, "Cortex-MK3")
end

function M.open_agent(name)
    -- bare -m opens the manifest browser; a named agent opens directly.
    local args = name and ("--agent " .. vim.fn.shellescape(name)) or "-m"
    open_harness(args, "Cortex-MK3 Agent")
end

function M.run(prompt)
    if prompt and prompt ~= "" then
        run_oneshot(prompt)
    else
        local ctx, _ = get_smart_context()
        vim.ui.input({ prompt = "Cortex prompt: " }, function(input)
            if input and input ~= "" then
                run_oneshot(input)
            end
        end)
    end
end

function M.resume()
    open_harness("-r", "Cortex-MK3 Resume")
end

function M.quick_prompt()
    vim.ui.input({ prompt = "Cortex: " }, function(input)
        if input and input ~= "" then
            run_oneshot(input)
        end
    end)
end

function M.setup()
    vim.api.nvim_create_user_command("Cortex", M.open, { desc = "Cortex-MK3: open harness TUI" })
    vim.api.nvim_create_user_command("CortexAgent", function(opts)
        M.open_agent(opts.args ~= "" and opts.args or nil)
    end, { nargs = "?", desc = "Cortex-MK3: open agent (or browser)" })
    vim.api.nvim_create_user_command("CortexRun", function(opts)
        M.run(opts.args ~= "" and opts.args or nil)
    end, { nargs = "?", desc = "Cortex-MK3: one-shot run + capture XML" })
    vim.api.nvim_create_user_command("CortexResume", M.resume, { desc = "Cortex-MK3: resume session" })
    vim.api.nvim_create_user_command("CortexPrompt", M.quick_prompt, { desc = "Cortex-MK3: quick prompt" })

    vim.keymap.set("n", "<leader>cx", M.open, { desc = "Cortex: Open harness" })
    vim.keymap.set("n", "<leader>ca", function()
        M.open_agent()
    end, { desc = "Cortex: Open agent browser" })
    vim.keymap.set("n", "<leader>cr", function()
        M.run()
    end, { desc = "Cortex: One-shot run" })
    vim.keymap.set("n", "<leader>cs", M.resume, { desc = "Cortex: Resume session" })
end

return M
