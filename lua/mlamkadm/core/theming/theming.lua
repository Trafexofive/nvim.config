-- Core theming logic - extracted from theme.lua for modularity
local M = {}

-- Theme configuration
M.themes = {
  gruvbox = {
    plugin = "ellisonleao/gruvbox.nvim",
    setup = function()
      -- Try to load the plugin with error handling
      local ok, gruvbox = pcall(require, "gruvbox")
      if not ok then
        -- Try to load it using lazy.nvim to ensure plugin is properly loaded
        local lazy_ok, lazy = pcall(require, "lazy.core.loader")
        if lazy_ok and lazy then
          local plugin_name = "gruvbox.nvim"
          local plugin = lazy.plugins[plugin_name]
          if plugin and not plugin._.loaded then
            lazy.load({ plugins = { plugin_name } })
            ok, gruvbox = pcall(require, "gruvbox")
          end
        end
        
        -- If still not loaded, try a delayed approach
        if not ok then
          vim.schedule(function()
            local retry_ok, retry_gruvbox = pcall(require, "gruvbox")
            if retry_ok then
              retry_gruvbox.setup({
                -- contrast = "medium",
                palette_overrides = {},
                overrides = {
                  SignColumn = { bg = "NONE" },
                  NormalFloat = { bg = "NONE" },
                  FloatBorder = { fg = "#928374", bg = "NONE" },
                },
                dim_inactive = false,
                transparent_mode = false,
              })
              vim.cmd.colorscheme "gruvbox"

              -- Set terminal colors to match gruvbox
              vim.g.terminal_color_0 = '#282828'
              vim.g.terminal_color_1 = '#cc241d'
              vim.g.terminal_color_2 = '#98971a'
              vim.g.terminal_color_3 = '#d79921'
              vim.g.terminal_color_4 = '#458588'
              vim.g.terminal_color_5 = '#b16286'
              vim.g.terminal_color_6 = '#689d6a'
              vim.g.terminal_color_7 = '#a89984'
              vim.g.terminal_color_8 = '#928374'
              vim.g.terminal_color_9 = '#fb4934'
              vim.g.terminal_color_10 = '#b8bb26'
              vim.g.terminal_color_11 = '#fabd2f'
              vim.g.terminal_color_12 = '#83a598'
              vim.g.terminal_color_13 = '#d3869b'
              vim.g.terminal_color_14 = '#8ec07c'
              vim.g.terminal_color_15 = '#ebdbb2'
              vim.notify("Gruvbox theme applied after delayed loading", vim.log.levels.INFO, { title = "Theme Manager" })
            else
              vim.notify("gruvbox.nvim plugin still not found after attempting to load with lazy.nvim. Please make sure it's installed via your plugin manager.", vim.log.levels.ERROR, { title = "Theme Manager" })
            end
          end)
          return false
        end
      end

      -- If plugin was successfully loaded immediately, apply the setup
      gruvbox.setup({
        -- contrast = "medium",
        palette_overrides = {},
        overrides = {
          SignColumn = { bg = "NONE" },
          NormalFloat = { bg = "NONE" },
          FloatBorder = { fg = "#928374", bg = "NONE" },
        },
        dim_inactive = false,
        transparent_mode = false,
      })
      vim.cmd.colorscheme "gruvbox"

      -- Set terminal colors to match gruvbox
      vim.g.terminal_color_0 = '#282828'
      vim.g.terminal_color_1 = '#cc241d'
      vim.g.terminal_color_2 = '#98971a'
      vim.g.terminal_color_3 = '#d79921'
      vim.g.terminal_color_4 = '#458588'
      vim.g.terminal_color_5 = '#b16286'
      vim.g.terminal_color_6 = '#689d6a'
      vim.g.terminal_color_7 = '#a89984'
      vim.g.terminal_color_8 = '#928374'
      vim.g.terminal_color_9 = '#fb4934'
      vim.g.terminal_color_10 = '#b8bb26'
      vim.g.terminal_color_11 = '#fabd2f'
      vim.g.terminal_color_12 = '#83a598'
      vim.g.terminal_color_13 = '#d3869b'
      vim.g.terminal_color_14 = '#8ec07c'
      vim.g.terminal_color_15 = '#ebdbb2'
    end,
    name = "Gruvbox",
    description = "Warm retro palette"
  },
  tokyonight = {
    plugin = "folke/tokyonight.nvim",
    setup = function()
      local ok, tokyonight = pcall(require, "tokyonight")
      if not ok then
        vim.notify("tokyonight.nvim plugin not found. Please make sure it's installed via your plugin manager.", vim.log.levels.WARN, { title = "Theme Manager" })
        return false
      end
      
      tokyonight.setup({
        style = "storm", -- Options: storm, moon, night, day
        transparent = false,
        terminal_colors = true,
        styles = {
          sidebars = "dark",
          floats = "dark",
        }
      })
      vim.cmd.colorscheme "tokyonight"
      
      -- Set terminal colors for tokyonight
      vim.g.terminal_color_0 = "#15161e"
      vim.g.terminal_color_1 = "#f7768e"
      vim.g.terminal_color_2 = "#9ece6a"
      vim.g.terminal_color_3 = "#e0af68"
      vim.g.terminal_color_4 = "#7aa2f7"
      vim.g.terminal_color_5 = "#bb9af7"
      vim.g.terminal_color_6 = "#7dcfff"
      vim.g.terminal_color_7 = "#a9b1d6"
      vim.g.terminal_color_8 = "#414868"
      vim.g.terminal_color_9 = "#f7768e"
      vim.g.terminal_color_10 = "#9ece6a"
      vim.g.terminal_color_11 = "#e0af68"
      vim.g.terminal_color_12 = "#7aa2f7"
      vim.g.terminal_color_13 = "#bb9af7"
      vim.g.terminal_color_14 = "#7dcfff"
      vim.g.terminal_color_15 = "#c0caf5"
    end,
    name = "Tokyo Night",
    description = "Dark theme with vibrant colors"
  },
  dracula = {
    plugin = "Mofiqul/dracula.nvim",
    setup = function()
      local ok, dracula = pcall(require, "dracula")
      if not ok then
        vim.notify("dracula.nvim plugin not found. Please make sure it's installed via your plugin manager.", vim.log.levels.WARN, { title = "Theme Manager" })
        return false
      end
      
      dracula.setup({
        transparent_bg = false,
        show_end_of_buffer = true,
        overrides = {},
      })
      vim.cmd.colorscheme "dracula"
      
      -- Set terminal colors for dracula
      vim.g.terminal_color_0 = "#212121"
      vim.g.terminal_color_1 = "#ff5555"
      vim.g.terminal_color_2 = "#50fa7b"
      vim.g.terminal_color_3 = "#f1fa8c"
      vim.g.terminal_color_4 = "#bd93f9"
      vim.g.terminal_color_5 = "#ff79c6"
      vim.g.terminal_color_6 = "#8be9fd"
      vim.g.terminal_color_7 = "#f8f8f2"
      vim.g.terminal_color_8 = "#6272a4"
      vim.g.terminal_color_9 = "#ff6e6e"
      vim.g.terminal_color_10 = "#69ff94"
      vim.g.terminal_color_11 = "#ffffa5"
      vim.g.terminal_color_12 = "#d6acff"
      vim.g.terminal_color_13 = "#ff92d0"
      vim.g.terminal_color_14 = "#a4ffff"
      vim.g.terminal_color_15 = "#ffffff"
    end,
    name = "Dracula",
    description = "Classic dark theme"
  },
  onedark = {
    plugin = "navarasu/onedark.nvim",
    setup = function()
      local ok, onedark = pcall(require, "onedark")
      if not ok then
        vim.notify("onedark.nvim plugin not found. Please make sure it's installed via your plugin manager.", vim.log.levels.WARN, { title = "Theme Manager" })
        return false
      end
      
      onedark.setup({
        style = "dark",
        transparent = false,
        code_style = {
          comments = "italic",
          keywords = "none",
          functions = "none",
        }
      })
      vim.cmd.colorscheme "onedark"
      
      -- Set terminal colors for onedark
      vim.g.terminal_color_0 = "#1e222a"
      vim.g.terminal_color_1 = "#e06c75"
      vim.g.terminal_color_2 = "#98c379"
      vim.g.terminal_color_3 = "#e5c07b"
      vim.g.terminal_color_4 = "#61afef"
      vim.g.terminal_color_5 = "#c678dd"
      vim.g.terminal_color_6 = "#56b6c2"
      vim.g.terminal_color_7 = "#abb2bf"
      vim.g.terminal_color_8 = "#5c6370"
      vim.g.terminal_color_9 = "#e06c75"
      vim.g.terminal_color_10 = "#98c379"
      vim.g.terminal_color_11 = "#e5c07b"
      vim.g.terminal_color_12 = "#61afef"
      vim.g.terminal_color_13 = "#c678dd"
      vim.g.terminal_color_14 = "#56b6c2"
      vim.g.terminal_color_15 = "#ffffff"
    end,
    name = "One Dark",
    description = "Popular dark theme"
  }
}

