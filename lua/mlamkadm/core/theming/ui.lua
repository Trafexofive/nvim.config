-- UI module for theming system
-- Provides UI components and user interaction for theme management

local theming = require("mlamkadm.core.theming.theming")

local M = {}

-- Interactive theme selector using telescope
function M.select_theme()
  local themes = theming.get_themes()
  local theme_names = {}
  local theme_map = {}

  for _, theme in ipairs(themes) do
    local display = string.format("%s - %s", theme.display_name, theme.description)
    if theme.name == theming.current_theme then
      display = display .. " [CURRENT]"
    end
    table.insert(theme_names, display)
    theme_map[display] = theme.name
  end

  -- Check if telescope is available
  local has_telescope, telescope = pcall(require, "telescope")
  if not has_telescope then
    -- Fallback to regular input if telescope is not available
    print("Available themes:")
    for i, theme in ipairs(themes) do
      local marker = theme.name == theming.current_theme and " (*)" or " ( )"
      print(marker .. " " .. theme.display_name .. " (" .. theme.name .. "): " .. theme.description)
    end
    local input = vim.fn.input("Enter theme name to switch to: ")
    if input and input ~= "" then
      vim.schedule(function()
        theming.switch_theme(input)
      end)
    end
    return
  end

  -- Use telescope to select a theme
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")
  local conf = require("telescope.config").values

  -- Create picker in a way that works from any context (including dashboard)
  local picker = pickers.new({}, {
    prompt_title = "Select a Theme",
    finder = finders.new_table {
      results = theme_names,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      map('i', '<CR>', function()
        local selection = action_state.get_current_line()
        actions.close(prompt_bufnr)
        vim.schedule(function()
          if theme_map[selection] and theme_map[selection] ~= theming.current_theme then
            theming.switch_theme(theme_map[selection])
          end
        end)
      end)
      -- Close picker with escape
      map('i', '<Esc>', actions.close)
      map('n', '<Esc>', actions.close)
      return true
    end,
  })
  
  -- Try to open picker with proper context handling
  local success, err = pcall(function()
    picker:find()
  end)
  
  if not success then
    -- Fallback to input if picker fails
    vim.notify("Theme picker failed: " .. tostring(err), vim.log.levels.WARN, { title = "Theme Manager" })
    local input = vim.fn.input("Enter theme name to switch to: ")
    if input and input ~= "" then
      vim.schedule(function()
        theming.switch_theme(input)
      end)
    end
  end
end

return M