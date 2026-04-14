local M = {}

-- Setup function
function M.setup(config)
  local gemini_config = require("gemini-explain.config")

  -- Merge user config with defaults
  local merged_config = gemini_config.merge(config)
  if not merged_config then
    return
  end

  -- Store the active configuration
  M.active_config = merged_config

  -- Validate configuration
  if not M.active_config.api_key then
    -- Try to read from environment variable or config file
    M.active_config.api_key = os.getenv("GEMINI_API_KEY")

    -- if not M.active_config.api_key then
    --   -- Try to read from file
    --   local key_file = vim.fn.expand("~/.config/nvim/gemini_key.txt")
    --   if vim.fn.filereadable(key_file) == 1 then
    --     local key_lines = vim.fn.readfile(key_file)
    --     if #key_lines > 0 then
    --       M.active_config.api_key = key_lines[1]:gsub("^%s+", ""):gsub("%s+$", "")
    --     end
    --   end
    -- end

    if not M.active_config.api_key then
      vim.notify("Gemini API key not found. Please set GEMINI_API_KEY environment variable or create ~/.config/nvim/gemini_key.txt", vim.log.levels.ERROR)
      return
    end
  end

  -- Load required modules
  local gemini_api = require("gemini-explain.api")
  local gemini_context = require("gemini-explain.context")
  local gemini_ui = require("gemini-explain.ui")

  -- Define the main function to explain selected code
  local explain_code = function()
    -- Get the current visual selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_line = start_pos[2]
    local end_line = end_pos[2]

    -- Get the selected lines
    local selected_lines = vim.fn.getline(start_line, end_line)
    local selected_text = table.concat(selected_lines, "\n")

    -- Build context
    local context = gemini_context.build_context(start_line, end_line)

    -- Send to Gemini API
    gemini_api.send_to_gemini(selected_text, context, function(explanation)
      -- Schedule the display to run in the main thread to avoid fast event context issues
      vim.schedule(function()
        -- Display the final explanation
        gemini_ui.display_explanation(explanation)
      end)
    end)
  end

  -- Set up the keybinding
  vim.keymap.set("v", M.active_config.keybind, explain_code, { noremap = true, silent = true })
end

return M
