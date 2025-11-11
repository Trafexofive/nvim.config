-- Session management utilities
local M = {}

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

return M