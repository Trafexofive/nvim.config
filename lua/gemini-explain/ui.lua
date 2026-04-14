local M = {}

-- Variables to store window and buffer handles
local explanation_buf = nil
local explanation_win = nil
local current_content = ""

-- Function to create a floating window
local function create_floating_window(content)
  -- Close existing window if open
  if explanation_win and vim.api.nvim_win_is_valid(explanation_win) then
    vim.api.nvim_win_close(explanation_win, true)
  end

  -- Create a new buffer
  explanation_buf = vim.api.nvim_create_buf(false, true)  -- not listed, scratch

  -- Set buffer options
  vim.api.nvim_buf_set_option(explanation_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(explanation_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(explanation_buf, "modifiable", true)

  -- Split the content into lines
  local lines = {}
  for line in string.gmatch(content, "([^\n]*)\n?") do
    if line ~= "" then
      table.insert(lines, line)
    elseif line == "" and #lines > 0 then
      -- Preserve empty lines in the content
      table.insert(lines, "")
    end
  end

  -- Add content to buffer
  vim.api.nvim_buf_set_lines(explanation_buf, 0, -1, false, lines)

  -- Make buffer read-only
  vim.api.nvim_buf_set_option(explanation_buf, "modifiable", false)

  -- Calculate window dimensions
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create the floating window
  explanation_win = vim.api.nvim_open_win(explanation_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "Gemini Code Explanation",
    title_pos = "center"
  })

  -- Set window options for better appearance
  vim.api.nvim_win_set_option(explanation_win, "winhighlight", "Normal:Normal,FloatBorder:FloatBorder")

  -- Set up key mappings to close the window
  vim.api.nvim_buf_set_keymap(explanation_buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(explanation_buf, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(explanation_buf, "n", "<C-c>", "<cmd>close<CR>", { noremap = true, silent = true })

  -- Set syntax highlighting for code blocks if possible
  vim.api.nvim_buf_set_option(explanation_buf, "syntax", "off")

  -- Enable syntax highlighting for markdown-like elements
  vim.api.nvim_buf_call(explanation_buf, function()
    vim.cmd([[syntax on]])
    -- Basic highlighting for code blocks
    vim.cmd([[syntax region CodeBlock start=/```/ end=/```/ contains=TOP]])
    vim.cmd([[highlight default link CodeBlock Comment]])
  end)
end

-- Function to initialize the streaming display
function M.initialize_streaming_display()
  current_content = "Loading explanation from Gemini...\n"
  create_floating_window(current_content)
end

-- Function to update the streaming display with new content
function M.update_streaming_display(new_text)
  -- Schedule the update to happen in the main thread to avoid fast event context issues
  vim.schedule(function()
    -- Append the new text to the current content
    current_content = current_content .. new_text

    -- Update the buffer with the new content
    if explanation_buf and vim.api.nvim_buf_is_valid(explanation_buf) then
      -- Split the content into lines
      local lines = {}
      for line in string.gmatch(current_content, "([^\n]*)\n?") do
        if line ~= "" then
          table.insert(lines, line)
        elseif line == "" and #lines > 0 then
          -- Preserve empty lines in the content
          table.insert(lines, "")
        end
      end

      -- Update buffer content
      vim.api.nvim_buf_set_option(explanation_buf, "modifiable", true)
      vim.api.nvim_buf_set_lines(explanation_buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(explanation_buf, "modifiable", false)

      -- Scroll to the bottom to show the latest content
      if explanation_win and vim.api.nvim_win_is_valid(explanation_win) then
        vim.api.nvim_win_set_cursor(explanation_win, { #lines, 0 })
      end
    end
  end)
end

-- Function to display the final explanation
function M.display_explanation(text)
  vim.schedule(function()
    create_floating_window(text)
  end)
end

return M