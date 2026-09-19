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

-- Apply a theme by name safely: run its setup, mark it current, persist.
-- Returns (true) on success, or (nil, err) if the setup raised.
function M.apply_theme(name)
  local t = M.themes[name]
  if not t then return nil, "theme not registered: " .. tostring(name) end
  local ok, err = pcall(t.setup)
  if not ok then return nil, err end
  M.current_theme = name
  M.save_theme()
  return true
end

-- Ensure SOME theme is active; apply the default (gruvbox) if none is, and
-- re-attempt shortly after if the plugin wasn't ready yet. Idempotent: no-op
-- once a colorscheme is already set, so it is safe to call from every startup
-- safety-net hook.
function M.ensure_default_theme()
  if vim.g.colors_name and vim.g.colors_name ~= "" then return end
  local ok, err = M.apply_theme("gruvbox")
  if not ok then
    vim.defer_fn(function()
      local ok2, err2 = M.apply_theme("gruvbox")
      if not ok2 then
        vim.notify("Failed to apply default theme: " .. tostring(err2 or err), vim.log.levels.ERROR, { title = "Theme Manager" })
      end
    end, 100)
  end
end

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
      vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
        return vim.lsp.handlers.hover(err, result, ctx, vim.tbl_extend("force", config or {}, { border = "rounded" }))
      end
      vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
        return vim.lsp.handlers.signature_help(err, result, ctx, vim.tbl_extend("force", config or {}, { border = "rounded" }))
      end
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

      -- Also save to session if auto-session is enabled
      if package.loaded["auto-session"] then
        local auto_session = require("auto-session")
        if auto_session.save then
          -- Small delay to ensure theme is fully loaded before saving session
          vim.defer_fn(function()
            pcall(auto_session.save)  -- Don't error if session saving fails
          end, 200)
        end
      end
    end,
    desc = "Save current theme when colorscheme changes",
    group = vim.api.nvim_create_augroup("ThemePersistence", { clear = true })
  })

  -- Initialize the current theme: if a colorscheme is already active, just
  -- mirror it; otherwise apply the default. Single entry point for the many
  -- startup safety nets below.
  local active_theme = vim.g.colors_name
  if active_theme and active_theme ~= "" then
    if M.themes[active_theme] then
      M.current_theme = active_theme
      M.save_theme()
    end
  else
    M.ensure_default_theme()
  end

  -- Restore saved theme if available (deferred to after startup)
  vim.defer_fn(function()
    local saved_theme = vim.g.saved_theme
    if saved_theme and M.themes[saved_theme] then
      M.restore_theme()
    end
  end, 500) -- Delay restoration slightly to ensure everything is loaded

  -- Ultimate safeguard: ensure theme is applied after full startup regardless
  -- of errors.
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(function()
        if not vim.g.colors_name or vim.g.colors_name == "" then
          M.ensure_default_theme()
          vim.notify("Applied default theme after full startup", vim.log.levels.INFO, { title = "Theme Manager" })
        end
      end, 100) -- Small delay to ensure everything is ready
    end,
    desc = "Ensure theme is applied after full startup",
    group = vim.api.nvim_create_augroup("ThemeEnsureDefault", { clear = true }),
    once = true,  -- Run only once
  })

  -- More robust theme restoration for session contexts
  vim.api.nvim_create_autocmd("UIEnter", {
    callback = function()
      local saved_theme = vim.g.saved_theme
      if saved_theme and M.themes[saved_theme] and saved_theme ~= (vim.g.colors_name or "gruvbox") then
        vim.schedule(function()
          M.restore_theme()
        end)
      end
    end,
    desc = "Restore theme on UI enter for session contexts",
    group = vim.api.nvim_create_augroup("ThemeRestoreOnUIEnter", { clear = true }),
  })

  -- Ensure theme is saved when session is about to be saved
  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "Session.vim", -- When a session file is being written
    callback = function()
      M.save_theme() -- Ensure theme is saved before session
    end,
    desc = "Save theme before session write",
    group = vim.api.nvim_create_augroup("ThemeBeforeSessionWrite", { clear = true }),
  })
end

return M