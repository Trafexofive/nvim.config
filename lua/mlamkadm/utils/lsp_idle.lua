-- lua/mlamkadm/utils/lsp_idle.lua
-- LSP idle policy: release resident project-index memory for the heavy
-- language servers (clangd, pyright, jdtls, rust-analyzer) after a period of
-- inactivity, and transparently re-attach when the user returns to a buffer.
--
-- Rationale: these servers keep their (large) project index resident even on
-- idle. clangd alone held ~446MB resident across duplicate instances. Stopping
-- on idle trims that baseline; resuming on use trades a cold start (0.5-3s,
-- masked while the buffer is empty on reentry) for a much lower idle footprint.

local M = {}

-- Which servers to govern (the resident-index hogs). Keyed by the name
-- vim.lsp reports (client.name), which matches the lspconfig server name.
local HEAVY = {
    clangd = true,
    pyright = true,
    jdtls = true,
    rust_analyzer = true,
}

-- filetype -> heavy server(s). Used only to know whether to resume.
local FT_TO_SERVER = {
    c = "clangd",
    cpp = "clangd",
    cuda = "clangd",
    objc = "clangd",
    objcpp = "clangd",
    python = "pyright",
    java = "jdtls",
    rust = "rust_analyzer",
}

-- Defaults; overridable via M.setup().
local idle_timeout_ms = (20 * 60) * 1000
local check_interval_ms = 30 * 1000

local last_activity_ms = (vim.uv or vim.loop).now()
local check_timer = nil

-- root_dir -> true for servers we stopped because the user went idle.
-- Used to decide when to resume (only re-attach servers we actually released).
local idle_stopped_roots = {}

--- Reset the idle clock on any user activity.
local function mark_activity()
    last_activity_ms = (vim.uv or vim.loop).now()
end

--- Stop all governed (heavy) clients that are currently running.
local function stop_idle_clients()
    for _, client in ipairs(vim.lsp.get_clients()) do
        local name = client.name or (client.config and client.config.name) or ""
        if HEAVY[name] then
            local root = client.config and client.config.root_dir
            if root then
                idle_stopped_roots[root] = true
            end
            -- Graceful stop (nvim 0.12: vim.lsp.stop_client is deprecated; use the
            -- client method). Revertible: the server is re-attached on use.
            pcall(function()
                client.stop(false)
            end)
        end
    end
end

--- Re-attach a heavy server for the current buffer if we stopped it on idle.
local function maybe_resume(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].buftype == "nofile" then
        return
    end

    local server = FT_TO_SERVER[vim.bo[bufnr].filetype]
    if not server then
        return
    end

    local file = vim.api.nvim_buf_get_name(bufnr)
    if file == "" then
        return
    end

    -- Only resume for a project root we actually released: match by prefix so a
    -- buffer nested anywhere under a stopped root resumes it.
    local matching_root = nil
    for root in pairs(idle_stopped_roots) do
        if file == root or vim.startswith(file .. "/", root .. "/") then
            matching_root = root
            break
        end
    end
    if not matching_root then
        return
    end

    -- Already running again (e.g. another buffer re-attached this root).
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        local name = client.name or (client.config and client.config.name) or ""
        if name == server then
            idle_stopped_roots[matching_root] = nil
            return
        end
    end

    idle_stopped_roots[matching_root] = nil
    -- Re-start the heavy server exactly the way lspconfig autostarts it: clear the
    -- per-buffer attach guard (if any) and re-fire the FileType autocmd. This
    -- avoids the deprecated require('lspconfig')[server] framework entirely.
    pcall(vim.api.nvim_buf_del_var, bufnr, server)
    vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr, modeline = false })
end

--- Periodic idle sweep.
local function check_and_act()
    local now = (vim.uv or vim.loop).now()
    if now - last_activity_ms >= idle_timeout_ms then
        stop_idle_clients()
    end
end

local group = nil

--- Start the idle policy.
--- @param opts? {idle_min?: integer, check_sec?: integer}
function M.setup(opts)
    opts = opts or {}
    idle_timeout_ms = (opts.idle_min or 20) * 60 * 1000
    check_interval_ms = (opts.check_sec or 30) * 1000

    if group then
        vim.api.nvim_del_augroup_by_id(group)
    end
    group = vim.api.nvim_create_augroup("HEavyLspIdlePolicy", { clear = true })
    --- stylua: ignore start
    vim.api.nvim_create_autocmd(
        { "CursorMoved", "CursorMovedI", "InsertEnter", "TextChanged", "TextChangedI" },
        { group = group, callback = mark_activity, desc = "lsp_idle: reset idle clock on activity" }
    )
    -- Resume when the user re-enters / edits a buffer after an idle stop.
    vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "InsertEnter" }, {
        group = group,
        callback = function(ev)
            maybe_resume(ev.buf)
        end,
        desc = "lsp_idle: re-attach heavy server on use",
    })
    --- stylua: ignore end

    if check_timer then
        check_timer:stop()
        check_timer:close()
    end
    check_timer = (vim.uv or vim.loop).new_timer()
    check_timer:start(check_interval_ms, check_interval_ms, vim.schedule_wrap(check_and_act))
end

-- Debug / test hooks (also usable via :lua for manual control).
M.stop_now = stop_idle_clients
M.resume_now = function(bufnr)
    return maybe_resume(bufnr or vim.api.nvim_get_current_buf())
end
M.set_timeout_min = function(min)
    idle_timeout_ms = min * 60 * 1000
end
M._state = function()
    return { last_activity_ms = last_activity_ms, stuck_roots = vim.tbl_keys(idle_stopped_roots) }
end

return M
