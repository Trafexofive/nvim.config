-- /lua/mlamkadm/utils/vim_motions_ui.lua
-- UI components for the Vim motions registry

local vim_motions = require("mlamkadm.utils.vim_motions")
local SmpNotify = require("mlamkadm.utils.SmpNotify")

local M = {}

-- Create a popup window to display motions
function M.show_motions_popup()
  -- Create a scratch buffer for the popup
  local buf = vim.api.nvim_create_buf(false, true) -- not listed, scratch buffer
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  
  -- Get motions and format them for display
  local motions = vim_motions.get_motions()
  local lines = {}
  
  table.insert(lines, "VIM MOTIONS REGISTRY")
  table.insert(lines, "==================")
  table.insert(lines, "")
  
  -- Add motions to the buffer
  for _, motion in ipairs(motions) do
    table.insert(lines, string.format("%2d. %-10s - %s", motion.rank, motion.motion, motion.description))
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Make buffer read-only
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  -- Create the popup window
  local width = 80
  local height = math.min(#lines + 2, 30) -- +2 for padding, max 30 lines
  
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = 'Vim Motions Registry',
    footer = {'<Enter> Execute | <r> Reorder | <q> Close | <n> New Motion', 'vim_motions_ui'},
    footer_hl = 'FloatFooter',
  }
  
  local win = vim.api.nvim_open_win(buf, true, opts)
  
  -- Set window highlights
  vim.api.nvim_win_set_option(win, 'winhl', 'NormalFloat:NormalFloat,FloatBorder:FloatBorder')
  
  -- Set up keymaps for the popup
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '<Cmd>lua require("mlamkadm.utils.vim_motions_ui").execute_motion()<CR>', { silent = true, noremap = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<Cmd>lua require("mlamkadm.utils.vim_motions_ui").close_popup()<CR>', { silent = true, noremap = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'r', '<Cmd>lua require("mlamkadm.utils.vim_motions_ui").reorder_motion()<CR>', { silent = true, noremap = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Up>', '<Cmd>lua require("mlamkadm.utils.vim_motions_ui").move_motion_up()<CR>', { silent = true, noremap = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Down>', '<Cmd>lua require("mlamkadm.utils.vim_motions_ui").move_motion_down()<CR>', { silent = true, noremap = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'n', '<Cmd>lua require("mlamkadm.utils.vim_motions_ui").add_new_motion()<CR>', { silent = true, noremap = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<2-LeftMouse>', '<Cmd>lua require("mlamkadm.utils.vim_motions_ui").execute_motion()<CR>', { silent = true, noremap = true })
  
  -- Update footer to include new keymaps
  opts.footer = {'<Enter> Execute | <r> Reorder | <Up/Down> Move | <q> Close | <n> New Motion', 'vim_motions_ui'}
  
  -- Store window and buffer references for later use
  M.current_popup = {
    buf = buf,
    win = win
  }
end

-- Function to close the popup
function M.close_popup()
  if M.current_popup then
    if vim.api.nvim_win_is_valid(M.current_popup.win) then
      vim.api.nvim_win_close(M.current_popup.win, true)
    end
    if vim.api.nvim_buf_is_valid(M.current_popup.buf) then
      vim.api.nvim_buf_delete(M.current_popup.buf, { force = true })
    end
    M.current_popup = nil
  end
end

-- Function to execute the selected motion
function M.execute_motion()
  if not M.current_popup then return end
  
  local line_num = vim.api.nvim_win_get_cursor(M.current_popup.win)[1]
  local line = vim.api.nvim_buf_get_lines(M.current_popup.buf, line_num - 1, line_num, false)[1]
  
  -- Check if the line contains a motion (formatted as "rank. motion - description")
  if line and string.match(line, "^%d+%.%s+.*%s*%-.*") then
    local motion = string.match(line, "^%d+%.%s+(%S+)%s*%-")
    if motion then
      -- Handle special cases like <C-r>
      local actual_motion = motion
      if motion == "<C-r>" then
        actual_motion = "<C-r>"
      end
      
      -- Close the popup first
      M.close_popup()
      
      -- Execute the motion
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(actual_motion, true, false, true), 'n', false)
      
      -- Notify user of motion execution
      SmpNotify.info("Executed motion: " .. motion)
    else
      SmpNotify.warn("Could not parse motion from line: " .. line)
    end
  else
    SmpNotify.warn("No motion selected")
  end
end

