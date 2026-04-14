local M = {}

-- Default configuration values
M.defaults = {
	api_key = "AIzaSyCa4WCJ-5OBTHbzk-N6pIvdYqIITKP76fQ",
	model = "gemini-3-flash-preview",
	context_lines = 10,
	keybind = "<leader>ce",
	max_tree_files = 500,
}

-- Function to validate configuration
function M.validate(config)
	local errors = {}

	if config.context_lines and type(config.context_lines) ~= "number" then
		table.insert(errors, "context_lines must be a number")
	end

	if config.max_tree_files and type(config.max_tree_files) ~= "number" then
		table.insert(errors, "max_tree_files must be a number")
	end

	if config.model and type(config.model) ~= "string" then
		table.insert(errors, "model must be a string")
	end

	if config.keybind and type(config.keybind) ~= "string" then
		table.insert(errors, "keybind must be a string")
	end

	return #errors == 0, errors
end

-- Function to merge user config with defaults
function M.merge(user_config)
	user_config = user_config or {}

	-- Validate configuration
	local is_valid, errors = M.validate(user_config)
	if not is_valid then
		for _, error in ipairs(errors) do
			vim.notify("Gemini Explain Config Error: " .. error, vim.log.levels.ERROR)
		end
		return nil
	end

	-- Merge configurations
	local merged_config = vim.tbl_deep_extend("force", M.defaults, user_config)

	return merged_config
end

return M
