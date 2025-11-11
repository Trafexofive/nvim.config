-- Custom UI framework for dashboard pages
-- Provides a cleaner, more integrated approach than raw buffers

local M = {}

-- Page registry
M.pages = {}
M.current_page = nil
M.page_order = {}

-- Create a new UI page
function M.create_page(name, opts)
  opts = opts or {}
  
  local page = {
    name = name,
    title = opts.title or name,
    sections = opts.sections or {},
    layout = opts.layout or "vertical",
    render = opts.render,
    keymaps = opts.keymaps or {},
    -- Add any other page-specific properties here
  }
  
  M.pages[name] = page
  table.insert(M.page_order, name)
  
  return page
end

-- Open a specific page
function M.open_page(page_name)
  local page = M.pages[page_name]
  if not page then
    vim.notify("Page '" .. page_name .. "' not found", vim.log.levels.ERROR)
    return
  end
  
  -- Build content for this page
  local content = {}
  
  -- Add title
  table.insert(content, { type = "text", lines = { "" } })
  table.insert(content, { 
    type = "text", 
    lines = { "══════ " .. page.title:upper() .. " ══════" }, 
    opts = { hl = "DashboardHeader" } 
  })
  table.insert(content, { type = "text", lines = { "" } })
  
  -- Add sections/content based on the page's render function
  if page.render then
    local page_content = page.render()
    for _, line in ipairs(page_content) do
      table.insert(content, { type = "text", lines = { line } })
    end
  end
  
  -- For now we'll open in a buffer
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}
  
  for _, item in ipairs(content) do
    if item.type == "text" then
      for _, line in ipairs(item.lines) do
        table.insert(lines, line)
      end
    end
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'dashboard_ui')
  
  -- Open the temp buffer
  vim.cmd("enew")
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Set keymaps to return to dashboard
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>lua require("mlamkadm.core.ui").close_page()<CR>', {
    noremap = true,
    silent = true,
    desc = "Return to dashboard"
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>lua require("mlamkadm.core.ui").close_page()<CR>', {
    noremap = true,
    silent = true,
    desc = "Return to dashboard"
  })
  
  -- Launch TUI when 'o' is pressed
  vim.api.nvim_buf_set_keymap(buf, 'n', 'o', '', {
    callback = function()
      local current_page_obj = M.pages[M.current_page]
      if current_page_obj and current_page_obj.launch_tui then
        -- Close current page before launching TUI
        local current_buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_is_valid(current_buf) then
          pcall(vim.api.nvim_buf_delete, current_buf, { force = true })
        end
        current_page_obj.launch_tui()
      end
    end,
    noremap = true,
    silent = true,
    desc = "Open TUI"
  })
  
  M.current_page = page_name
end

-- Close current page and return to dashboard
function M.close_page()
  local current_buf = vim.api.nvim_get_current_buf()
  M.current_page = nil
  
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(current_buf) then
      pcall(vim.api.nvim_buf_delete, current_buf, { force = true })
    end
    local snacks_available, snacks = pcall(require, "snacks")
    if snacks_available then
      snacks.dashboard()
    else
      -- Fallback to basic dashboard if snacks is not available
      pcall(vim.cmd, "Dashboard")
    end
  end)
end

-- Setup function to initialize the UI framework
function M.setup()
  -- Create default pages for system monitoring tools
  
  -- btop Page
  M.create_page("btop", {
    title = "System Monitor (btop)",
    render = function()
      local lines = {
        "┌─ btop - System Monitor ──────────────────────────┐",
        "│                                                  │",
        "│  A monitor of resources with a more advanced     │", 
        "│  terminal UI and in-depth performance metrics.   │",
        "│                                                  │",
        "│  - CPU, Memory, Disk, Network usage              │",
        "│  - Process viewer with search and kill options   │",
        "│  - Mouse support and customizable themes         │",
        "│                                                  │",
        "└──────────────────────────────────────────────────┘",
        "",
        "  Press 'o' to launch btop in terminal",
      }
      return lines
    end,
    launch_tui = function()
      -- Launch btop with your terminal system
      _G.Poptui("btop", nil, { use_theme = false })  -- btop has its own theme
    end
  })
  
  -- lazydocker Page
  M.create_page("lazydocker", {
    title = "Docker Manager (lazydocker)",
    render = function()
      local lines = {
        "┌─ lazydocker - Docker Manager ────────────────────┐", 
        "│                                                  │",
        "│  A simple terminal UI for both docker and        │",
        "│  docker-compose, written in Go with the tview    │",
        "│  library.                                        │",
        "│                                                  │",
        "│  - View and manage containers, images, volumes   │",
        "│  - View logs and attach to containers            │",
        "│  - Execute commands in containers                │",
        "│                                                  │",
        "└──────────────────────────────────────────────────┘",
        "",
        "  Press 'o' to launch lazydocker in terminal",
      }
      return lines
    end,
    launch_tui = function()
      -- Launch lazydocker with your terminal system
      _G.Poptui("lazydocker")
    end
  })
end

return M