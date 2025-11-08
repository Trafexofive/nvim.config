#!/bin/bash
# Quick test script for current nvim setup

echo "Testing nvim configuration..."
nvim --headless +"lua require('mlamkadm.core.widgets').setup()" +"lua print('✓ Widget system loaded')" +qa 2>&1 | grep "✓"

echo ""
echo "Widget pages available:"
nvim --headless +"lua require('mlamkadm.core.widgets').setup(); for k,v in pairs(require('mlamkadm.core.widgets').page.pages) do print('  - ' .. k) end" +qa 2>&1 | grep " - "

echo ""
echo "Test complete!"