-- Current theme
M.current_theme = "gruvbox"

-- Switch to a specified theme
function M.switch_theme(theme_name)
  if not M.themes[theme_name] then
    vim.notify("Theme " .. theme_name .. " not found!", vim.log.levels.ERROR, { title = "Theme Manager" })
    return false
  end

  -- First ensure the plugin is loaded before applying the theme
  local theme_info = M.themes[theme_name]
  
  -- Try to load the theme plugin if it's not already loaded
  local plugin_loaded = false
  if theme_name ~= "gruvbox" then  -- gruvbox is already loaded via config
    -- For other themes, try to load them using lazy if possible
    local success, lazy_plugins = pcall(require, "lazy.core.config")
    if success then
      -- Extract just the plugin name from the path (e.g., "folke/tokyonight.nvim" -> "tokyonight.nvim")
      local plugin_name = theme_info.plugin:match("[^/]+")
      local plugin = lazy_plugins.plugins[plugin_name]
      if plugin then
        -- Load the plugin if it's not already loaded
        if not plugin._.loaded then
          require("lazy.core.loader").load(plugin, { only = plugin })
        end
        plugin_loaded = true
      end
    end
    
    -- If plugin wasn't loaded via lazy, try a regular require
    if not plugin_loaded then
      -- Extract theme name from plugin path (e.g., "folke/tokyonight.nvim" -> "tokyonight")
      local theme_module_name = theme_info.plugin:match("([^/]+)$"):gsub("%.nvim$", "")
      local _, module = pcall(require, theme_module_name)  
      if module then
        plugin_loaded = true
      end
    end
    
    if not plugin_loaded then
      vim.notify("Could not load " .. theme_info.plugin .. ". Attempting to apply theme anyway.", vim.log.levels.WARN, { title = "Theme Manager" })
    end
  end

  -- Execute the theme setup
  local success, err = pcall(theme_info.setup)
  if not success then
    vim.notify("Error setting up theme " .. theme_name .. ": " .. tostring(err), vim.log.levels.ERROR, { title = "Theme Manager" })
    return false
  end

  -- Apply visual enhancements
  local ok, visual = pcall(require, "mlamkadm.core.visual")
  if ok then
    visual.setup()
  end

  -- Update current theme
  M.current_theme = theme_name

  -- Notify user with more visual distinction
  local theme_info = M.themes[theme_name]
  vim.schedule(function()
    vim.notify("✓ Switched to " .. theme_info.name .. " (" .. theme_name .. ")", vim.log.levels.INFO, { 
      title = "Theme Manager", 
      on_open = function(win)
        -- Make notification more visible by using a highlight
        vim.api.nvim_win_set_option(win, "winhighlight", "Normal:Normal")
      end
    })
  end)
  
  -- Save the theme for persistence
  vim.g.saved_theme = M.current_theme
  
  return true
