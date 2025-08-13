-- monkeytype.nvim: Typing practice mode in the same Neovim buffer
local M = {}

-- Default configuration
local config = {
  highlight_groups = {
    correct = "Comment",
    error = "Error",
    remaining = "Normal",
  },
}

-- State variables
local state = {
  buffer = nil,
  namespace = vim.api.nvim_create_namespace("Monkeytype"),
  original_lines = {},
  practice_lines = {},  -- Lines to practice (subset of original_lines)
  start_line = 1,       -- Starting line in original buffer
  end_line = nil,       -- Ending line in original buffer
  current_line = 1,     -- Current line in practice_lines
  current_char = 1,
  user_input = "",
  start_time = nil,
  is_practice_mode = false,
  original_keymaps = {},
  original_modifiable = true,
}

-- Save original buffer content and keymaps
local function save_buffer_state(start_line, end_line)
  state.buffer = vim.api.nvim_get_current_buf()
  state.original_lines = vim.api.nvim_buf_get_lines(state.buffer, 0, -1, false)
  state.original_modifiable = vim.api.nvim_buf_get_option(state.buffer, "modifiable")
  
  -- Set practice range
  state.start_line = start_line or 1
  state.end_line = end_line or #state.original_lines
  
  -- Extract practice lines
  state.practice_lines = {}
  for i = state.start_line, state.end_line do
    if state.original_lines[i] then
      table.insert(state.practice_lines, state.original_lines[i])
    end
  end
  
  -- Save insert mode keymaps (filter out our own keymaps)
  state.original_keymaps = {}
  local current_keymaps = vim.api.nvim_buf_get_keymap(state.buffer, "i")
  for _, map in ipairs(current_keymaps) do
    -- Only save non-monkeytype keymaps
    if not (map.desc and map.desc:match("monkeytype")) then
      table.insert(state.original_keymaps, map)
    end
  end
end

-- Clear previous highlights
local function clear_highlights()
  if state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then
    vim.api.nvim_buf_clear_namespace(state.buffer, state.namespace, 0, -1)
  end
end

-- Calculate WPM
local function calculate_wpm(correct_chars)
  if not state.start_time then return 0 end
  local elapsed = os.difftime(os.time(), state.start_time) / 60
  if elapsed == 0 then return 0 end
  return math.floor((correct_chars / 5) / elapsed)
end

