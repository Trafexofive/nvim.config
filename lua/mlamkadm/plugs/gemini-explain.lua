-- lua/mlamkadm/plugs/gemini-explain.lua
-- Gemini API plugin for code explanation with contextual awareness
return {
	dir = vim.fn.stdpath("config") .. "/lua/gemini-explain", -- Local plugin directory
	dependencies = { "nvim-lua/plenary.nvim" }, -- Required for HTTP requests
	config = function()
		require("gemini-explain").setup({
			api_key = os.getenv("GEMINI_API_KEY"), -- or read from file
			model = "gemini-3-flash-preview",
			context_lines = 10, -- lines above/below selection
			keybind = "<leader>ce", -- code explain
			max_tree_files = 500, -- limit for large repos
		})
	end,
	event = "VeryLazy",
}