end

-- Save current theme to be persistent across sessions
function M.save_theme()
  vim.g.saved_theme = M.current_theme
end

-- Restore theme from saved state
function M.restore_theme()
  local saved_theme = vim.g.saved_theme
  if saved_theme and M.themes[saved_theme] then
    -- Ensure the theme plugin is properly loaded before switching
    local theme_info = M.themes[saved_theme]

    -- Try to ensure the plugin is loaded first
    if saved_theme ~= "gruvbox" then
      -- For other themes, try to load them using lazy if possible
      local success, lazy_plugins = pcall(require, "lazy.core.config")
      if success then
        -- Extract just the plugin name from the path (e.g., "folke/tokyonight.nvim" -> "tokyonight.nvim")
        local plugin_name = theme_info.plugin:match("[^/]+")
        local plugin = lazy_plugins.plugins[plugin_name]
        if plugin then
          -- Load the plugin if it's not already loaded
          if not plugin._.loaded then
            require("lazy.core.loader").load(plugin, { only = plugin })
          end
        end
      end
    end

    -- For gruvbox, it should already be loaded via plugin manager
    if saved_theme == "gruvbox" then
      -- Just run the setup again to ensure it's properly applied
      local ok, err = pcall(theme_info.setup)
      if ok then
        M.current_theme = saved_theme
        vim.g.colors_name = saved_theme  -- Explicitly set colors_name
        vim.notify("Restored " .. theme_info.name .. " theme", vim.log.levels.INFO, { title = "Theme Manager" })
      else
        vim.notify("Failed to restore " .. theme_info.name .. " theme: " .. tostring(err), vim.log.levels.ERROR, { title = "Theme Manager" })
      end
    else
      -- For other themes, switch normally
      M.switch_theme(saved_theme)
    end
  end
end

-- Get list of available themes
function M.get_themes()
  local theme_list = {}
  for name, theme in pairs(M.themes) do
    table.insert(theme_list, {
      name = name,
      display_name = theme.name,
      description = theme.description
    })
  end
  return theme_list
end

-- Get current theme info
function M.get_current_theme()
  return {
    name = M.current_theme,
    display_name = M.themes[M.current_theme] and M.themes[M.current_theme].name or "Unknown",
    description = M.themes[M.current_theme] and M.themes[M.current_theme].description or "No description"
  }
end

return M