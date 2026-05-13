-- Neovim 0.12's built-in ftplugin/markdown.lua is just `vim.treesitter.start()`.
-- We can't prevent it from running (ftplugin files don't override — they stack).
-- But our after/ftplugin runs AFTER it, so we can tear it down.
-- vim.treesitter.stop() must run asynchronously because treesitter starts
-- its own parsing in a vim.schedule callback which would otherwise re-queue.
if vim.bo.buftype == "" then
  -- Deferred: let treesitter's scheduled parse callbacks fire first, then kill it
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(0) then
      pcall(vim.treesitter.stop, 0)
    end
  end, 50)
  vim.cmd("syntax enable")
end
