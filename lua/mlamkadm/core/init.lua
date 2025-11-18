require("mlamkadm.core.options")
require("mlamkadm.core.keymaps")
require("mlamkadm.core.terminal")
require("mlamkadm.core.visual").setup()
require("mlamkadm.core.theme").setup()
require("mlamkadm.core.session_manager")
require("mlamkadm.core.ui").setup()

-- Setup Vim motions registry commands
require("mlamkadm.utils.vim_motions_cmd").setup_commands()
