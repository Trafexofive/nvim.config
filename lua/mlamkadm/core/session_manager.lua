-- Session management utilities
local M = {}

-- Function to delete a session using telescope session-lens
function M.delete_session()
  -- Use the AutoSession deletePicker command which should open a picker to select a session to delete
  vim.cmd("AutoSession deletePicker")
end

-- Create a new session by prompting for directory
function M.create_new_session()
  -- Prompt for a new directory path
  vim.ui.input({
    prompt = "Enter directory for new session (will be created if it doesn't exist): ",
    default = vim.fn.expand("~/projects/"),
    completion = "dir",  -- Enable directory completion
  }, function(input)
    if input and input ~= "" then
      local path = vim.fn.expand(input)
      
      -- Validate the path
      if not path or path == "" then
        vim.notify("Invalid path provided", vim.log.levels.ERROR)
        return
      end
      
      -- Create directory if it doesn't exist using vim.fn.mkdir
      local success, err = pcall(function()
        vim.fn.mkdir(path, "p")  -- "p" flag creates parent directories as needed
      end)
      
      if not success then
        vim.notify("Error creating directory: " .. tostring(err), vim.log.levels.ERROR)
        return
      end
      
      -- Change to the new directory using a safer approach
      local success_cd, err_cd = pcall(function()
        vim.cmd("cd " .. vim.fn.fnameescape(path))
      end)
      
      if not success_cd then
        vim.notify("Error changing to directory: " .. tostring(err_cd), vim.log.levels.ERROR)
        return
      end
      
      -- Close the snacks dashboard buffer if it's the current buffer to avoid saving it in the session
      local current_buf = vim.api.nvim_get_current_buf()
      local buf_ft = vim.api.nvim_buf_get_option(current_buf, "filetype")
      
      -- Close the dashboard if it's the current buffer
      if buf_ft == "snacks_dashboard" then
        vim.cmd("bd!") -- Force delete the dashboard buffer without saving
        
        -- Create a new empty buffer to replace the closed dashboard
        vim.cmd("enew")
      end
      
      -- Save the session
      local success_save, err_save = pcall(function()
        vim.cmd("SessionSave")
      end)
      
      if not success_save then
        vim.notify("Error saving session: " .. tostring(err_save), vim.log.levels.ERROR)
        return
      end
      
      -- Notify the user
      vim.notify("New session created in: " .. path, vim.log.levels.INFO)
    else
      -- User cancelled or entered empty input
      if input == nil then
        vim.notify("Session creation cancelled", vim.log.levels.INFO)
      end
    end
  end)
end

-- Create a temporary session that doesn't get saved to disk
-- This function will create a temporary working environment without creating an actual session file
function M.create_temp_session()
  -- Close the snacks dashboard buffer if it's the current buffer to avoid saving it in the session
  local current_buf = vim.api.nvim_get_current_buf()
  local buf_ft = vim.api.nvim_buf_get_option(current_buf, "filetype")

  -- Close the dashboard if it's the current buffer
  if buf_ft == "snacks_dashboard" then
    vim.cmd("bd!") -- Force delete the dashboard buffer without saving
    -- Create a new empty buffer to replace the closed dashboard
    vim.cmd("enew")
  end

  -- Create a temporary directory for this session using system temp
  local temp_dir = vim.fn.tempname()
  
  -- Create the temp directory
  vim.fn.mkdir(temp_dir, "p")
  
  -- Change to the temp directory
  local success_cd, err_cd = pcall(function()
    vim.cmd("cd " .. vim.fn.fnameescape(temp_dir))
  end)

  if not success_cd then
    vim.notify("Error changing to temp directory: " .. tostring(err_cd), vim.log.levels.ERROR)
    return
  end

  -- Notify user about the temporary working environment
  vim.notify("Temporary workspace created in: " .. temp_dir, vim.log.levels.INFO)
  
  -- Store the temp directory path for possible cleanup later
  M.current_temp_workspace = temp_dir
  
  -- Open a new empty buffer to start fresh
  vim.cmd("enew")
end

-- Function to clean up temporary workspace (delete files)
function M.cleanup_temp_session()
  if M.current_temp_workspace and vim.fn.isdirectory(M.current_temp_workspace) == 1 then
    local success, err = pcall(function()
      vim.fn.delete(M.current_temp_workspace, "rf") -- Remove directory recursively
    end)
    
    if success then
      vim.notify("Cleaned up temporary workspace", vim.log.levels.INFO)
      M.current_temp_workspace = nil
    else
      vim.notify("Error cleaning up temp workspace: " .. tostring(err), vim.log.levels.WARN)
    end
  else
    vim.notify("No temporary workspace to clean up", vim.log.levels.INFO)
  end
end

return M