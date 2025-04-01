local M = {}

-- Configuration
local config = {
    api_key = "AIzaSyDRKg7kYPJPSCxYhsSWC73xK1iCoaDA3Z4",
    model = "gemini-1.5-pro-latest",
    max_tokens = 2048,
    temperature = 0.3,
    popup_border = "rounded",
    prompt_prefix = "%% " -- Trigger for copilot suggestions
}

-- Custom prompts registry
local prompts = {
    explain = "Explain this code in simple terms:",
    improve = "Improve this code with better practices:",
    docstring = "Write a detailed docstring for this code:",
    debug = "Help debug this code. What's wrong with it?"
}

-- Track floating windows
local windows = {}

local function close_windows()
    for _, win in ipairs(windows) do
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end
    windows = {}
end

local function show_popup(content, title)
    close_windows()

    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.min(math.floor(vim.o.columns * 0.8), 80)
    local height = math.min(math.floor(vim.o.lines * 0.8), 20)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        style = "minimal",
        border = config.popup_border,
        title = title or "Gemini Response"
    })

    table.insert(windows, win)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    vim.api.nvim_create_autocmd({ "BufHidden", "BufLeave" }, {
        buffer = buf,
        callback = close_windows,
        once = true
    })
end

local function get_visual_selection()
    local s_start = vim.fn.getpos("'<")
    local s_end = vim.fn.getpos("'>")
    local lines = vim.fn.getline(s_start[2], s_end[2])

    if #lines == 0 then return "" end

    lines[1] = string.sub(lines[1], s_start[3], -1)
    if #lines == 1 then
        lines[#lines] = string.sub(lines[#lines], 1, s_end[3] - s_start[3] + 1)
    else
        lines[#lines] = string.sub(lines[#lines], 1, s_end[3])
    end

    return table.concat(lines, "\n")
end

local function query_gemini(prompt, context)
    local full_prompt = context and (context .. "\n\n" .. prompt) or prompt

    local cmd = string.format(
        [[curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s" ]] ..
        [[-H "Content-Type: application/json" ]] ..
        [[-d '{"contents":[{"parts":[{"text":"%s"}]}],"generationConfig":{"temperature":%f,"maxOutputTokens":%d}}']],
        config.model,
        config.api_key,
        full_prompt:gsub('"', '\\"'):gsub("\n", "\\n"),
        config.temperature,
        config.max_tokens
    )

    local handle = io.popen(cmd)
    if not handle then return nil, "Failed to execute curl command" end

    local result = handle:read("*a")
    handle:close()

    local ok, response = pcall(vim.json.decode, result)
    if not ok then return nil, "Failed to parse JSON response" end

    if response.error then
        return nil, response.error.message
    end

    if response.candidates and response.candidates[1] then
        return response.candidates[1].content.parts[1].text
    end

    return nil, "No response from API"
end

-- Auto-complete handler
local function copilot_complete()
    local line = vim.api.nvim_get_current_line()
    local prefix = line:match(config.prompt_prefix .. "(.*)$")
    if not prefix then return {} end

    local response, err = query_gemini(prefix)
    if not response then
        vim.notify("Gemini error: " .. err, vim.log.levels.ERROR)
        return {}
    end

    local suggestions = {}
    for line in response:gmatch("[^\n]+") do
        table.insert(suggestions, {
            word = line:gsub("^%s+", ""),
            menu = "[Gemini]"
        })
    end

    return suggestions
end

-- Visual mode prompt application
function M.apply_prompt(prompt_name)
    local context = get_visual_selection()
    local prompt = prompts[prompt_name]

    if not prompt then
        vim.notify("Unknown prompt: " .. prompt_name, vim.log.levels.ERROR)
        return
    end

    vim.schedule(function()
        local response, err = query_gemini(prompt, context)
        if not response then
            vim.notify("Gemini error: " .. err, vim.log.levels.ERROR)
            return
        end

        show_popup(response, "Gemini: " .. prompt_name)
    end)
end

-- Custom query interface
function M.custom_query()
    vim.ui.input({ prompt = "Gemini Query: " }, function(input)
        if not input or input == "" then return end

        local context = get_visual_selection()
        vim.schedule(function()
            local response, err = query_gemini(input, context)
            if not response then
                vim.notify("Gemini error: " .. err, vim.log.levels.ERROR)
                return
            end

            show_popup(response, "Gemini Response")
        end)
    end)
end

-- Setup function
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})

    -- -- Set up auto-complete
    -- vim.api.nvim_create_autocmd("FileType", {
    --     pattern = "*",
    --     callback = function()
    --         vim.bo.omnifunc = "v:lua.require'gemini'.copilot_complete"
    --     end
    -- })

    -- Add user commands
    vim.api.nvim_create_user_command("GeminiPrompt", function(args)
        M.apply_prompt(args.args)
    end, { nargs = 1, complete = function() return vim.tbl_keys(prompts) end })

    vim.api.nvim_create_user_command("GeminiQuery", function()
        M.custom_query()
    end, {})

    -- Example key mappings
    vim.keymap.set("v", "<leader>ge", function() M.apply_prompt("explain") end)
    vim.keymap.set("v", "<leader>gi", function() M.apply_prompt("improve") end)
    vim.keymap.set("v", "<leader>gq", M.custom_query)
end

return M
