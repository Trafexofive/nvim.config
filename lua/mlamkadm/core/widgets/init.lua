-- Custom widget system
-- Full buffer control, live updates, TUI support
local M = {}

M.page = require("mlamkadm.core.widgets.page")
M.buffer = require("mlamkadm.core.widgets.buffer")

-- Widget types
M.types = {
  text = require("mlamkadm.core.widgets.types.text"),
  command = require("mlamkadm.core.widgets.types.command"),
  tui = require("mlamkadm.core.widgets.types.tui"),
}

-- Setup function - call this from your config
function M.setup()
  -- Create default pages
  M.create_default_pages()
  
  -- Set up global keymaps
  M.setup_keymaps()
end

-- Create default widget pages
function M.create_default_pages()
  -- Page 1: System Info
  local system_page = M.page.create("1_system", { layout = "vertical" })
  
  system_page:add_widget(M.types.command.new({
    title = "Calendar",
    cmd = "cal",
    height = 10,
  }))
  
  system_page:add_widget(M.types.command.new({
    title = "System Info",
    cmd = "uname -a",
    height = 3,
  }))
  
  system_page:add_widget(M.types.command.new({
    title = "Disk Usage",
    cmd = "df -h | head -5",
    height = 7,
  }))
  
  -- Page 2: Development
  local dev_page = M.page.create("2_development", { layout = "vertical" })
  
  dev_page:add_widget(M.types.command.new({
    title = "Git Status",
    cmd = "git status -s 2>/dev/null || echo 'Not in git repo'",
    height = 8,
  }))
  
  dev_page:add_widget(M.types.command.new({
    title = "Recent Commits",
    cmd = "git log --oneline -5 2>/dev/null || echo 'Not in git repo'",
    height = 8,
  }))
  
  dev_page:add_widget(M.types.command.new({
    title = "Git Branch",
    cmd = "git branch 2>/dev/null | grep '*' | sed 's/* //' || echo 'Not in git repo'",
    height = 3,
  }))
end

-- Set up global keymaps
function M.setup_keymaps()
  -- Helper to set keymaps on buffer
  local function set_dashboard_keymaps(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    
    local opts = { buffer = buf, nowait = true, silent = true }
    
    -- Ctrl-j: Next page (cycle forward from dashboard)
    vim.keymap.set('n', '<C-j>', function()
      M.page.next()
    end, opts)
    
    -- Ctrl-k: Previous page (cycle backward from dashboard)
    vim.keymap.set('n', '<C-k>', function()
      M.page.prev()
    end, opts)
  end
  
  -- Set keymaps immediately on current buffer if it's dashboard
  vim.schedule(function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype == "snacks_dashboard" then
      set_dashboard_keymaps(buf)
    end
  end)
  
  -- Also set up autocmd for future dashboard buffers
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "snacks_dashboard",
    callback = function(event)
      set_dashboard_keymaps(event.buf)
    end,
  })
end

-- Convenience function to open a specific page
function M.open(page_name)
  local page = M.page.get(page_name)
  if page then
    page:open()
  else
    vim.notify("Page '" .. page_name .. "' not found", vim.log.levels.WARN)
  end
end

return M
