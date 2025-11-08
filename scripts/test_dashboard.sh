#!/bin/bash
# Quick test script for dashboard framework

echo "════════════════════════════════════════════════════════════"
echo "  Dashboard Widget Framework - Test Suite"
echo "════════════════════════════════════════════════════════════"
echo ""

# Test 1: Load framework
echo "Test 1: Loading framework..."
nvim --headless -c "lua require('mlamkadm.core.dashboard-widgets')" -c "lua print('✓ Framework loaded')" -c "qa" 2>&1 | grep "✓"

# Test 2: Load config
echo "Test 2: Loading widget config..."
nvim --headless -c "lua require('mlamkadm.core.dashboard-config')" -c "lua print('✓ Config loaded')" -c "qa" 2>&1 | grep "✓"

# Test 3: Load dashboard plugin
echo "Test 3: Loading dashboard plugin..."
nvim --headless -c "lua require('mlamkadm.plugs.snacks-dashboard')" -c "lua print('✓ Plugin loaded')" -c "qa" 2>&1 | grep "✓"

# Test 4: Check widget registration
echo "Test 4: Checking widget registration..."
nvim --headless -c "lua local w = require('mlamkadm.core.dashboard-config'); local total = #w.registry.left + #w.registry.center + #w.registry.right; print('✓ Registered ' .. total .. ' widgets')" -c "qa" 2>&1 | grep "✓"

# Test 5: Check responsive layout
echo "Test 5: Testing responsive layout..."
nvim --headless -c "lua local w = require('mlamkadm.core.dashboard-widgets'); print('✓ Pane count at 160 cols: ' .. w.get_pane_count(160)); print('✓ Pane count at 100 cols: ' .. w.get_pane_count(100)); print('✓ Pane count at 60 cols: ' .. w.get_pane_count(60))" -c "qa" 2>&1 | grep "✓"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  All tests completed!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "To see the dashboard, run: nvim"
echo "For help in dashboard, press: ?"
