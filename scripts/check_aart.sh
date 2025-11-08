#!/bin/bash
# Quick verification script for aart integration

echo "════════════════════════════════════════════════════════════"
echo "  AART INTEGRATION VERIFICATION"
echo "════════════════════════════════════════════════════════════"
echo

# Check 1: Plugin file exists
echo "✓ Checking plugin file..."
if [ -f ~/.config/nvim/lua/mlamkadm/plugs/aart.lua ]; then
    echo "  ✓ aart.lua exists"
else
    echo "  ✗ aart.lua NOT FOUND"
fi

# Check 2: Startup modified
echo
echo "✓ Checking startup.lua..."
if grep -q "require('aart')" ~/.config/nvim/lua/mlamkadm/plugs/startup.lua; then
    echo "  ✓ startup.lua has aart integration"
else
    echo "  ✗ startup.lua NOT modified"
fi

# Check 3: Animation file
echo
echo "✓ Checking animation file..."
if [ -L ~/.config/nvim/logo.aart ]; then
    echo "  ✓ logo.aart symlink exists"
    echo "  → Points to: $(readlink ~/.config/nvim/logo.aart)"
elif [ -f ~/.config/nvim/logo.aart ]; then
    echo "  ✓ logo.aart file exists (not symlink)"
else
    echo "  ✗ logo.aart NOT FOUND"
fi

# Check 4: Source animation exists
echo
echo "✓ Checking source animation..."
if [ -f ~/.config/aart/test.aa ]; then
    SIZE=$(du -h ~/.config/aart/test.aa | cut -f1)
    echo "  ✓ test.aa exists ($SIZE)"
else
    echo "  ✗ test.aa NOT FOUND"
fi

# Check 5: aart plugin source
echo
echo "✓ Checking aart plugin source..."
if [ -d ~/repos/aart/lua/aart ]; then
    echo "  ✓ Plugin source exists"
    FILES=$(ls ~/repos/aart/lua/aart/*.lua 2>/dev/null | wc -l)
    echo "  → Found $FILES Lua files"
else
    echo "  ✗ Plugin source NOT FOUND"
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  NEXT: Restart Neovim and check dashboard!"
echo "════════════════════════════════════════════════════════════"
echo
echo "Test commands in Neovim:"
echo "  :lua vim.print(require('aart'))"
echo "  :AartOpen ~/.config/nvim/logo.aart"
echo "  <leader>aa"
echo "  Press 'a' on dashboard"
echo
