-- Telescope picker with README.md preview for auto-session
local telescope = require('telescope')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

-- Get all possible auto-session directories
local get_auto_session_dirs = function()
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
M.session_readme_previewer = function(opts)
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
M.sessions_with_readme = function(opts)
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
    previewer = M.session_readme_previewer(opts),
    sorter = conf.generic_sorter(opts),
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

return M