-- Highlight text based on user input
local function highlight_text()
  if not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
    return
  end
  
  clear_highlights()
  
  if state.current_line > #state.practice_lines then
    return
  end
  
  local line = state.practice_lines[state.current_line]
  if not line then return end
  
  -- Calculate actual buffer line number
  local buffer_line = state.start_line + state.current_line - 2

  local correct_chars = 0
  
  -- Highlight each character
  for i = 1, #line do
    local char = line:sub(i, i)
    local highlight
    
    if i <= #state.user_input then
      -- Character has been typed
      if state.user_input:sub(i, i) == char then
        highlight = config.highlight_groups.correct
        correct_chars = correct_chars + 1
      else
        highlight = config.highlight_groups.error
      end
    else
      -- Character hasn't been typed yet
      highlight = config.highlight_groups.remaining
    end
    
    vim.api.nvim_buf_add_highlight(
      state.buffer, 
      state.namespace, 
      highlight, 
      buffer_line, 
      i - 1, 
      i
    )
  end

  -- Add virtual text for WPM and progress
  local wpm = calculate_wpm(correct_chars)
  local progress = string.format("Line %d/%d", state.current_line, #state.practice_lines)
  vim.api.nvim_buf_set_extmark(state.buffer, state.namespace, buffer_line, 0, {
    virt_text = { 
      { " WPM: " .. wpm .. " | " .. progress, "Comment" } 
    },
    virt_text_pos = "eol",
  })
end

-- Handle user input
local function handle_input(char)
  if not state.is_practice_mode or not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
    return
  end

  if state.current_line > #state.practice_lines then
    -- Practice completed
    M.stop()
    vim.notify("Typing practice completed!", vim.log.levels.INFO)
    return
  end

  local line = state.practice_lines[state.current_line]
  if not line then return end

  if char == "<BS>" then
    -- Backspace
    if #state.user_input > 0 then
      state.user_input = state.user_input:sub(1, -2)
    end
  elseif char == "<CR>" then
    -- Enter key - move to next line if current line is complete
    if #state.user_input >= #line then
      state.current_line = state.current_line + 1
      state.user_input = ""
    end
  else
    -- Regular character input
    if #state.user_input < #line then
      state.user_input = state.user_input .. char
    end
  end

  highlight_text()
end

-- Set up keymaps for practice mode
local function setup_keymaps()
  if not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
    return
  end
  
  -- Make buffer non-modifiable
  vim.api.nvim_buf_set_option(state.buffer, "modifiable", false)
  
  -- Set up character keymaps
  local printable_chars = {}
  for i = 32, 126 do
    table.insert(printable_chars, string.char(i))
  end
  
  for _, char in ipairs(printable_chars) do
    vim.keymap.set("i", char, function() 
      handle_input(char) 
    end, { 
      buffer = state.buffer, 
      desc = "monkeytype char input" 
    })
  end
  
  -- Special keys
  vim.keymap.set("i", "<BS>", function() 
    handle_input("<BS>") 
  end, { 
    buffer = state.buffer, 
    desc = "monkeytype backspace" 
  })
  
  vim.keymap.set("i", "<CR>", function() 
    handle_input("<CR>") 
  end, { 
    buffer = state.buffer, 
    desc = "monkeytype enter" 
  })
  
  -- Escape to exit practice mode
  vim.keymap.set("i", "<Esc>", function()
    M.stop()
  end, { 
    buffer = state.buffer, 
    desc = "monkeytype exit" 
  })
end

-- Reset keymaps to original state
local function reset_keymaps()
  if not state.buffer or not vim.api.nvim_buf_is_valid(state.buffer) then
    return
  end
  
  -- Clear all current insert mode keymaps
  local current_keymaps = vim.api.nvim_buf_get_keymap(state.buffer, "i")
  for _, map in ipairs(current_keymaps) do
    if map.desc and map.desc:match("monkeytype") then
      pcall(vim.api.nvim_buf_del_keymap, state.buffer, "i", map.lhs)
    end
  end
  
  -- Restore original keymaps
  for _, map in ipairs(state.original_keymaps) do
    local opts = {
      noremap = map.noremap == 1,
      silent = map.silent == 1,
      expr = map.expr == 1,
      desc = map.desc,
    }
    
    if map.callback then
      opts.callback = map.callback
    end
    
    pcall(vim.api.nvim_buf_set_keymap, state.buffer, "i", map.lhs, map.rhs or "", opts)
  end
  
  -- Restore buffer modifiable state
  vim.api.nvim_buf_set_option(state.buffer, "modifiable", state.original_modifiable)
end

-- Reset the typing test
local function reset_test()
  if not state.is_practice_mode then
    return
  end
  
  state.current_line = 1
  state.current_char = 1
  state.user_input = ""
  state.start_time = os.time()
  clear_highlights()
  highlight_text()
  vim.notify("Typing practice reset!", vim.log.levels.INFO)
end

-- Validate buffer for practice
local function validate_buffer()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    vim.notify("Invalid buffer!", vim.log.levels.ERROR)
    return false
  end
  
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    vim.notify("Buffer is empty! Add some text to practice with.", vim.log.levels.WARN)
    return false
  end
  
  return true
end

-- Get visual selection range
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil, nil
  end
  
  return start_pos[2], end_pos[2]  -- Return line numbers (1-indexed)
end

-- Get current line or cursor position
local function get_cursor_position()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return cursor[1]  -- Return line number (1-indexed)
end

-- Start typing practice
function M.start(opts)
  opts = opts or {}
  
  if state.is_practice_mode then
    vim.notify("Typing practice already active!", vim.log.levels.WARN)
    return
  end
  
  if not validate_buffer() then
    return
  end

  local start_line, end_line
  
  if opts.range then
    -- Use provided range
    start_line = opts.range[1]
    end_line = opts.range[2]
  else
    -- Try to get visual selection, fallback to current line or whole buffer
    local vis_start, vis_end = get_visual_selection()
    if vis_start and vis_end then
      start_line = vis_start
      end_line = vis_end
      vim.notify(string.format("Starting practice from lines %d-%d", start_line, end_line), vim.log.levels.INFO)
    elseif opts.from_cursor then
      start_line = get_cursor_position()
      end_line = vim.api.nvim_buf_line_count(0)
      vim.notify(string.format("Starting practice from line %d to end", start_line), vim.log.levels.INFO)
    else
      -- Default: whole buffer
      start_line = 1
      end_line = vim.api.nvim_buf_line_count(0)
    end
  end

  save_buffer_state(start_line, end_line)
  
  if #state.practice_lines == 0 then
    vim.notify("No lines to practice!", vim.log.levels.WARN)
    return
  end
  
  state.start_time = os.time()
  state.is_practice_mode = true
  state.current_line = 1
  state.current_char = 1
  state.user_input = ""
  
  setup_keymaps()
  highlight_text()
  
  local msg = string.format("Typing practice started! (%d lines) Press <Esc> to exit.", #state.practice_lines)
  vim.notify(msg, vim.log.levels.INFO)
end

-- Stop typing practice
function M.stop()
  if not state.is_practice_mode then
    vim.notify("No active typing practice!", vim.log.levels.WARN)
    return
  end

  state.is_practice_mode = false
  reset_keymaps()
  clear_highlights()
  
  -- Calculate final stats
  if state.start_time then
    local total_chars = 0
    local correct_chars = 0
    
    for i = 1, state.current_line - 1 do
      if state.practice_lines[i] then
        total_chars = total_chars + #state.practice_lines[i]
        correct_chars = correct_chars + #state.practice_lines[i]
      end
    end
    
    -- Add current line progress
    if state.practice_lines[state.current_line] then
      local current_line_text = state.practice_lines[state.current_line]
      for i = 1, math.min(#state.user_input, #current_line_text) do
        total_chars = total_chars + 1
        if state.user_input:sub(i, i) == current_line_text:sub(i, i) then
          correct_chars = correct_chars + 1
        end
      end
    end
    
    local accuracy = total_chars > 0 and math.floor((correct_chars / total_chars) * 100) or 0
    local wpm = calculate_wpm(correct_chars)
    
    vim.notify(
      string.format("Practice completed! WPM: %d, Accuracy: %d%% (%d/%d)", 
        wpm, accuracy, correct_chars, total_chars), 
      vim.log.levels.INFO
    )
  else
    vim.notify("Typing practice stopped!", vim.log.levels.INFO)
  end
end

-- Reset typing practice
function M.reset()
  if not state.is_practice_mode then
    vim.notify("No active typing practice to reset!", vim.log.levels.WARN)
    return
  end
  reset_test()
end

-- Get current stats
function M.stats()
  if not state.is_practice_mode then
    vim.notify("No active typing practice!", vim.log.levels.WARN)
    return
  end
  
  local correct_chars = 0
  local total_chars = 0
  
  -- Count characters from completed lines
  for i = 1, state.current_line - 1 do
    if state.practice_lines[i] then
      total_chars = total_chars + #state.practice_lines[i]
      correct_chars = correct_chars + #state.practice_lines[i]
    end
  end
  
  -- Count characters from current line
  if state.practice_lines[state.current_line] then
    local line = state.practice_lines[state.current_line]
    for i = 1, math.min(#state.user_input, #line) do
      total_chars = total_chars + 1
      if state.user_input:sub(i, i) == line:sub(i, i) then
        correct_chars = correct_chars + 1
      end
    end
  end
  
  local accuracy = total_chars > 0 and math.floor((correct_chars / total_chars) * 100) or 0
  local wpm = calculate_wpm(correct_chars)
  
  vim.notify(
    string.format("Current stats - WPM: %d, Accuracy: %d%% (%d/%d) | Line %d/%d", 
      wpm, accuracy, correct_chars, total_chars, state.current_line, #state.practice_lines), 
    vim.log.levels.INFO
  )
end

-- Setup function for user configuration
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})
end

-- Create user commands
vim.api.nvim_create_user_command("MonkeytypeStart", function(opts)
  M.start()
end, {
  desc = "Start typing practice (whole buffer)"
})

vim.api.nvim_create_user_command("MonkeytypeStartFromCursor", function(opts)
  M.start({ from_cursor = true })
end, {
  desc = "Start typing practice from cursor position"
})

vim.api.nvim_create_user_command("MonkeytypeStartRange", function(opts)
  M.start({ range = { opts.line1, opts.line2 } })
end, {
  desc = "Start typing practice on range",
  range = true
})

vim.api.nvim_create_user_command("MonkeytypeStop", M.stop, {
  desc = "Stop typing practice"
})
vim.api.nvim_create_user_command("MonkeytypeReset", M.reset, {
  desc = "Reset current typing practice"
})
vim.api.nvim_create_user_command("MonkeytypeStats", M.stats, {
  desc = "Show current typing statistics"
})

return M
