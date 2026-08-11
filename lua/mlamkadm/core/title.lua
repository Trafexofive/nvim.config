-- /lua/mlamkadm/core/title.lua
-- Window title reflects the auto-session project (CWD) name.
-- For a zellij terminal buffer the running command is `zellij attach --create …`
-- (long/ugly), so we show just "project · zellij" instead of "project · <cmd>".

local M = {}

local function project_name()
  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")
  if name == "" then name = "home" end
  return name
end

-- True when the buffer is a terminal running zellij.
local function is_zellij_terminal(buf)
  if vim.bo[buf].buftype ~= "terminal" then
    return false
  end
  local job = vim.b[buf].terminal_job_id
  if not job or job <= 0 then
    return false
  end
  local ok, info = pcall(vim.api.nvim_get_chan_info, job)
  if not ok or not info or not info.argv then
    return false
  end
  for _, a in ipairs(info.argv) do
    if a == "zellij" then
      return true
    end
  end
  return false
end

local function refresh_title()
  local buf = vim.api.nvim_get_current_buf()
  if is_zellij_terminal(buf) then
    vim.o.titlestring = project_name() .. " · zellij"
  else
    vim.o.titlestring = project_name() .. " · %t%m"
  end
end

function M.setup()
  vim.o.title = true
  vim.o.titleold = "" -- don't leave a stale terminal title on exit

  refresh_title()
  local group = vim.api.nvim_create_augroup("MlamkadmTitle", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = group,
    callback = refresh_title,
    desc = "Refresh window title (zellij-aware)",
  })
end

return M
