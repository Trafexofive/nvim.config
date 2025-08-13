-- lua/mlamkadm/plugs/copilot.lua
return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",           -- Load on command
  event = "InsertEnter",     -- Or load when entering insert mode
  dependencies = {
     "zbirenbaum/copilot-cmp", -- Explicit dependency
  },
  config = function()
    require("copilot").setup({
      suggestion = {
        enabled = true,
        auto_trigger = true, -- Trigger suggestions automatically
        keymap = {
           accept = "<C-l>", -- Example: Accept with Ctrl+L
           dismiss = "<C-]>",
           next = "<M-]>", -- Consider changing Meta keymaps if they conflict
           prev = "<M-[>",
        }
      },
      panel = { enabled = true }, -- Enable Copilot panel (:Copilot panel)
      filetypes = {             -- Configure filetypes where Copilot is active/inactive
        -- markdown = true,
        ["*"] = true, -- Enable for all by default
        -- yaml = false, -- Example: Disable for YAML
      },
    })
  end,
}
