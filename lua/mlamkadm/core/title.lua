-- /lua/mlamkadm/core/title.lua
-- Window title reflects the auto-session project (CWD) name + current file.
-- This is what the compositor (niri) reads for alt-tab, the taskbar, etc.
--
-- auto-session names sessions by the working directory, so the project name is
-- the CWD basename (same as alpha.lua's "Session: <dir>").
--
-- `%{...}` is evaluated at expansion time, so the project name updates on
-- DirChanged automatically; `%t` is the current file's short name.

local M = {}

function M.setup()
  vim.o.title = true
  vim.o.titleold = "" -- don't leave a stale terminal title on exit

  -- "project · file"
  vim.o.titlestring = "%{fnamemodify(getcwd(), ':t')} · %t%m"
end

return M
