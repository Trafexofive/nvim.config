#!/usr/bin/env nvim -l
-- Test widget system
-- Usage: nvim -l scripts/test_widgets.lua

-- Load widget system
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

local widgets = require("mlamkadm.core.widgets")

print("Widget System Test")
print("==================")
print("")

-- Test widget creation
widgets.create_default_pages()

print("Created pages:")
for name, page in pairs(widgets.page.pages) do
  print("  - " .. name .. " with " .. #page.widgets .. " widgets")
end

print("")
print("Widget types available:")
for type_name, _ in pairs(widgets.types) do
  print("  - " .. type_name)
end

print("")
print("✓ Widget system initialized successfully")
