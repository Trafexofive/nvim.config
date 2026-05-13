-- Plugin aggregator for lazy.nvim
-- This file loads all plugin configurations from individual files

local plugins = {}

-- Helper to safely require plugin files
local function add_plugin(module_name)
  local ok, plugin = pcall(require, "mlamkadm.plugs." .. module_name)
  if ok and plugin then
    if type(plugin) == "table" then
      -- Handle array of plugins or single plugin
      if plugin[1] then
        vim.list_extend(plugins, plugin)
      else
        table.insert(plugins, plugin)
      end
    end
  else
    vim.notify("Failed to load plugin: " .. module_name, vim.log.levels.WARN)
  end
end

-- Core plugins (loaded first)
add_plugin("mason")
add_plugin("lsp")
add_plugin("nvimcmp")
add_plugin("treesitter")
add_plugin("whichkey")
add_plugin("gitsigns")
add_plugin("icons")

-- UI plugins
add_plugin("theme")       -- Theme (gruvbox, etc.)
add_plugin("notify")      -- Notifications
add_plugin("aart")         -- ?
add_plugin("outline")     -- Outline/symbols
add_plugin("telescope")  -- Fuzzy finder
add_plugin("dap")         -- Debugging
add_plugin("copilot")     -- Copilot
-- add_plugin("gemsini")     -- Gemini AI
-- add_plugin("gemini-explain") -- Gemini explain
add_plugin("smooth-scroll") -- Smooth scrolling
add_plugin("zen")          -- Zen mode
add_plugin("auto-pairs")  -- Auto pairs
add_plugin("lsp_signature") -- LSP signature
add_plugin("indent")      -- Indentation
add_plugin("lint")        -- Linting
add_plugin("formatter")   -- Formatting
add_plugin("markdown")    -- Markdown
add_plugin("explorer")   -- File explorer
add_plugin("session")     -- Session management
add_plugin("mc-modder")  -- Maven/Gradle
add_plugin("cheatsheet") -- Cheatsheet
add_plugin("flash")      -- Flash.nvim (fast navigation)
add_plugin("surround")    -- Surround text
add_plugin("trouble")     -- Trouble (diagnostics list)
add_plugin("oil")         -- Oil (directory editing)
add_plugin("lualine")     -- The standard statusline
add_plugin("bufferline")  -- The standard top bar
add_plugin("comment")     -- Comment.nvim
add_plugin("alpha")        -- Alpha (dashboard)
add_plugin("snacks")       -- Snacks (picker/dashboard/git)
add_plugin("mini")         -- Mini.nvim (all modules)

-- Disable old statusline (using mini.statusline now)
-- add_plugin("line")     -- DISABLED: Replaced by mini.statusline

return plugins
