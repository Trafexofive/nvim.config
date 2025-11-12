-- ============================================================================
-- FeedMe.nvim - Single File Edition
-- A beautiful, configurable RSS reader for Neovim
-- ============================================================================
-- Installation (Lazy.nvim):
-- {
--   "yourusername/feedme.nvim",
--   dependencies = { "nvim-lua/plenary.nvim" },
--   config = function() require("feedme").setup() end
-- }
--
-- Usage: :FeedMe
-- ============================================================================

local M = {}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================
M.config = {
	feeds = {
		{ name = "Hacker News", url = "https://news.ycombinator.com/rss", icon = "󰃶", color = "#ff6600" },
		{ name = "Neovim Discourse", url = "https://neovim.discourse.group/posts.rss", icon = "" },
		{ name = "Reddit Programming", url = "https://www.reddit.com/r/programming/.rss", icon = "󰞱" },
	},
	max_items = 30,
	cache_ttl = 600, -- 10 minutes
	window = {
		width = 0.9,
		height = 0.8,
		border = "rounded",
		title = " 󰼛 FeedMe ",
	},
	format = {
		title_length = 70,
		description_length = 100,
	},
	keys = {
		close = "q",
		open_link = "<CR>",
		refresh = "R",
		toggle_read = "r",
	},
}

-- =============================================================================
-- MINIMAL XML PARSER (inlined, RSS/Atom only)
-- =============================================================================
local function parse_rss_xml(xml)
	local items = {}
	local current = {}
	local in_item = false
	local tag_stack = {}

	-- Simple state machine for RSS/Atom
	for tag, text in xml:gmatch("<([%w_:]+)[^>]->(.-)</%1>") do
		if tag == "item" or tag == "entry" then
			if in_item then
				table.insert(items, current)
				current = {}
				if #items >= M.config.max_items then
					break
				end
			end
			in_item = true
		end

		if in_item then
			if tag == "title" then
				current.title = text:gsub("<!%[CDATA%[(.-)%]%]>", "%1"):gsub("<.->", "")
			elseif tag == "link" then
				current.link = text
			elseif tag == "description" or tag == "summary" then
				current.description = text:gsub("<!%[CDATA%[(.-)%]%]>", "%1")
			elseif tag == "pubDate" or tag == "published" or tag == "updated" then
				current.pubDate = text
			end
		end
	end

	if in_item then
		table.insert(items, current)
	end
	return items
end

-- =============================================================================
-- ASYNC FETCHER (non-blocking)
-- =============================================================================
local function fetch_feed_async(feed, callback)
	local curl = require("plenary.curl")

	curl.get(feed.url, {
		timeout = 10000,
		headers = { ["User-Agent"] = "FeedMe.nvim/1.0" },
		callback = vim.schedule_wrap(function(response)
			if not response or response.status ~= 200 then
				vim.notify(
					string.format("❌ %s: %s", feed.name, response and response.status or "timeout"),
					vim.log.levels.WARN
				)
				callback(nil)
				return
			end

			local items = parse_rss_xml(response.body)
			for _, item in ipairs(items) do
				item.feed_name = feed.name
				item.feed_icon = feed.icon or "󰼛"
				item.read = false
			end
			callback(items)
		end),
	})
end

-- =============================================================================
-- CACHE SYSTEM (simple JSON file)
-- =============================================================================
local cache_path = vim.fn.stdpath("cache") .. "/feedme_cache.json"

local function save_cache(items)
	local data = { timestamp = os.time(), items = items }
	vim.fn.writefile({ vim.json.encode(data) }, cache_path)
end

local function load_cache()
	if vim.fn.filereadable(cache_path) == 0 then
		return {}
	end
	local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(cache_path), "\n"))
	if ok and data.timestamp and (os.time() - data.timestamp) < M.config.cache_ttl then
		return data.items
	end
	return {}
end

-- =============================================================================
-- UI SYSTEM (floating window + highlights)
-- =============================================================================
local ui_state = { win = nil, buf = nil, items = {} }

local function setup_highlights()
	vim.api.nvim_set_hl(0, "FeedMeTitle", { fg = "#7aa2f7", bold = true, default = true })
	vim.api.nvim_set_hl(0, "FeedMeIcon", { fg = "#7dcfff", default = true })
	vim.api.nvim_set_hl(0, "FeedMeLink", { fg = "#bb9af7", underline = true, default = true })
	vim.api.nvim_set_hl(0, "FeedMeRead", { fg = "#565f89", strikethrough = true, default = true })
	vim.api.nvim_set_hl(0, "FeedMeUnread", { fg = "#ff9e64", bold = true, default = true })
end

