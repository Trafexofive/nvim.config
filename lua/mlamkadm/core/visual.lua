-- Visual enhancements for a more polished UI/UX experience
local M = {}

-- Function to set up a clean, zenful winbar
local function setup_winbar()
  -- Create highlights for winbar
  vim.api.nvim_set_hl(0, "WinBar", { fg = "#a6adc8", bg = "NONE", bold = true })
  vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#585b70", bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarSeparator", { fg = "#6c7086", bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarIcon", { fg = "#74c7ec" }) -- Default icon color
  
  -- Set up autocommand to apply winbar to all windows, but skip special windows
  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    callback = function()
      -- Only apply winbar to normal windows, not special ones like telescope, dashboard, etc.
      local buf = vim.api.nvim_win_get_buf(0)
      local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
      local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
      
      -- Skip winbar for special buffer types
      if buftype ~= "" and buftype ~= "help" then
        return
      end
      
      -- Skip winbar for specific filetypes
      if filetype == "snacks_dashboard" or filetype == "dashboard" or filetype == "alpha" then
        return
      end
      
      vim.opt_local.winbar = "%{%v:lua.require'mlamkadm.core.visual'.get_winbar()%}"
    end,
    desc = "Set winbar for current window",
  })
  
  -- Also apply to all existing windows, with same checks
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.api.nvim_win_call(win, function()
      local buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
      local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
      
      if buftype == "" or buftype == "help" then
        if filetype ~= "snacks_dashboard" and filetype ~= "dashboard" and filetype ~= "alpha" then
          vim.opt_local.winbar = "%{%v:lua.require'mlamkadm.core.visual'.get_winbar()%}"
        end
      end
    end)
  end
end

function M.setup()
  -- Set global border style
  vim.o.pumblend = 10
  vim.o.winblend = 10
  vim.o.wildoptions = 'pum'
  vim.o.pumheight = 10

  -- Set up consistent border style for floating windows
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
  })

  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = "rounded",
  })

  -- Set up default border for all floating windows
  local set_floating_window_border = function()
    vim.api.nvim_command("highlight! FloatBorder guifg=#928374 guibg=NONE")
  end

  set_floating_window_border()

  -- Add autocommand to ensure borders are applied consistently
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = set_floating_window_border,
    desc = "Set consistent floating window borders"
  })

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
    desc = "Enhance highlights after colorscheme change"
  })

  -- Set better fold colors
  vim.o.fillchars = [[eob: ,fold:.,foldopen:,foldclose:,foldsep: ]]
  
  -- Improve cursor appearance
  vim.o.cursorline = true
  vim.o.termguicolors = true
  
  -- Better popup menu appearance
  vim.o.pumblend = 10
  vim.o.winblend = 10
  
  -- Set up zenful winbar (top bar)
  setup_winbar()
end

-- Function to generate winbar content
function M.get_winbar()
  local filename = vim.fn.expand("%:t")
  local modified = vim.bo.modified and " ●" or ""
  
  if filename == "" then
    filename = "[No Name]"
  end
  
  local winbar_str = ""
  
  -- Add file type icon if devicons is available
  local devicons_available, devicons = pcall(require, "nvim-web-devicons")
  if devicons_available then
    local ft = vim.bo.filetype
    local icon, hl_color = devicons.get_icon(filename, ft, { default = true })
    if icon then
      winbar_str = winbar_str .. "%#WinBarIcon#" .. icon .. "%* "
    end
  end
  
  -- Add the filename with modified indicator
  winbar_str = winbar_str .. "%#WinBar#" .. filename .. modified .. "%*"
  
  -- Center: Current time and date
  local current_time = os.date("%H:%M:%S")
  local current_date = os.date("%m/%d")
  winbar_str = winbar_str .. "%=" -- Push everything to center
  winbar_str = winbar_str .. "%#WinBar#" .. current_date .. " " .. current_time .. "%*"
  winbar_str = winbar_str .. "%=" -- Balance the centering
  
  -- Add git branch info to the far right
  local gitsigns_available, gitsigns = pcall(require, "gitsigns")
  if gitsigns_available then
    local gs = vim.b.gitsigns_status_dict
    if gs and gs.head and gs.head ~= "" then
      winbar_str = winbar_str .. "%#WinBar#" .. " 󰊢 " .. gs.head .. "%*"
    end
  end
  
  return winbar_str
end

return M