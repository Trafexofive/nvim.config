#!/bin/bash
# Test script to verify enhanced session management

echo "Testing enhanced session management configuration..."
echo ""

# Check if the session module was created
if [ -f ~/.config/nvim/lua/mlamkadm/core/session.lua ]; then
    echo "✓ Enhanced session module created"
else
    echo "✗ Enhanced session module NOT FOUND"
    exit 1
fi

# Check if the changes were applied to options.lua
if grep -q "terminal" ~/.config/nvim/lua/mlamkadm/core/options.lua; then
    echo "✓ Session options updated with terminal support"
else
    echo "✗ Session options NOT updated properly"
    exit 1
fi

# Check if the changes were applied to the terminal.lua
if grep -q "SessionSavePre\|SessionLoadPost" ~/.config/nvim/lua/mlamkadm/core/terminal.lua; then
    echo "✓ Terminal module updated with session hooks"
else
    echo "✗ Terminal module NOT updated with session hooks"
    exit 1
fi

# Check if the changes were applied to core/init.lua
if grep -q "session" ~/.config/nvim/lua/mlamkadm/core/init.lua; then
    echo "✓ Core module updated with session integration"
else
    echo "✗ Core module NOT updated with session integration"
    exit 1
fi

echo ""
echo "All configuration changes applied successfully!"
echo ""
echo "To test the feature:"
echo "1. Start nvim and open a terminal with <c-t>"
echo "2. Save a session with <leader>sS"
echo "3. Open another project and create a new session"
echo "4. Switch between sessions with <leader>ss"
echo "5. The terminal should be preserved across sessions"