local function render_buffer()
	if not ui_state.buf then
		return
	end
	vim.api.nvim_buf_set_option(ui_state.buf, "modifiable", true)

	local lines = {}
	local hl_groups = {}

	for i, item in ipairs(ui_state.items) do
		local start = #lines

		-- Title with icon
		local icon = item.read and "✓" or "●"
		table.insert(lines, string.format(" %s %s", icon, item.title:sub(1, M.config.format.title_length)))
		table.insert(hl_groups, { line = start, hl = item.read and "FeedMeRead" or "FeedMeUnread" })

		-- Metadata: icon + feed name
		table.insert(lines, string.format("   %s %s", item.feed_icon, item.feed_name))
		table.insert(hl_groups, { line = start + 1, hl = "FeedMeIcon" })

		-- Link
		if item.link then
			table.insert(lines, "   " .. item.link)
			table.insert(hl_groups, { line = start + 2, hl = "FeedMeLink" })
		end

		-- Preview
		if item.description then
			local preview = item.description
				:gsub("%s+", " ")
				:gsub("<.->", "")
				:sub(1, M.config.format.description_length) .. "…"
			table.insert(lines, "   " .. preview)
		end

		table.insert(lines, "") -- Spacer
	end

	vim.api.nvim_buf_set_lines(ui_state.buf, 0, -1, false, lines)

	-- Apply highlights
	for _, h in ipairs(hl_groups) do
		if h.line < #lines then
			vim.api.nvim_buf_add_highlight(ui_state.buf, -1, h.hl, h.line, 0, -1)
		end
	end

	vim.api.nvim_buf_set_option(ui_state.buf, "modifiable", false)
end

local function open_window()
	setup_highlights()

	local width = math.floor(vim.o.columns * M.config.window.width)
	local height = math.floor(vim.o.lines * M.config.window.height)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	ui_state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(ui_state.buf, "filetype", "feedme")

	ui_state.win = vim.api.nvim_open_win(ui_state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = M.config.window.border,
		title = M.config.window.title,
		title_pos = "center",
	})

	-- Load cached items first
	ui_state.items = load_cache()
	render_buffer()

	-- Fetch fresh data
	M.refresh()

	-- Keymaps
	vim.keymap.set("n", M.config.keys.close, M.close, { buffer = ui_state.buf, silent = true })
	vim.keymap.set("n", M.config.keys.refresh, M.refresh, { buffer = ui_state.buf, silent = true })
	vim.keymap.set("n", M.config.keys.open_link, M.open_link, { buffer = ui_state.buf, silent = true })
	vim.keymap.set("n", M.config.keys.toggle_read, M.toggle_read, { buffer = ui_state.buf, silent = true })
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	vim.api.nvim_create_user_command("FeedMe", function()
		if ui_state.win and vim.api.nvim_win_is_valid(ui_state.win) then
			M.close()
		else
			open_window()
		end
	end, {})
end

function M.refresh()
	if not ui_state.buf then
		return
	end
	vim.api.nvim_buf_set_lines(ui_state.buf, 0, -1, false, { " 󱑋 Fetching feeds..." })

	local jobs = {}
	local all_items = {}

	for _, feed in ipairs(M.config.feeds) do
		table.insert(jobs, function()
			fetch_feed_async(feed, function(items)
				if items then
					vim.list_extend(all_items, items)
				end
			end)
		end)
	end

	require("plenary.async").util.join(jobs, 6) -- Max 6 parallel

	-- Sort and limit
	table.sort(all_items, function(a, b)
		return (a.pubDate or "") > (b.pubDate or "")
	end)
	ui_state.items = vim.list_slice(all_items, 1, M.config.max_items)

	save_cache(ui_state.items)
	render_buffer()
	vim.notify(string.format("✅ Loaded %d articles", #ui_state.items), vim.log.levels.INFO)
end

function M.close()
	if ui_state.win and vim.api.nvim_win_is_valid(ui_state.win) then
		vim.api.nvim_win_close(ui_state.win, true)
	end
	ui_state = { win = nil, buf = nil, items = {} }
end

function M.open_link()
	local row = vim.fn.line(".")
	local idx = math.floor(row / 5) + 1
	local item = ui_state.items[idx]

	if item and item.link then
		local cmd = vim.fn.has("mac") == 1 and "open" or (vim.fn.has("win32") == 1 and "start" or "xdg-open")
		vim.fn.jobstart({ cmd, item.link }, { detach = true })
		item.read = true
		save_cache(ui_state.items)
		render_buffer()
	end
end

function M.toggle_read()
	local row = vim.fn.line(".")
	local idx = math.floor(row / 5) + 1
	if ui_state.items[idx] then
		ui_state.items[idx].read = not ui_state.items[idx].read
		save_cache(ui_state.items)
		render_buffer()
	end
end

return M

