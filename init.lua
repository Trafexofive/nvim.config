-- Set leader keys BEFORE loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\\\"

-- Load lazy.nvim plugin manager first
require("mlamkadm.lazy")

-- Load core settings (options, keymaps) after lazy
require("mlamkadm.core")
