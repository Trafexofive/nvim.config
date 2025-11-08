-- Simple, solid snacks.nvim dashboard
-- Keep it zen: minimal, functional, beautiful
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = function()
    return {
      dashboard = {
        enabled = true,
        autokeys = "",  -- Disable autokeys
        preset = {
          header = nil,
          keys = {
            { icon = "󰈞", key = "f", desc = "Find File", action = ":Telescope find_files" },
            { icon = "", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
            { icon = "", key = "s", desc = "Sessions", action = ":Telescope session-lens" },
            { icon = "", key = "S", desc = "Restore Session", action = ":SessionRestore" },
            { icon = "", key = "t", desc = "TUI Commands", action = function() require("mlamkadm.core.terminal").show_tui_registry() end },
            { icon = "", key = "w", desc = "Widgets", action = function() require("mlamkadm.core.widgets").open("1_system") end },
            { icon = "󰒲", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = "", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        formats = {
          key = function(item)
            return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
          end,
        },
        sections = {
          -- Single centered layout
          {
            section = "terminal",
            cmd = vim.fn.expand("~/repos/aart/aart") .. " --raw --center " .. vim.fn.expand("~/.config/aart/dashboard-art.aa"),
            height = 26,
            padding = 1,
            ttl = 0,
            indent = 0,
          },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
    }
  end,
  config = function(_, opts)
    require("snacks").setup(opts)
    
    -- Initialize widget system
    require("mlamkadm.core.widgets").setup()
    
    vim.api.nvim_create_autocmd("User", {
      pattern = "SnacksDashboardOpened",
      callback = function()
        vim.defer_fn(function()
          vim.notify("Press 'w' or Ctrl-j to open widgets", vim.log.levels.INFO, { timeout = 2000 })
        end, 1000)
      end,
    })
  end,
}
