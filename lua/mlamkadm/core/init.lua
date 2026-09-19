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

-- LSP idle policy: release resident RAM from heavy language servers (clangd,
-- pyright, jdtls, rust-analyzer) after 20min idle; re-attach on use.
require("mlamkadm.utils.lsp_idle").setup({ idle_min = 20, check_sec = 30 })

-- Manual control over the LSP idle policy.
-- :LspIdleStop   -> immediately release heavy servers (e.g. before a build/leaving)
-- :LspIdleResume  -> immediately re-attach the server for the current buffer
vim.api.nvim_create_user_command("LspIdleStop", function()
    require("mlamkadm.utils.lsp_idle").stop_now()
end, { desc = "LSP idle: stop heavy servers now (release RAM)" })
vim.api.nvim_create_user_command("LspIdleResume", function()
    require("mlamkadm.utils.lsp_idle").resume_now()
end, { desc = "LSP idle: re-attach heavy server for current buffer" })
