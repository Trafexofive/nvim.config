-- ollama.nvim: A minimal Neovim plugin for processing visual selections with Ollama
-- Author: Claude
-- License: MIT

local M = {}
local api = vim.api
local fn = vim.fn

-- Minimal configuration
M.config = {
  host = "http://localhost",
  port = 11434,
  default_model = "mistral:7b",
  keymaps = {
    selection = "<leader>os", -- Process selection (visual mode)
  },
  window = {
    width = 0.8,   -- Percentage of screen width
    height = 0.7,  -- Percentage of screen height
    border = "rounded",
  },
  timeout = 30000, -- Request timeout in ms
  stream = false,  -- Disable streaming responses for simplicity
}

-- Buffer for the floating window
M.buf = nil
M.win = nil

-----------------------------------------------------------
-- Utility: Make an API request to the Ollama server.
-----------------------------------------------------------
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

-----------------------------------------------------------
-- Create a floating window for displaying responses.
-----------------------------------------------------------
function M.create_window()
  local width = math.floor(vim.o.columns * M.config.window.width)
  local height = math.floor(vim.o.lines * M.config.window.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  if not M.buf or not api.nvim_buf_is_valid(M.buf) then
    M.buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
    api.nvim_buf_set_option(M.buf, 'bufhidden', 'hide')
  end

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = M.config.window.border,
    title = " Ollama Response ",
    title_pos = "center",
  }

  if not M.win or not api.nvim_win_is_valid(M.win) then
    M.win = api.nvim_open_win(M.buf, true, opts)
    api.nvim_win_set_option(M.win, 'wrap', true)
    api.nvim_win_set_option(M.win, 'linebreak', true)
  else
    api.nvim_win_set_config(M.win, opts)
  end

  api.nvim_set_current_win(M.win)
  return M.buf, M.win
end

-----------------------------------------------------------
-- Process the currently selected text in visual mode.
-----------------------------------------------------------
function M.process_selection()
  -- Get visual selection positions
  local start_pos = fn.getpos("'<")
  local end_pos = fn.getpos("'>")
  local start_row, start_col = start_pos[2], start_pos[3]
  local end_row, end_col = end_pos[2], end_pos[3]

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
  local action_choices = {
    "Explain this code",
    "Improve this code",
    "Optimize this code",
    "Document this code",
    "Find bugs in this code",
    "Complete this code",
    "Summarize this text",
    "Other (custom prompt)",
  }

  vim.ui.select(action_choices, {
    prompt = "What do you want to do with the selection?",
  }, function(choice)
    if not choice then
      return
    end

    local prompt_text
    if choice == "Other (custom prompt)" then
      prompt_text = vim.fn.input({ prompt = "Custom prompt: ", cancelreturn = "" })
      if prompt_text == "" then
        return
      end
      prompt_text = prompt_text .. ":\n\n" .. selected_text
    else
      prompt_text = choice .. ":\n\n" .. selected_text
    end

    -- Split the selected_text into lines to avoid embedded newlines in a single item.
    local selection_lines = vim.split(selected_text, "\n", { plain = true })

    -- Build the header lines for the floating window.
    local header_lines = {}
    table.insert(header_lines, "# Selection")
    for _, l in ipairs(selection_lines) do
      table.insert(header_lines, l)
    end
    table.insert(header_lines, "")
    table.insert(header_lines, "# " .. choice)
    table.insert(header_lines, "Thinking...")

    M.create_window()
    api.nvim_buf_set_lines(M.buf, 0, -1, false, header_lines)

    M.generate_completion(prompt_text, nil, function(response)
      if response and response.response then
        local response_lines = vim.split(response.response, "\n", { plain = true })
        api.nvim_buf_set_lines(M.buf, #header_lines - 1, #header_lines, false, response_lines)
      else
        api.nvim_buf_set_lines(M.buf, #header_lines - 1, #header_lines, false, { "Error: Failed to get response" })
      end
    end)
  end)
end

-----------------------------------------------------------
-- Generate a completion using the Ollama server.
-----------------------------------------------------------
function M.generate_completion(prompt, model, callback)
  ollama_request("generate", {
    model = model or M.config.default_model,
    prompt = prompt,
    stream = false
  }, callback)
end

-----------------------------------------------------------
-- Setup the plugin and map the visual mode selection key.
-----------------------------------------------------------
function M.setup(user_config)
  if user_config then
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
  end

  vim.keymap.set('v', M.config.keymaps.selection, function() M.process_selection() end,
    { desc = "Ollama: Process visual selection" }
  )

  vim.api.nvim_create_user_command("OllamaSelection", function() M.process_selection() end, {})
end

return M
