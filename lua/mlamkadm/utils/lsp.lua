-- /lua/mlamkadm/utils/lsp.lua
-- LSP utilities using the new Neovim LSP API

local M = {}

--- Get active LSP clients for the current buffer
-- @param bufnr (number|nil) Buffer number, defaults to current buffer
-- @return (table) List of active LSP clients
function M.get_active_clients(bufnr)
  bufnr = bufnr or 0  -- Default to current buffer
  return vim.lsp.get_clients({ bufnr = bufnr })
end

--- Check if any LSP clients are attached to the current buffer
-- @param bufnr (number|nil) Buffer number, defaults to current buffer
-- @return (boolean) True if there are active LSP clients, false otherwise
function M.has_active_clients(bufnr)
  local clients = M.get_active_clients(bufnr)
  return #clients > 0
end

--- Get names of active LSP clients for the current buffer
-- @param bufnr (number|nil) Buffer number, defaults to current buffer
-- @return (table) List of names of active LSP clients
function M.get_client_names(bufnr)
  local clients = M.get_active_clients(bufnr)
  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return names
end

--- Print information about active LSP clients
-- @param bufnr (number|nil) Buffer number, defaults to current buffer
function M.print_client_info(bufnr)
  local clients = M.get_active_clients(bufnr)
  if #clients == 0 then
    print("No active LSP clients")
    return
  end

  print("Active LSP clients:")
  for _, client in ipairs(clients) do
    print(string.format("- %s (id: %d)", client.name, client.id))
  end
end

return M