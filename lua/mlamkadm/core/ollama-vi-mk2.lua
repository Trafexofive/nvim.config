-- -- ollama.nvim: A minimal Neovim plugin for processing visual selections with streamed responses from Ollama
-- -- Author: Claude
-- -- License: MIT
--
-- local M = {}
-- local api = vim.api
-- local fn = vim.fn
--
-- -- Minimal configuration
-- M.config = {
--   host = "http://localhost",
--   port = 11434,
--   default_model = "mistral:7b",
--   keymaps = {
--     selection = "<leader>os", -- Process selection (visual mode)
--   },
--   window = {
--     width = 0.8,   -- Percentage of screen width
--     height = 0.7,  -- Percentage of screen height
--     border = "rounded",
--   },
--   timeout = 30000, -- Request timeout in ms
--   stream = true,   -- Enable streaming responses
-- }
--
-- -- Buffer for the floating window
-- M.buf = nil
-- M.win = nil
--
-- -----------------------------------------------------------
-- -- Utility: Make a non-streaming API request.
-- -----------------------------------------------------------
-- local function ollama_request(endpoint, data, callback)
--   local curl_cmd = string.format(
--     "curl -s -X POST %s:%d/api/%s -H 'Content-Type: application/json' -d '%s'",
--     M.config.host,
--     M.config.port,
--     endpoint,
--     vim.json.encode(data)
--   )
--
--   local handle = io.popen(curl_cmd)
--   if not handle then
--     vim.notify("Failed to execute curl command", vim.log.levels.ERROR)
--     return
--   end
--
--   local result = handle:read("*a")
--   handle:close()
--
--   local ok, parsed = pcall(vim.json.decode, result)
--   if not ok then
--     vim.notify("Failed to parse JSON response: " .. result, vim.log.levels.ERROR)
--     return
--   end
--
--   if callback then
--     callback(parsed)
--   end
--
--   return parsed
-- end
--
-- -----------------------------------------------------------
-- -- Create a floating window for displaying responses.
-- -----------------------------------------------------------
-- function M.create_window()
--   local width = math.floor(vim.o.columns * M.config.window.width)
--   local height = math.floor(vim.o.lines * M.config.window.height)
--   local row = math.floor((vim.o.lines - height) / 2)
--   local col = math.floor((vim.o.columns - width) / 2)
--
--   if not M.buf or not api.nvim_buf_is_valid(M.buf) then
--     M.buf = api.nvim_create_buf(false, true)
--     api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
--     api.nvim_buf_set_option(M.buf, 'bufhidden', 'hide')
--   end
--
--   local opts = {
--     relative = 'editor',
--     width = width,
--     height = height,
--     row = row,
--     col = col,
--     style = 'minimal',
--     border = M.config.window.border,
--     title = " Ollama Response ",
--     title_pos = "center",
--   }
--
--   if not M.win or not api.nvim_win_is_valid(M.win) then
--     M.win = api.nvim_open_win(M.buf, true, opts)
--     api.nvim_win_set_option(M.win, 'wrap', true)
--     api.nvim_win_set_option(M.win, 'linebreak', true)
--   else
--     api.nvim_win_set_config(M.win, opts)
--   end
--
--   api.nvim_set_current_win(M.win)
--   return M.buf, M.win
-- end
--
-- -----------------------------------------------------------
-- -- Generate a completion using the Ollama server.
-- -- If streaming is enabled, update the response window live.
-- -----------------------------------------------------------
-- function M.generate_completion(prompt, model, callback)
--   if M.config.stream then
--     local args = {
--       "-s",             -- silent
--       "-N",             -- disable buffering
--       "-X", "POST",
--       string.format("%s:%d/api/generate", M.config.host, M.config.port),
--       "-H", "Content-Type: application/json",
--       "-d", vim.json.encode({
--           model = model or M.config.default_model,
--           prompt = prompt,
--           stream = true
--       })
--     }
--     local stdout = vim.loop.new_pipe(false)
--     local response_lines = {}
--     local buf, _ = M.create_window()
--     local function on_read(err, chunk)
--       if err then
--         vim.schedule(function()
--           vim.notify("Error reading stream: " .. err, vim.log.levels.ERROR)
--         end)
--         return
--       end
--       if chunk then
--         for line in string.gmatch(chunk, "[^\r\n]+") do
--           local ok, data = pcall(vim.json.decode, line)
--           if ok and data and data.response then
--             table.insert(response_lines, data.response)
--             vim.schedule(function()
--               local current = table.concat(response_lines, "")
--               -- Split the current response into individual lines
--               local new_lines = vim.split(current, "\n", { plain = true })
--               local total = api.nvim_buf_line_count(buf)
--               -- Replace the last line with the new_lines table
--               api.nvim_buf_set_lines(buf, total - 1, total, false, new_lines)
--             end)
--           end
--         end
--       end
--     end
--
--     local handle
--     handle = vim.loop.spawn("curl", {
--       args = args,
--       stdio = { nil, stdout, nil }
--     }, function(code, signal)
--       stdout:close()
--       handle:close()
--       if callback then
--         callback({ response = table.concat(response_lines, "") })
--       end
--     end)
--     stdout:read_start(on_read)
--   else
--     ollama_request("generate", {
--       model = model or M.config.default_model,
--       prompt = prompt,
--       stream = false
--     }, callback)
--   end
-- end
--
-- -----------------------------------------------------------
-- -- Process the currently selected text in visual mode.
-- -----------------------------------------------------------
-- function M.process_selection()
--   local start_pos = fn.getpos("'<")
--   local end_pos = fn.getpos("'>")
--   local start_row, start_col = start_pos[2], start_pos[3]
--   local end_row, end_col = end_pos[2], end_pos[3]
--
--   local lines
--   if start_row == end_row then
--     local line = api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
--     lines = { line:sub(start_col, end_col) }
--   else
--     lines = api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
--     if #lines > 0 then
--       lines[1] = lines[1]:sub(start_col)
--       lines[#lines] = lines[#lines]:sub(1, end_col)
--     end
--   end
--
--   local selected_text = table.concat(lines, "\n")
--   local action_choices = {
--     "Explain this code",
--     "Improve this code",
--     "Optimize this code",
--     "Document this code",
--     "Find bugs in this code",
--     "Complete this code",
--     "Summarize this text",
--     "Other (custom prompt)",
--   }
--
--   vim.ui.select(action_choices, {
--     prompt = "What do you want to do with the selection?",
--   }, function(choice)
--     if not choice then return end
--
--     local prompt_text
--     if choice == "Other (custom prompt)" then
--       prompt_text = vim.fn.input({ prompt = "Custom prompt: ", cancelreturn = "" })
--       if prompt_text == "" then return end
--       prompt_text = prompt_text .. ":\n\n" .. selected_text
--     else
--       prompt_text = choice .. ":\n\n" .. selected_text
--     end
--
--     local selection_lines = vim.split(selected_text, "\n", { plain = true })
--     local header_lines = {}
--     table.insert(header_lines, "# Selection")
--     for _, l in ipairs(selection_lines) do
--       table.insert(header_lines, l)
--     end
--     table.insert(header_lines, "")
--     table.insert(header_lines, "# " .. choice)
--     table.insert(header_lines, "Thinking...")
--
--     M.create_window()
--     api.nvim_buf_set_lines(M.buf, 0, -1, false, header_lines)
--
--     M.generate_completion(prompt_text, nil, function(response)
--       if not M.config.stream then
--         if response and response.response then
--           local response_lines = vim.split(response.response, "\n", { plain = true })
--           api.nvim_buf_set_lines(M.buf, #header_lines - 1, #header_lines, false, response_lines)
--         else
--           api.nvim_buf_set_lines(M.buf, #header_lines - 1, #header_lines, false, { "Error: Failed to get response" })
--         end
--       end
--     end)
--   end)
-- end
--
-- -----------------------------------------------------------
-- -- Setup the plugin and map the visual mode selection key.
-- -----------------------------------------------------------
-- function M.setup(user_config)
--   if user_config then
--     M.config = vim.tbl_deep_extend("force", M.config, user_config)
--   end
--
--   vim.keymap.set('v', M.config.keymaps.selection, function() M.process_selection() end,
--     { desc = "Ollama: Process visual selection" }
--   )
--
--   vim.api.nvim_create_user_command("OllamaSelection", function() M.process_selection() end, {})
-- end
--
-- return M
--
-- function M.generate_completion(prompt, model, callback)
--   local model_name = model or M.config.default_model
--   local buf, win = M.create_window()
--
--   -- Add initial content to buffer
--   local header = string.format("# Processing with %s\n\n", model_name)
--   M.update_buffer_content(buf, header)
--
--   if M.config.stream then
--     local args = {
--       "-s",             -- silent
--       "-N",             -- disable buffering
--       "-X", "POST",
--       string.format("%s:%d/api/generate", M.config.host, M.config.port),
--       "-H", "Content-Type: application/json",
--       "-d", vim.json.encode({
--           model = model_name,
--           prompt = prompt,
--           stream = true
--       })
--     }
--
--     local stdout = vim.loop.new_pipe(false)
--     local response_text = ""
--     local is_first_update = true
--
--     local function on_read(err, chunk)
--       if err then
--         vim.schedule(function()
--           vim.notify("Error reading stream: " .. err, vim.log.levels.ERROR)
--           M.update_buffer_content(buf, header .. "Error: " .. err)
--         end)
--         return
--       end
--
--       if chunk then
--         vim.schedule(function()
--           if not api.nvim_buf_is_valid(buf) then
--             return
--           end
--
--           -- Process the JSON lines in the chunk
--           for line in string.gmatch(chunk, "[^\r\n]+") do
--             local ok, data = pcall(vim.json.decode, line)
--             if ok and data and data.response then
--               response_text = response_text .. data.response
--
--               -- Only update the buffer if window is still valid
--               if api.nvim_win_is_valid(win) then
--                 local display_text = header .. response_text
--
--                 -- For the first update, replace the entire buffer
--                 -- For subsequent updates, append to existing content
--                 if is_first_update then
--                   api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(display_text, "\n", { plain = true }))
--                   is_first_update = false
--                 else
--                   local lines = vim.split(display_text, "\n", { plain = true })
--                   api.nvim_buf_set_lines(buf, 0, -1, false, lines)
--                 end
--
--                 -- Auto-scroll to bottom if cursor was at the bottom
--                 local cursor_pos = api.nvim_win_get_cursor(win)
--                 local line_count = api.nvim_buf_line_count(buf)
--                 if cursor_pos[1] >= line_count - 2 then
--                   api.nvim_win_set_cursor(win, {line_count, 0})
--                 end
--               end
--             end
--
--             -- Check if we're done
--             if ok and data and data.done then
--               -- Finished generating
--             end
--           end
--         end)
--       end
--     end
--
--     -- Handle process lifecycle
--     local stderr = vim.loop.new_pipe(false)
--     local handle
--     handle = vim.loop.spawn("curl", {
--       args = args,
--       stdio = { nil, stdout, stderr }
--     }, function(code, signal)
--       stdout:close()
--       stderr:close()
--       handle:close()
--
--       vim.schedule(function()
--         if code ~= 0 then
--           vim.notify("Ollama request failed with code: " .. code, vim.log.levels.ERROR)
--         end
--
--         if callback then
--           callback({ response = response_text, code = code })
--         end
--       end)
--     end)
--
--     -- Start reading from stdout and stderr
--     stdout:read_start(on_read)
--     stderr:read_start(function(err, chunk)
--       if chunk then
--         vim.schedule(function()
--           vim.notify("Ollama error: " .. chunk, vim.log.levels.ERROR)
--         end)
--       end
--     end)
--   else
--     -- Non-streaming implementation
--     M.update_buffer_content(buf, header .. "Processing request...")
--
--     ollama_request("generate", {
--       model = model_name,
--       prompt = prompt,
--       stream = false
--     }, function(response)
--       vim.schedule(function()
--         if response and response.response then
--           M.update_buffer_content(buf, header .. response.response)
--         else
--           M.update_buffer_content(buf, header .. "Error: Failed to get response")
--         end
--
--         if callback then
--           callback(response)
--         end
--       end)
--     end)
--   end
-- end

function M.generate_completion(prompt, model, callback)
    local model_name = model or M.config.default_model
    local buf, win = M.create_window()

    -- Add initial content to buffer
    local header = string.format("# Processing with %s\n\n", model_name)
    M.update_buffer_content(buf, header)

    if M.config.stream then
        local args = {
            "-s", -- silent
            "-N", -- disable buffering
            "-X", "POST",
            string.format("%s:%d/api/generate", M.config.host, M.config.port),
            "-H", "Content-Type: application/json",
            "-d", vim.json.encode({
            model = model_name,
            prompt = prompt,
            stream = true
        })
        }

        local stdout = vim.loop.new_pipe(false)
        local response_text = ""
        local is_first_update = true

        local function on_read(err, chunk)
            if err then
                vim.schedule(function()
                    vim.notify("Error reading stream: " .. err, vim.log.levels.ERROR)
                    M.update_buffer_content(buf, header .. "Error: " .. err)
                end)
                return
            end

            if chunk then
                vim.schedule(function()
                    if not api.nvim_buf_is_valid(buf) then
                        return
                    end

                    -- Process the JSON lines in the chunk
                    for line in string.gmatch(chunk, "[^\r\n]+") do
                        local ok, data = pcall(vim.json.decode, line)
                        if ok and data and data.response then
                            response_text = response_text .. data.response

                            -- Only update the buffer if window is still valid
                            if api.nvim_win_is_valid(win) then
                                local display_text = header .. response_text

                                -- For the first update, replace the entire buffer
                                -- For subsequent updates, append to existing content
                                if is_first_update then
                                    api.nvim_buf_set_lines(buf, 0, -1, false,
                                        vim.split(display_text, "\n", { plain = true }))
                                    is_first_update = false
                                else
                                    local lines = vim.split(display_text, "\n", { plain = true })
                                    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                                end

                                -- Auto-scroll to bottom if cursor was at the bottom
                                local cursor_pos = api.nvim_win_get_cursor(win)
                                local line_count = api.nvim_buf_line_count(buf)
                                if cursor_pos[1] >= line_count - 2 then
                                    api.nvim_win_set_cursor(win, { line_count, 0 })
                                end
                            end
                        end

                        -- Check if we're done
                        if ok and data and data.done then
                            -- Finished generating
                        end
                    end
                end)
            end
        end

        -- Handle process lifecycle
        local stderr = vim.loop.new_pipe(false)
        local handle
        handle = vim.loop.spawn("curl", {
            args = args,
            stdio = { nil, stdout, stderr }
        }, function(code, signal)
            stdout:close()
            stderr:close()
            handle:close()

            vim.schedule(function()
                if code ~= 0 then
                    vim.notify("Ollama request failed with code: " .. code, vim.log.levels.ERROR)
                end

                if callback then
                    callback({ response = response_text, code = code })
                end
            end)
        end)

        -- Start reading from stdout and stderr
        stdout:read_start(on_read)
        stderr:read_start(function(err, chunk)
            if chunk then
                vim.schedule(function()
                    vim.notify("Ollama error: " .. chunk, vim.log.levels.ERROR)
                end)
            end
        end)
    else
        -- Non-streaming implementation
        M.update_buffer_content(buf, header .. "Processing request...")

        ollama_request("generate", {
            model = model_name,
            prompt = prompt,
            stream = false
        }, function(response)
            vim.schedule(function()
                if response and response.response then
                    M.update_buffer_content(buf, header .. response.response)
                else
                    M.update_buffer_content(buf, header .. "Error: Failed to get response")
                end

                if callback then
                    callback(response)
                end
            end)
        end)
    end
end
