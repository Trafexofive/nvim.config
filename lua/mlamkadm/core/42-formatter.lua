
return {
  {
    "Diogo-ss/42-C-Formatter.nvim",
    cmd = "CFormat42",  -- Ensures plugin loads when command is called
    config = function()
      local formatter = require("42-formatter")
      formatter.setup({
        formatter = "c_formatter_42",  -- Must be installed system-wide
        filetypes = {
          c = true,
          h = true,
          cpp = true,
          hpp = true
        }
      })

      -- Format on save for C-family files
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.c", "*.h", "*.cpp", "*.hpp" },
        group = vim.api.nvim_create_augroup("42AutoFormat", {}),
        callback = function()
          vim.cmd("CFormat42")
        end
      })

      -- Key mapping for manual formatting
      vim.keymap.set("n", "<leader>cf", "<cmd>CFormat42<CR>", { desc = "Format with 42 Norm" })
    end
  }
}
