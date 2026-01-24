#!/bin/bash
# Test script to verify winbar duplication fix

echo "╔════════════════════════════════════════════════════════════╗"
echo "║              Winbar Duplication Fix Verification           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

echo "Testing winbar duplication fix..."
echo

# Create a test file
cat > /tmp/test_file.lua << 'EOF'
print("This is a test file")
print("Line 2")
print("Line 3")
print("Line 4")
print("Line 5")
EOF

# Run Neovim with split windows and capture the winbar for each window
nvim --headless -c 'edit /tmp/test_file.lua' -c 'split' -c 'wincmd j' -c 'split' -c 'wincmd j' -c 'lua print("Window 1 - Winbar: " .. vim.api.nvim_win_get_option(0, "winbar"))' -c 'wincmd w' -c 'lua print("Window 2 - Winbar: " .. vim.api.nvim_win_get_option(0, "winbar"))' -c 'wincmd w' -c 'lua print("Window 3 - Winbar: " .. vim.api.nvim_win_get_option(0, "winbar"))' -c 'qa' 2>&1 | grep -E "(Window [0-9] - Winbar:|Gruvbox theme)" > /tmp/winbar_test_output

echo "Winbar test results:"
cat /tmp/winbar_test_output

# Count unique winbars
unique_winbars=$(grep "Winbar: " /tmp/winbar_test_output | cut -d':' -f2- | sort -u | wc -l)

echo
echo "Number of unique winbars: $unique_winbars"
echo "Expected: 1 (all windows should have the same winbar)"

if [ "$unique_winbars" -eq 1 ]; then
    echo "✓ SUCCESS: Winbar duplication issue is FIXED!"
    result=0
else
    echo "✗ ISSUE: Winbar duplication still exists"
    result=1
fi

# Clean up
rm -f /tmp/test_file.lua /tmp/winbar_test_output

exit $result