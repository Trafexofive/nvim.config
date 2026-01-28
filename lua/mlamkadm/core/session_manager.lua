-- Session management utilities
local M = {}

-- Get all possible auto-session directories
local function get_auto_session_dirs()
  local session_dirs = {}
  local possible_paths = {
    vim.fn.stdpath("data") .. "/sessions",      -- Default Neovim sessions
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

-- Helper to decode auto-session filenames to actual paths
local function decode_session_path(filename)
  -- Remove .vim extension
  local path = filename:gsub("%.vim$", "")
  -- Replace all %XX hex sequences with their actual characters
  path = path:gsub("%%(%x%x)", function(h)
    return string.char(tonumber(h, 16))
  end)
  return path
end

-- Custom previewer to show README.md for the selected session
local function session_readme_previewer(opts)
  local previewers_avail, previewers = pcall(require, "telescope.previewers")
  if not previewers_avail then return nil end
  opts = opts or {}

  return previewers.new_buffer_previewer({
    title = "Session README",
    dyn_title = function(_, entry)
      return "README.md for: " .. entry.display
    end,
    define_preview = function(self, entry, status)
      local project_path = entry.value
      local readme_content = {}

      -- Look for README.md in the project directory
      local readme_path = project_path .. "/README.md"
      local readme_found = false
      
      if vim.fn.filereadable(readme_path) == 1 then
        readme_content = vim.fn.readfile(readme_path)
        readme_found = true
      end

      if not readme_found then
        -- If no README.md found, provide a helpful message
        readme_content = {
          "No README.md file found in project directory.",
          "",
          "Project Path: " .. project_path,
          "",
          "This preview pane will show the README.md file",
          "from the project directory when available.",
        }
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
  -- Require telescope components inside the function to ensure they are loaded
  local pickers_avail, pickers = pcall(require, "telescope.pickers")
  local finders_avail, finders = pcall(require, "telescope.finders")
  local conf_avail, conf = pcall(require, "telescope.config")
  local actions_avail, actions = pcall(require, "telescope.actions")
  local action_state_avail, action_state = pcall(require, "telescope.actions.state")

  if not (pickers_avail and finders_avail and conf_avail and actions_avail and action_state_avail) then
    vim.notify("Telescope components not fully available", vim.log.levels.ERROR)
    return
  end
  
  opts = opts or {}

  -- Get available sessions from all session directories
  local session_dirs = get_auto_session_dirs()
  local session_data = {}

  -- Process each session directory
  for _, session_dir in ipairs(session_dirs) do
    local session_files = vim.fn.glob(session_dir .. "/*.vim", 0, 1)
    for _, session_file in ipairs(session_files) do
      local filename = vim.fn.fnamemodify(session_file, ":t")
      local project_path = decode_session_path(filename)
      local stats = vim.loop.fs_stat(session_file)
      local mtime = stats and stats.mtime.sec or 0
      
      -- Avoid duplicates, keep the newest mtime if same path found in different dirs
      if not session_data[project_path] or mtime > session_data[project_path].mtime then
        session_data[project_path] = {
          path = project_path,
          display = vim.fn.fnamemodify(project_path, ":t"),
          mtime = mtime,
        }
      end
    end
  end

  -- Create picker entries
  local entries = {}
  for path, data in pairs(session_data) do
    table.insert(entries, {
      value = path,
      ordinal = path .. " " .. data.display,
      display = data.display .. " (" .. path .. ")",
      mtime = data.mtime,
    })
  end

  -- Sort entries by modification time (newest first)
  table.sort(entries, function(a, b)
    return a.mtime > b.mtime
  end)

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
          -- Save current session before switching
          vim.cmd("silent! SessionSave")
          
          local project_dir = selection.value
          if vim.fn.isdirectory(project_dir) == 1 then
            vim.cmd("cd " .. vim.fn.fnameescape(project_dir))
            -- Clear all buffers before restoring to ensure a clean switch
            -- This helps with terminals and other state
            vim.cmd("silent! %bd!")
            vim.cmd("silent! SessionRestore")
          else
            vim.notify("Directory not found: " .. project_dir, vim.log.levels.ERROR)
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

