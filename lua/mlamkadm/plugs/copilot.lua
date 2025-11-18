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
      panel = {
        enabled = true,
        auto_refresh = false,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = true, -- Trigger suggestions automatically
        debounce = 75, -- Faster debounce for more responsive suggestions
        keymap = {
           accept = "<C-l>", -- Accept with Ctrl+L
           accept_word = false,
           accept_line = false,
           next = "<M-]>", -- Next suggestion
           prev = "<M-[>", -- Previous suggestion
           dismiss = "<C-]>",
        },
        -- Filetype optimizations for better performance
        filetypes = {
          ["*"] = true, -- Enable for all by default
        },
      },
      filetypes = {             -- Configure filetypes where Copilot is active/inactive
        yaml = false,
        markdown = true,
        help = false,
        gitcommit = true,
        ["*"] = true, -- Enable for all by default
      },
      server_opts_overrides = {
        trace = "off", -- Disable tracing for better performance
        settings = {
          advanced = {
            -- Improve the speed and quality of suggestions
            completeInComMENTS = false, -- Don't suggest in comments
            listCount = 6, -- Number of completions to fetch
            inlineSuggestCount = 3, -- Number of inline suggestions
          }
        }
      },
    })
  end,
}