-- Function to reorder a motion
function M.reorder_motion()
  if not M.current_popup then return end
  
  local line_num = vim.api.nvim_win_get_cursor(M.current_popup.win)[1]
  local line = vim.api.nvim_buf_get_lines(M.current_popup.buf, line_num - 1, line_num, false)[1]
  
  -- Check if the line contains a motion (formatted as "rank. motion - description")
  if line and string.match(line, "^%d+%.%s+.*%s*%-.*") then
    local motion = string.match(line, "^%d+%.%s+(%S+)%s*%-")
    local current_rank = tonumber(string.match(line, "^(%d+)%.")) or 0
    
    if motion then
      vim.ui.input({
        prompt = string.format("Enter new rank for '%s' (currently %d): ", motion, current_rank),
        default = tostring(current_rank),
        completion = "customlist,v:lua.nvim_list_uis"
      }, function(input)
        if input and input ~= "" then
          local new_rank = tonumber(input)
          if new_rank and new_rank > 0 then
            vim_motions.update_motion_rank(motion, new_rank)
            SmpNotify.success(string.format("Updated rank for '%s' to %d", motion, new_rank))
            
            -- Refresh the popup to show changes
            M.close_popup()
            M.show_motions_popup()
          else
            SmpNotify.warn("Invalid rank value")
          end
        end
      end)
    else
      SmpNotify.warn("Could not parse motion from line: " .. line)
    end
  else
    SmpNotify.warn("No motion selected")
  end
end

-- Function to add a new motion
function M.add_new_motion()
  -- Close the current popup
  M.close_popup()
  
  -- Prompt for motion
  vim.ui.input({
    prompt = "Enter new motion (e.g. 'dd', 'f<char>', etc.): ",
  }, function(motion)
    if not motion or motion == "" then return end
    
    -- Prompt for description
    vim.ui.input({
      prompt = "Enter description: ",
    }, function(description)
      if not description or description == "" then return end
      
      -- Prompt for category
      vim.ui.input({
        prompt = "Enter category (optional, e.g. 'movement', 'editing', 'search'): ",
        default = "general",
      }, function(category)
        category = category or "general"
        
        -- Register the new motion
        vim_motions.register_motion(motion, description, category)
        SmpNotify.success(string.format("Added new motion: '%s' - %s", motion, description))
        
        -- Show the motions popup again
        M.show_motions_popup()
      end)
    end)
  end)
end

-- Function to move the selected motion up
function M.move_motion_up()
  if not M.current_popup then return end
  
  local line_num = vim.api.nvim_win_get_cursor(M.current_popup.win)[1]
  local line = vim.api.nvim_buf_get_lines(M.current_popup.buf, line_num - 1, line_num, false)[1]
  
  -- Check if the line contains a motion (formatted as "rank. motion - description")
  if line and string.match(line, "^%d+%.%s+.*%s*%-.*") then
    local motion = string.match(line, "^%d+%.%s+(%S+)%s*%-")
    
    if motion then
      local success = vim_motions.move_motion_up(motion)
      if success then
        SmpNotify.success(string.format("Moved '%s' up in the list", motion))
        
        -- Refresh the popup to show changes
        M.close_popup()
        M.show_motions_popup()
      else
        SmpNotify.warn(string.format("Cannot move '%s' up", motion))
      end
    else
      SmpNotify.warn("Could not parse motion from line: " .. line)
    end
  else
    SmpNotify.warn("No motion selected")
  end
end

-- Function to move the selected motion down
function M.move_motion_down()
  if not M.current_popup then return end
  
  local line_num = vim.api.nvim_win_get_cursor(M.current_popup.win)[1]
  local line = vim.api.nvim_buf_get_lines(M.current_popup.buf, line_num - 1, line_num, false)[1]
  
  -- Check if the line contains a motion (formatted as "rank. motion - description")
  if line and string.match(line, "^%d+%.%s+.*%s*%-.*") then
    local motion = string.match(line, "^%d+%.%s+(%S+)%s*%-")
    
    if motion then
      local success = vim_motions.move_motion_down(motion)
      if success then
        SmpNotify.success(string.format("Moved '%s' down in the list", motion))
        
        -- Refresh the popup to show changes
        M.close_popup()
        M.show_motions_popup()
      else
        SmpNotify.warn(string.format("Cannot move '%s' down", motion))
      end
    else
      SmpNotify.warn("Could not parse motion from line: " .. line)
    end
  else
    SmpNotify.warn("No motion selected")
  end
end

return M