-- Session management utilities
local M = {}

-- Telescope dependencies for readme picker
local telescope_avail, telescope = pcall(require, "telescope")
local pickers_avail, pickers = pcall(require, "telescope.pickers")
local finders_avail, finders = pcall(require, "telescope.finders")
local previewers_avail, previewers = pcall(require, "telescope.previewers")
local conf_avail, conf = pcall(require, "telescope.config")
local actions_avail, actions = pcall(require, "telescope.actions")
local action_state_avail, action_state = pcall(require, "telescope.actions.state")

-- Get all possible auto-session directories
local function get_auto_session_dirs()
  local session_dirs = {}
  local possible_paths = {
    vim.fn.stdpath("data") .. "/auto-session",  -- Newer format
    vim.fn.stdpath("data") .. "/auto_session",  -- Older format  
  }
  
  for _, path in ipairs(possible_paths) do
    if vim.fn.isdirectory(path) == 1 then
      table.insert(session_dirs, path)
    end
  end
  
  return session_dirs
end

-- Custom previewer to show README.md for the selected session
local function session_readme_previewer(opts)
  if not previewers_avail then return nil end
  opts = opts or {}

  return previewers.new_buffer_previewer({
    title = "Session README",
    dyn_title = function(_, entry)
      return "README.md for: " .. entry.value
    end,
    define_preview = function(self, entry, status)
      local session_name = entry.value
      local readme_content = {}

      -- Auto-session typically names directories after the project paths
      -- So the session_name here is likely the project directory name/path
      local possible_project_paths = {
        vim.fn.expand(session_name),                    -- Direct expansion
        vim.fn.expand("~/") .. session_name,           -- Path relative to home
        vim.fn.getcwd() .. "/" .. session_name,        -- Path relative to current dir
      }

      -- Also check in the auto-session directory structure
      local session_dirs = get_auto_session_dirs()
      local session_path_found = nil
      
      -- Check if session_name corresponds to a directory in any of the auto-session directories
      for _, auto_session_dir in ipairs(session_dirs) do
        local session_dir_path = auto_session_dir .. "/" .. session_name
        if vim.fn.isdirectory(session_dir_path) == 1 then
          session_path_found = session_dir_path
          break
        end
      end

      if session_path_found then
        -- The session directory was found, so we can check for session files
        table.insert(possible_project_paths, 1, session_name)
      end

      -- Look for README.md in possible project directories
      local readme_found = false
      for _, project_path in ipairs(possible_project_paths) do
        if vim.fn.isdirectory(project_path) == 1 then
          local readme_path = project_path .. "/README.md"
          if vim.fn.filereadable(readme_path) == 1 then
            readme_content = vim.fn.readfile(readme_path)
            readme_found = true
            break
          end
        end
      end

      if not readme_found then
        -- If no README.md found, provide a helpful message
        readme_content = {
          "No README.md file found in project directory.",
          "",
          "Selected Session: " .. session_name,
          "",
          "This preview pane will show the README.md file",
          "from the project directory when available.",
          "",
          "Check the following locations for README.md:",
        }
        for i, path in ipairs(possible_project_paths) do
          if i <= 5 then  -- Limit the number of paths shown
            table.insert(readme_content, "  - " .. path .. "/README.md")
          end
        end
      end

      -- Set the content to the preview buffer
      vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
      
      -- Make buffer modifiable to set content
      vim.api.nvim_buf_set_option(self.state.bufnr, "modifiable", true)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, readme_content)
      vim.api.nvim_buf_set_option(self.state.bufnr, "modifiable", false)
    end,
  })
end

-- Function to create the session picker with README preview
function M.sessions_with_readme(opts)
  if not (telescope_avail and pickers_avail and finders_avail and conf_avail and actions_avail and action_state_avail) then
    vim.notify("Telescope is not available", vim.log.levels.ERROR)
    return
  end
  
  opts = opts or {}

  -- Get available sessions from all auto-session directories
  local session_dirs = get_auto_session_dirs()
  local sessions = {}

  -- Process each session directory in all session directories
  for _, session_dir in ipairs(session_dirs) do
    local session_entries = vim.fn.glob(session_dir .. "/*/", 0, 1)  -- Get all directories
    for _, session_path in ipairs(session_entries) do
      local session_name = vim.fn.fnamemodify(session_path, ":t"):gsub("/$", "")  -- Get directory name without trailing slash

      -- Check if the directory contains any session-related files
      local all_files = vim.fn.glob(session_path .. "*", 0, 1)
      if #all_files > 0 then
        -- Avoid duplicates
        local is_duplicate = false
        for _, existing_session in ipairs(sessions) do
          if existing_session == session_name then
            is_duplicate = true
            break
          end
        end
        if not is_duplicate then
          table.insert(sessions, session_name)
        end
      end
    end
  end

  -- Create picker entries
  local entries = {}
  for _, session_name in ipairs(sessions) do
    table.insert(entries, {
      value = session_name,
      ordinal = session_name,
      display = session_name,
    })
  end

  -- Create the picker with README preview
  pickers.new(opts, {
    prompt_title = "Sessions with README Preview",
    finder = finders.new_table {
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry.value,
          ordinal = entry.ordinal,
          display = entry.display,
        }
      end,
    },
    previewer = session_readme_previewer(opts),
    sorter = conf.values.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      -- Map enter key to restore the selected session
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection then
          -- The issue here is that we need to determine the correct way to restore the session
          -- Auto-session uses the directory context to determine which session to restore
          -- Try to restore by changing to the session directory name if it's a real path
          local project_dir = vim.fn.expand(selection.value)
          if vim.fn.isdirectory(project_dir) == 1 then
            vim.cmd("cd " .. vim.fn.fnameescape(project_dir))
            vim.cmd("silent! SessionRestore")
          else
            -- If it's not a valid directory, try to restore using auto-session API
            pcall(vim.cmd, "cd ~") -- Go to home directory as fallback
            vim.cmd("silent! SessionRestore " .. selection.value)
          end
        end
      end)
      return true
    end,
  }):find()
end

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
		completion = "dir", -- Enable directory completion
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
				vim.fn.mkdir(path, "p") -- "p" flag creates parent directories as needed
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

