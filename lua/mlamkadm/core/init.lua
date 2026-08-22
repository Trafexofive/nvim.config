require("mlamkadm.core.options")
require("mlamkadm.core.keymaps")
require("mlamkadm.core.terminal").setup()
require("mlamkadm.core.title").setup()
require("mlamkadm.core.visual").setup()
require("mlamkadm.core.theme").setup()
require("mlamkadm.core.session_manager")
require("mlamkadm.core.ui").setup()

-- Setup Pi Agent bridge (commands, keymaps)
require("mlamkadm.core.pi").setup()

-- Setup Cortex-Prime MK3 harness bridge (commands, keymaps)
require("mlamkadm.core.cortex").setup()

-- Setup Vim motions registry commands
require("mlamkadm.utils.vim_motions_cmd").setup_commands()
