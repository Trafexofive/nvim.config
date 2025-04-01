-- ollama.nvim: A Neovim plugin for interacting with Ollama local LLMs
-- Author: Claude
-- License: MIT

local M = {}
local api = vim.api
local fn = vim.fn

-- Default configuration
M.config = {
    host = "http://localhost",
    port = 11434,
    default_model = "mistral:7b",
    models = {
        "llama2",
        "codellama",
        "mistral",
        "phi2",
        "gemma"
    },
    keymaps = {
        prompt = "<leader>op", -- Open prompt
        inline = "<leader>oi", -- Generate inline completion
        selection = "<leader>os", -- Process selection
        chat = "<leader>oc",  -- Open chat window
    },
    window = {
        width = 0.8, -- Percentage of screen width
        height = 0.7, -- Percentage of screen height
        border = "rounded",
    },
    timeout = 30000, -- Request timeout in ms
    stream = true, -- Stream responses
}

-- Store the buffer for chat interface
M.buf = nil
M.win = nil
M.prompt_history = {}
M.history_index = 0
M.chat_history = {}
M.model = nil

-- Utility function to make API requests to Ollama
local function ollama_request(endpoint, data, callback)
    local curl_cmd = string.format(
        "curl -s -X POST %s:%d/api/%s -H 'Content-Type: application/json' -d '%s'",
        M.config.host,
        M.config.port,
        endpoint,
        vim.json.encode(data)
    )

    local handle = io.popen(curl_cmd)
    if not handle then
        vim.notify("Failed to execute curl command", vim.log.levels.ERROR)
        return
    end

    local result = handle:read("*a")
    handle:close()

    local ok, parsed = pcall(vim.json.decode, result)
    if not ok then
        vim.notify("Failed to parse JSON response: " .. result, vim.log.levels.ERROR)
        return
    end

    if callback then
        callback(parsed)
    end

    return parsed
end

-- Get available models from Ollama
function M.get_models(callback)
    ollama_request("tags", {}, function(response)
        if response and response.models then
            callback(response.models)
        else
            vim.notify("Failed to fetch models", vim.log.levels.ERROR)
        end
    end)
end

-- Create floating window for chat/prompts
function M.create_window()
    -- Calculate window size
    local width = math.floor(vim.o.columns * M.config.window.width)
    local height = math.floor(vim.o.lines * M.config.window.height)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create buffer if it doesn't exist
    if not M.buf or not api.nvim_buf_is_valid(M.buf) then
        M.buf = api.nvim_create_buf(false, true)
        api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
        api.nvim_buf_set_option(M.buf, 'bufhidden', 'hide')
    end

    -- Window options
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = M.config.window.border,
        title = " Ollama Chat ",
        title_pos = "center",
    }

    -- Create window
    if not M.win or not api.nvim_win_is_valid(M.win) then
        M.win = api.nvim_open_win(M.buf, true, opts)
        api.nvim_win_set_option(M.win, 'wrap', true)
        api.nvim_win_set_option(M.win, 'linebreak', true)
    else
        api.nvim_win_set_config(M.win, opts)
    end

    -- Return to window if it exists
    api.nvim_set_current_win(M.win)

    -- Set some keymaps for the chat buffer
    local buffer_maps = {
        ["<Esc>"] = ":lua require('ollama').close_window()<CR>",
        ["q"] = ":lua require('ollama').close_window()<CR>",
        ["<C-c>"] = ":lua require('ollama').close_window()<CR>",
        ["<C-k>"] = ":lua require('ollama').scroll_up()<CR>",
        ["<C-j>"] = ":lua require('ollama').scroll_down()<CR>",
    }

    for k, v in pairs(buffer_maps) do
        api.nvim_buf_set_keymap(M.buf, 'n', k, v, { noremap = true, silent = true })
    end

    return M.buf, M.win
end

-- Close the floating window
function M.close_window()
    if M.win and api.nvim_win_is_valid(M.win) then
        api.nvim_win_close(M.win, true)
        M.win = nil
    end
end

-- Scroll functions for chat window
function M.scroll_up()
    local cursor = api.nvim_win_get_cursor(M.win)
    if cursor[1] > 1 then
        api.nvim_win_set_cursor(M.win, { cursor[1] - 1, cursor[2] })
    end
end

function M.scroll_down()
    local cursor = api.nvim_win_get_cursor(M.win)
    local line_count = api.nvim_buf_line_count(M.buf)
    if cursor[1] < line_count then
        api.nvim_win_set_cursor(M.win, { cursor[1] + 1, cursor[2] })
    end
end

