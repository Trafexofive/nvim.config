-- RSS feed reader module for Neovim
-- Provides functionality to fetch, parse, and display RSS feeds

local M = {}

-- Import required libraries
local curl_builtin = require("plenary.curl")
local utils = require("mlamkadm.utils")

-- Default RSS feeds
M.default_feeds = {
  {
    name = "Hacker News",
    url = "https://news.ycombinator.com/rss"
  },
  {
    name = "Reddit Programming",
    url = "https://www.reddit.com/r/programming/.rss"
  },
  {
    name = "Neovim Discourse",
    url = "https://neovim.discourse.group/posts.rss"
  },
  {
    name = "Planet Linux",
    url = "http://planetlinux.org/rss.xml"
  }
}

-- Parse RSS XML content
local function parse_rss(content)
  local items = {}
  
  -- Simple regex-based parsing (in a real implementation, you'd want a proper XML parser)
  -- Extract titles
  for title in content:gmatch("<title>(.-)</title>") do
    if not title:match("^<!%-%-") and not title:match("CDATA") then  -- Skip comment titles
      local item = { title = title:gsub("<!%[CDATA%[(.-)%]%]>", "%1"):gsub("<.->", "") }
      
      -- Extract link for this item
      for link in content:gmatch("<link>(.-)</link>") do
        item.link = link:gsub("<!%[CDATA%[(.-)%]%]>", "%1"):gsub("<.->", "")
        break -- Get first link after title
      end
      
      -- Extract description
      for desc in content:gmatch("<description>(.-)</description>") do
        item.description = desc:gsub("<!%[CDATA%[(.-)%]%]>", "%1"):gsub("<.->", "")
        break -- Get first description after title
      end
      
      table.insert(items, item)
      
      -- Limit to 10 items per feed to prevent too much data
      if #items >= 10 then break end
    end
  end
  
  return items
end

-- Fetch a single RSS feed
function M.fetch_feed(url)
  local response = curl_builtin.get(url)
  
  if response and response.status == 200 then
    return parse_rss(response.body)
  else
    utils.SmpNotify.error("Failed to fetch RSS feed: " .. url)
    return {}
  end
end

-- Fetch all configured feeds
function M.fetch_all_feeds(feeds)
  feeds = feeds or M.default_feeds
  local all_items = {}
  
  for _, feed in ipairs(feeds) do
    local items = M.fetch_feed(feed.url)
    for _, item in ipairs(items) do
      item.feed_name = feed.name
      table.insert(all_items, item)
    end
  end
  
  -- Sort by some pseudo-date or just return as-is
  return all_items
end

-- Create a buffer to display RSS feed
function M.show_feeds(feeds)
  feeds = feeds or M.default_feeds
  
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'rss')
  
  -- Fetch feeds
  local items = M.fetch_all_feeds(feeds)
  
  -- Prepare content
  local lines = { "RSS Feeds", string.rep("=", 30), "" }
  
  for i, item in ipairs(items) do
    table.insert(lines, string.format("%d. %s", i, item.title or "No title"))
    table.insert(lines, string.format("   Feed: %s", item.feed_name or "Unknown"))
    if item.link then
      table.insert(lines, string.format("   Link: %s", item.link))
    end
    if item.description then
      local desc = item.description:gsub("<.->", ""):gsub("%s+", " "):sub(1, 100) .. "..."
      table.insert(lines, string.format("   Summary: %s", desc))
    end
    table.insert(lines, "")
    
    if i >= 20 then -- Limit display to 20 items
      table.insert(lines, "... (truncated)")
      break
    end
  end
  
  -- Set content to buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Open in a new tab
  vim.cmd("tabnew")
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Set up keymaps for the RSS buffer
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>tabclose<CR>', { noremap = true, silent = true, desc = "Close RSS view" })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', ':lua require("mlamkadm.core.rss").open_link()<CR>', { noremap = true, silent = true, desc = "Open link in browser" })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'r', ':lua require("mlamkadm.core.rss").refresh()<CR>', { noremap = true, silent = true, desc = "Refresh feeds" })
  
  return buf
end

-- Open the link under the cursor (placeholder function)
function M.open_link()
  local line = vim.api.nvim_get_current_line()
  -- Extract URL from the line (simplified approach)
  local url = line:match("Link:%s*(https?://%S+)")
  if url then
    -- Use system command to open URL (this is OS-dependent)
    local cmd = vim.o.shell:match("zsh") and "open" or "xdg-open"  -- macOS vs Linux
    if vim.fn.has("win32") == 1 then cmd = "start" end  -- Windows
    
    vim.fn.jobstart({cmd, url}, {detach=true})
  else
    utils.SmpNotify.warn("No link found on current line")
  end
end

-- Refresh the RSS view
function M.refresh()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
  if ft == 'rss' then
    -- We'd need to re-fetch and re-populate the buffer
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Refreshing...", ""})
    
    -- In real implementation: refetch feeds and update content
    vim.defer_fn(function()
      local lines = {"Refreshed RSS Feeds", string.rep("=", 30), "This would show updated feed content"}
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    end, 1000)
  end
end

-- Open RSS feeds in a custom dashboard page
function M.open_dashboard_page()
  -- This would integrate with your dashboard widget system
  -- For now, just show the feeds in a buffer
  M.show_feeds()
end

return M