-- Main theme module - delegates to modular theming system
-- Ensures backward compatibility while providing new functionality

local theming = require("mlamkadm.core.theming.theming")
local ui = require("mlamkadm.core.theming.ui")

local M = {}

-- Public API functions - delegate to modular system
M.select_theme = function()
  ui.select_theme()
end

M.switch_theme = theming.switch_theme
M.get_themes = theming.get_themes
M.get_current_theme = theming.get_current_theme
M.save_theme = theming.save_theme
M.restore_theme = theming.restore_theme

-- Original theme functionality that was in the original file
M.themes = theming.themes
M.current_theme = theming.current_theme

-- Apply visual enhancements - copy from original
function M.apply_visual_enhancements()
  local ok, visual = pcall(require, "mlamkadm.core.visual")
  if ok then
    visual.setup()
  else
    -- Fallback visual enhancements
    vim.o.pumblend = 10
    vim.o.winblend = 10
    vim.o.wildoptions = 'pum'
    vim.o.pumheight = 10
    
    -- Set up consistent border style for floating windows
    if vim.lsp and vim.lsp.handlers then
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
      })

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = "rounded",
      })
    end

    -- Enhance colors and highlights
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        -- Enhance visual elements for better contrast
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#fabd2f", bg = "NONE", bold = true })
        vim.api.nvim_set_hl(0, "Visual", { bg = "#3c3d5a" })
        vim.api.nvim_set_hl(0, "Search", { bg = "#458588", fg = "#ebdbb2" })
        vim.api.nvim_set_hl(0, "IncSearch", { bg = "#d79921", fg = "#282828" })
        vim.api.nvim_set_hl(0, "LineNr", { fg = "#7c8f8f" })
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#3c3836" })
        
        -- Enhance git signs
        vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#a6da95" })
        vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#7aa2f7" })
        vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#f7768e" })
        
        -- Enhance dashboard elements if in dashboard
        vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#89b4fa", bold = true })
        vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = "#cba6f7", bold = true })
        vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = "#a6adc8" })
      end,
      desc = "Enhance highlights after colorscheme change",
      group = vim.api.nvim_create_augroup("CustomHighlights", { clear = true })
    })

    -- Set better fold colors
    vim.o.fillchars = [[eob: ,fold:.,foldopen:,foldclose:,foldsep: ]]
    
    -- Improve cursor appearance
    vim.o.cursorline = true
    vim.o.termguicolors = true
  end
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command("Theme", function(opts)
    if #opts.fargs == 0 then
      -- If no arguments provided, open theme selector
      M.select_theme()
    else
      -- Switch to the specified theme
      M.switch_theme(opts.fargs[1])
    end
  end, {
    desc = "Manage themes",
    nargs = "*",
    complete = function(arg_lead, cmdline, cursor_pos)
      local themes = M.get_themes()
      local completions = {}
      for _, theme in ipairs(themes) do
        if theme.name:match("^" .. arg_lead) then
          table.insert(completions, theme.name)
        end
      end
      return completions
    end
  })
end

-- Setup function
function M.setup()
  -- Set up commands
  M.setup_commands()
  
  -- Apply visual enhancements
  local ok, _ = pcall(M.apply_visual_enhancements)
  if not ok then
    vim.o.pumblend = 10
    vim.o.winblend = 10
  end
  
  -- Set up autocommands to save theme when changing
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      -- Update the current theme to match what's actually active
      local theme_name = vim.g.colors_name or "gruvbox"
      if M.themes[theme_name] then
        M.current_theme = theme_name
      end
      M.save_theme()
    end,
    desc = "Save current theme when colorscheme changes",
    group = vim.api.nvim_create_augroup("ThemePersistence", { clear = true })
  })
  -- Initialize the current theme from what's currently active
  -- If no theme is active (colors_name is still none), explicitly apply the default theme
  if not vim.g.colors_name or vim.g.colors_name == "" then
    local default_theme = "gruvbox"
    if M.themes[default_theme] then
      M.themes[default_theme].setup()  -- Apply the full theme setup
      M.current_theme = default_theme
      M.save_theme()
    end
  else
    -- If a theme is already active, just initialize our current theme to match
    local active_theme = vim.g.colors_name
    if M.themes[active_theme] then
      M.current_theme = active_theme
      M.save_theme()
    end
  end

  -- Use a later timer to ensure plugins are fully loaded
  vim.defer_fn(function()
    -- Only restore if a theme was previously saved and it's different from the default
    local saved_theme = vim.g.saved_theme
    if saved_theme and saved_theme ~= "gruvbox" then
      M.restore_theme()
    end
  end, 500) -- Delay restoration slightly to ensure everything is loaded
end

return M
