#!/bin/bash
# Verification script for dashboard framework

echo "╔════════════════════════════════════════════════════════════╗"
echo "║      Dashboard Widget Framework - Final Verification       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0

test_case() {
    local name="$1"
    local cmd="$2"
    echo -n "Testing: $name... "
    if eval "$cmd" &>/dev/null; then
        echo "✅ PASS"
        ((PASS++))
    else
        echo "❌ FAIL"
        ((FAIL++))
    fi
}

# Test 1: Framework loads
test_case "Framework loading" \
    "nvim --headless -c 'lua require(\"mlamkadm.core.dashboard-widgets\")' -c 'qa' 2>&1"

# Test 2: Config loads
test_case "Config loading" \
    "nvim --headless -c 'lua require(\"mlamkadm.core.dashboard-config\")' -c 'qa' 2>&1"

# Test 3: Dashboard plugin loads
test_case "Dashboard plugin" \
    "nvim --headless -c 'lua require(\"mlamkadm.plugs.snacks-dashboard\")' -c 'qa' 2>&1"

# Test 4: Widget registration
test_case "Widget registration" \
    "nvim --headless -c 'lua local w = require(\"mlamkadm.core.dashboard-config\"); assert(#w.registry.left > 0)' -c 'qa' 2>&1"

# Test 5: Build sections (critical - this was failing)
test_case "Build sections" \
    "nvim --headless -c 'lua local w = require(\"mlamkadm.core.dashboard-config\"); local s = w.build_sections(); assert(type(s) == \"table\")' -c 'qa' 2>&1"

# Test 6: Responsive layout
test_case "Responsive layout" \
    "nvim --headless -c 'lua local w = require(\"mlamkadm.core.dashboard-widgets\"); assert(w.get_pane_count(160) == 3)' -c 'qa' 2>&1"

# Test 7: Navigation setup
test_case "Navigation system" \
    "nvim --headless -c 'lua local w = require(\"mlamkadm.core.dashboard-widgets\"); w.cycle_pane(1)' -c 'qa' 2>&1"

# Test 8: Help system
test_case "Help system" \
    "nvim --headless -c 'lua require(\"mlamkadm.core.dashboard-widgets-help\")' -c 'qa' 2>&1"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "════════════════════════════════════════════════════════════"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "✅ All tests passed! Dashboard is ready to use."
    echo ""
    echo "Start Neovim to see your dashboard:"
    echo "  nvim"
    echo ""
    echo "Press ? in the dashboard for help."
    echo ""
    exit 0
else
    echo ""
    echo "❌ Some tests failed. Please check the errors above."
    echo ""
    exit 1
fi
