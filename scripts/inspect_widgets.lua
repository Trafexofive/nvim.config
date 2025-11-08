#!/usr/bin/env lua

-- Widget Registry Inspector
-- Displays all registered widgets in a structured format

package.path = package.path .. ";/home/mlamkadm/.config/nvim/lua/?.lua"
package.path = package.path .. ";/home/mlamkadm/.config/nvim/lua/?/init.lua"

-- Mock vim for headless inspection
_G.vim = {
  fn = {
    expand = function(s) return s:gsub("~", os.getenv("HOME")) end,
    executable = function() return 1 end,
    filereadable = function() return 1 end,
    isdirectory = function() return 1 end,
    system = function() return ".git" end,
  },
  o = { columns = 160, lines = 40, shell = "bash" },
  version = function() return { major = 0, minor = 10, patch = 0 } end,
  log = { levels = { INFO = 1, WARN = 2, ERROR = 3 } },
  api = {
    nvim_create_autocmd = function() end,
    nvim_buf_set_keymap = function() end,
    nvim_create_buf = function() return 1 end,
    nvim_open_win = function() return 1 end,
    nvim_win_set_option = function() end,
    nvim_buf_set_option = function() end,
    nvim_buf_is_loaded = function() return true end,
    nvim_win_is_valid = function() return true end,
    nvim_win_close = function() end,
  },
  keymap = {
    set = function() end,
  },
  cmd = function() end,
  notify = function() end,
  deepcopy = function(t) return vim.tbl_deep_extend("force", {}, t) end,
  tbl_deep_extend = function(mode, ...)
    local result = {}
    for _, tbl in ipairs({...}) do
      for k, v in pairs(tbl or {}) do
        if type(v) == "table" and type(result[k]) == "table" then
          result[k] = vim.tbl_deep_extend(mode, result[k], v)
        else
          result[k] = v
        end
      end
    end
    return result
  end,
}

-- Mock lazy plugin manager
_G.require = function(name)
  if name == "lazy" then
    return { stats = function() return { count = 42 } end }
  end
  return require(name)
end

-- Load framework
local widgets = require("mlamkadm.core.dashboard-widgets")
local config = require("mlamkadm.core.dashboard-config")

-- Display function
local function display_widgets()
  print("\n╔════════════════════════════════════════════════════════════╗")
  print("║           Dashboard Widget Registry Inspector             ║")
  print("╚════════════════════════════════════════════════════════════╝\n")
  
  for _, pane in ipairs({"left", "center", "right"}) do
    local pane_widgets = widgets.registry[pane]
    
    if #pane_widgets > 0 then
      print(string.format("┌─ %s PANE (%d widgets) %s", 
        pane:upper(), #pane_widgets, string.rep("─", 40 - #pane)))
      
      for i, widget in ipairs(pane_widgets) do
        print(string.format("│ %d. %s %s", i, widget.icon, widget.title))
        print(string.format("│    ID: %s", widget.id))
        print(string.format("│    Type: %s", widget.type))
        
        if widget.type == "terminal" then
          local cmd = type(widget.cmd) == "function" and widget.cmd() or widget.cmd
          local short_cmd = cmd:sub(1, 50) .. (cmd:len() > 50 and "..." or "")
          print(string.format("│    Command: %s", short_cmd))
        end
        
        print(string.format("│    Height: %s (min:%d, max:%d)", 
          tostring(widget.height), widget.min_height, widget.max_height))
        
        if widget.refresh > 0 then
          print(string.format("│    Refresh: %ds", widget.refresh))
        end
        
        if widget.interactive then
          print("│    Interactive: yes")
        end
        
        if widget.condition and widget.condition() == false then
          print("│    Status: HIDDEN (condition not met)")
        else
          print("│    Status: VISIBLE")
        end
        
        if i < #pane_widgets then
          print("│")
        end
      end
      print("└" .. string.rep("─", 60) .. "\n")
    end
  end
  
  -- Display configuration summary
  print("\n╔════════════════════════════════════════════════════════════╗")
  print("║                  Configuration Summary                     ║")
  print("╚════════════════════════════════════════════════════════════╝\n")
  
  print("Navigation Keymaps:")
  local nav = widgets.config.navigation
  print(string.format("  Pane Switch:     %s / %s", nav.pane_switch, nav.pane_switch_back))
  print(string.format("  Widget Navigate: %s / %s", nav.widget_prev, nav.widget_next))
  print(string.format("  Widget Action:   %s", nav.widget_action))
  print(string.format("  Widget Refresh:  %s", nav.widget_refresh))
  
  print("\nLayout Configuration:")
  local layout = widgets.config.layout
  print(string.format("  Responsive: %s", layout.responsive and "yes" or "no"))
  print(string.format("  Breakpoints: small=%d, medium=%d, large=%d", 
    layout.breakpoints.small, layout.breakpoints.medium, layout.breakpoints.large))
  print(string.format("  Column Ratios: %.0f%% : %.0f%% : %.0f%%",
    layout.column_ratios[1]*100, layout.column_ratios[2]*100, layout.column_ratios[3]*100))
  
  print("\nWidget Defaults:")
  local defaults = widgets.config.widget_defaults
  print(string.format("  Height: %s (min:%d, max:%d)", 
    tostring(defaults.height), defaults.min_height, defaults.max_height))
  print(string.format("  Refresh: %ds", defaults.refresh))
  print(string.format("  Border: %s", defaults.border))
  print(string.format("  On Error: %s", defaults.on_error))
  
  -- Total widget count
  local total = #widgets.registry.left + #widgets.registry.center + #widgets.registry.right
  print(string.format("\nTotal Widgets: %d", total))
  print("")
end

-- Run
display_widgets()
