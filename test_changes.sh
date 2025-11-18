#!/bin/bash
# Test script to verify the changes made to the poptui and temp session

echo "Testing poptui and temp session changes..."
echo "=========================================="

# Check if the terminal.lua file was modified correctly
echo "Checking poptui exit status fix in terminal.lua..."
if grep -A 10 "on_exit = function" /home/mlamkadm/.config/nvim/lua/mlamkadm/core/terminal.lua | grep -q "vim.schedule"; then
    echo "✓ on_exit callback updated with window closing logic"
else
    echo "✗ on_exit callback NOT updated properly"
fi

# Check if the Ctrl+D keymap was added
if grep -q "C-d" /home/mlamkadm/.config/nvim/lua/mlamkadm/core/terminal.lua; then
    echo "✓ Ctrl+D keymap added to terminal"
else
    echo "✗ Ctrl+D keymap NOT found"
fi

# Check if the session manager has temp session functions
echo "Checking temp session functions in session_manager.lua..."
if grep -q "create_temp_session" /home/mlamkadm/.config/nvim/lua/mlamkadm/core/session_manager.lua; then
    echo "✓ create_temp_session function added"
else
    echo "✗ create_temp_session function NOT found"
fi

if grep -q "cleanup_temp_session" /home/mlamkadm/.config/nvim/lua/mlamkadm/core/session_manager.lua; then
    echo "✓ cleanup_temp_session function added"
else
    echo "✗ cleanup_temp_session function NOT found"
fi

# Check if the dashboard was updated with temp session
echo "Checking dashboard integration..."
if grep -q "Temp Workspace" /home/mlamkadm/.config/nvim/lua/mlamkadm/plugs/snacks-dashboard.lua; then
    echo "✓ Temp Workspace option added to dashboard"
else
    echo "✗ Temp Workspace option NOT found in dashboard"
fi

if grep -q "create_temp_session" /home/mlamkadm/.config/nvim/lua/mlamkadm/plugs/snacks-dashboard.lua; then
    echo "✓ create_temp_session function called in dashboard"
else
    echo "✗ create_temp_session function NOT called in dashboard"
fi

echo "=========================================="
echo "Test completed. Check the results above."