-- Open a prompt input for quick queries
function M.open_prompt()
    local model = M.model or M.config.default_model
    local prompt = vim.fn.input({
        prompt = "Ollama (" .. model .. "): ",
        completion = "customlist,v:lua.require'ollama'.complete_prompt",
        cancelreturn = "",
    })

    if prompt and prompt ~= "" then
        table.insert(M.prompt_history, prompt)
        M.history_index = #M.prompt_history + 1

        M.create_window()
        api.nvim_buf_set_lines(M.buf, 0, -1, false, {
            "# Query",
            prompt,
            "",
            "# Response",
            "Thinking..."
        })

        M.generate_completion(prompt, nil, function(response)
            if response and response.response then
                api.nvim_buf_set_lines(M.buf, 4, 5, false, vim.split(response.response, "\n"))
            else
                api.nvim_buf_set_lines(M.buf, 4, 5, false, { "Error: Failed to get response" })
            end
        end)
    end
end

-- Generate inline completion at cursor position
function M.inline_completion()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_get_current_line()
    local prefix = string.sub(line, 1, col)

    if prefix:match("^%s*$") then
        vim.notify("Please provide some context for inline completion", vim.log.levels.WARN)
        return
    end

    -- Get the few lines before cursor for context
    local start_row = math.max(1, row - 10)
    local context_lines = api.nvim_buf_get_lines(0, start_row - 1, row, false)
    local context = table.concat(context_lines, "\n")

    local prompt = "Continue the following code or text. Only provide the continuation:\n\n" .. context

    -- Create a temporary notification
    vim.notify("Generating completion...", vim.log.levels.INFO)

    M.generate_completion(prompt, nil, function(response)
        if response and response.response then
            -- Get completion text and remove leading whitespace
            local completion_text = response.response:gsub("^%s+", "")

            -- Insert the completion at cursor position
            local new_line = prefix .. completion_text
            api.nvim_set_current_line(new_line)
            api.nvim_win_set_cursor(0, { row, #new_line })
        else
            vim.notify("Failed to get completion", vim.log.levels.ERROR)
        end
    end)
end

-- Process selected text with Ollama
function M.process_selection()
    -- Get visual selection
    local start_pos = fn.getpos("'<")
    local end_pos = fn.getpos("'>")
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]

    -- Get selected text
    local lines
    if start_row == end_row then
        local line = api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
        lines = { line:sub(start_col, end_col) }
    else
        lines = api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
        if #lines > 0 then
            lines[1] = lines[1]:sub(start_col)
            lines[#lines] = lines[#lines]:sub(1, end_col)
        end
    end

    local selected_text = table.concat(lines, "\n")

    -- Get the action to perform
    local actions = {
        "Explain this code",
        "Improve this code",
        "Optimize this code",
        "Document this code",
        "Find bugs in this code",
        "Complete this code",
        "Summarize this text",
        "Other (custom prompt)",
    }

    vim.ui.select(actions, {
        prompt = "What do you want to do with the selection?",
    }, function(choice)
        if not choice then return end

        local prompt
        if choice == "Other (custom prompt)" then
            prompt = vim.fn.input({
                prompt = "Custom prompt: ",
                cancelreturn = "",
            })
            if prompt == "" then return end
            prompt = prompt .. ":\n\n" .. selected_text
        else
            prompt = choice .. ":\n\n" .. selected_text
        end

        -- Create window for response
        M.create_window()
        api.nvim_buf_set_lines(M.buf, 0, -1, false, {
            "# Selection",
            selected_text,
            "",
            "# " .. choice,
            "Thinking..."
        })

        M.generate_completion(prompt, nil, function(response)
            if response and response.response then
                api.nvim_buf_set_lines(M.buf, 4, 5, false, vim.split(response.response, "\n"))
            else
                api.nvim_buf_set_lines(M.buf, 4, 5, false, { "Error: Failed to get response" })
            end
        end)
    end)
end

-- Open chat interface with persistent history
function M.open_chat()
    M.create_window()

    -- If we don't have a model selected, prompt for one
    if not M.model then
        M.select_model(function()
            M.display_chat_history()
        end)
    else
        M.display_chat_history()
    end
end

-- Display the chat history in the buffer
function M.display_chat_history()
    local lines = { "# Ollama Chat (" .. (M.model or M.config.default_model) .. ")", "" }

    -- Add chat history
    for _, msg in ipairs(M.chat_history) do
        table.insert(lines, "## " .. msg.role)
        table.insert(lines, "")
        for _, line in ipairs(vim.split(msg.content, "\n")) do
            table.insert(lines, line)
        end
        table.insert(lines, "")
    end

    -- Add prompt for user input
    table.insert(lines, "## You")
    table.insert(lines, "")
    table.insert(lines, "_Type your message here and press <C-Enter> to send_")

    -- Set the buffer content
    api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)

    -- Move cursor to the last line
    api.nvim_win_set_cursor(M.win, { #lines, 0 })

    -- Enter insert mode
    vim.cmd("startinsert!")

    -- Set keymap for sending the message
    api.nvim_buf_set_keymap(M.buf, 'i', '<C-CR>',
        "<Esc>:lua require('ollama').send_chat_message()<CR>",
        { noremap = true, silent = true }
    )
end

-- Send a message from the chat interface
function M.send_chat_message()
    -- Get current buffer content
    local lines = api.nvim_buf_get_lines(M.buf, 0, -1, false)

    -- Find the start of the user's latest message
    local start_idx = 0
    for i = #lines, 1, -1 do
        if lines[i] == "## You" then
            start_idx = i + 2 -- +2 to skip the "## You" line and the empty line
            break
        end
    end

    if start_idx == 0 then return end

    -- Extract the message
    local message_lines = {}
    for i = start_idx, #lines do
        local line = lines[i]
        if line ~= "_Type your message here and press <C-Enter> to send_" then
            table.insert(message_lines, line)
        end
    end

    local message = table.concat(message_lines, "\n")
    message = message:gsub("^%s+", ""):gsub("%s+$", "")

    if message == "" then
        vim.notify("Please enter a message", vim.log.levels.WARN)
        return
    end

    -- Add the message to chat history
    table.insert(M.chat_history, {
        role = "You",
        content = message
    })

    -- Update the display with a "thinking" message
    table.insert(M.chat_history, {
        role = "Ollama",
        content = "Thinking..."
    })

    M.display_chat_history()

    -- Generate response
    local messages = {}
    for _, msg in ipairs(M.chat_history) do
        table.insert(messages, {
            role = msg.role == "You" and "user" or "assistant",
            content = msg.content
        })
    end

    -- Remove the "thinking" message
    table.remove(M.chat_history)

    ollama_request("chat", {
        model = M.model or M.config.default_model,
        messages = messages,
        stream = M.config.stream
    }, function(response)
        if response and response.message and response.message.content then
            -- Add the response to chat history
            table.insert(M.chat_history, {
                role = "Ollama",
                content = response.message.content
            })

            -- Update the display
            M.display_chat_history()
        else
            vim.notify("Failed to get chat response", vim.log.levels.ERROR)
            -- Remove the thinking message
            table.remove(M.chat_history)
            M.display_chat_history()
        end
    end)
end

-- Generate completion with Ollama
function M.generate_completion(prompt, model, callback)
    ollama_request("generate", {
        model = model or M.model or M.config.default_model,
        prompt = prompt,
        stream = false
    }, callback)
end

-- Select a model from available models
function M.select_model(callback)
    M.get_models(function(models)
        local model_names = {}
        for _, model in ipairs(models) do
            table.insert(model_names, model.name)
        end

        vim.ui.select(model_names, {
            prompt = "Select Ollama model:",
        }, function(choice)
            if choice then
                M.model = choice
                vim.notify("Using model: " .. choice, vim.log.levels.INFO)
                if callback then callback() end
            end
        end)
    end)
end

-- Command completion for prompts
function M.complete_prompt(arg_lead, cmd_line, cursor_pos)
    local results = {}
    if #M.prompt_history == 0 then
        return results
    end

    arg_lead = arg_lead:lower()
    for i = #M.prompt_history, 1, -1 do
        local item = M.prompt_history[i]
        if arg_lead == "" or item:lower():find(arg_lead, 1, true) then
            table.insert(results, item)
        end
    end

    return results
end

-- Setup function
function M.setup(user_config)
    -- Merge user config with defaults
    if user_config then
        for k, v in pairs(user_config) do
            if type(v) == "table" and type(M.config[k]) == "table" then
                for k2, v2 in pairs(v) do
                    M.config[k][k2] = v2
                end
            else
                M.config[k] = v
            end
        end
    end

    -- Set keymaps
    vim.keymap.set('n', M.config.keymaps.prompt, function() M.open_prompt() end, { desc = "Ollama: Open prompt" })
    vim.keymap.set('n', M.config.keymaps.inline, function() M.inline_completion() end,
        { desc = "Ollama: Inline completion" })
    vim.keymap.set('v', M.config.keymaps.selection, function() M.process_selection() end,
        { desc = "Ollama: Process selection" })
    vim.keymap.set('n', M.config.keymaps.chat, function() M.open_chat() end, { desc = "Ollama: Open chat" })

    -- Create user commands
    vim.api.nvim_create_user_command("OllamaPrompt", function() M.open_prompt() end, {})
    vim.api.nvim_create_user_command("OllamaInline", function() M.inline_completion() end, {})
    vim.api.nvim_create_user_command("OllamaChat", function() M.open_chat() end, {})
    vim.api.nvim_create_user_command("OllamaSelectModel", function() M.select_model() end, {})
end

return M
