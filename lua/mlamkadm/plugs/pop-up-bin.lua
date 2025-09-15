return {
  dir = vim.fn.stdpath("config") .. "/lua/mlamkadm/libs/pop-up-bin",
  event = "VeryLazy",
  config = function()
    require("mlamkadm.libs.pop-up-bin").setup({
      -- Settings from the original file concept
      border = "rounded",
      width = 80,
      height = 20,
      title = "Pop-Up Bin",
      title_pos = "center",
      close_key = "q",
      winblend = 0,
      zindex = 50,
    })
  end,
}
