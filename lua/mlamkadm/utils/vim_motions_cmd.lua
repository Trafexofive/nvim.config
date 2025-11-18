-- /lua/mlamkadm/utils/vim_motions_cmd.lua
-- Commands for the Vim motions registry

local vim_motions = require("mlamkadm.utils.vim_motions")
local SmpNotify = require("mlamkadm.utils.SmpNotify")

local M = {}

-- Command to register a new motion
function M.register_motion_cmd(motion, description, category)
  if not motion or not description then
    SmpNotify.error("Usage: :VimMotionRegister <motion> <description> [category]")
    return
  end
  
  category = category or "general"
  
  vim_motions.register_motion(motion, description, category)
  SmpNotify.success(string.format("Registered new motion: '%s' - %s (category: %s)", motion, description, category))
end

-- Command to show the motions registry popup
function M.show_motions_cmd()
  require("mlamkadm.utils.vim_motions_ui").show_motions_popup()
end

-- Initialize commands
function M.setup_commands()
  -- Command to register a new motion
  vim.api.nvim_create_user_command('VimMotionRegister', function(opts)
    local args = opts.fargs
    if #args < 2 then
      SmpNotify.error("Usage: :VimMotionRegister <motion> <description> [category]")
      return
    end
    
    local motion = args[1]
    local description = args[2]
    local category = args[3] or "general"
    
    M.register_motion_cmd(motion, description, category)
  end, {
    nargs = '+',
    desc = 'Register a new Vim motion in the motions registry',
    complete = function(ArgLead, CmdLine, CursorPos)
      -- Provide basic completion options
      return { 'movement', 'editing', 'search', 'general' }
    end
  })
  
  -- Command to open the motions registry
  vim.api.nvim_create_user_command('VimMotions', function(opts)
    M.show_motions_cmd()
  end, {
    nargs = 0,
    desc = 'Open the Vim motions registry popup'
  })
end

return M