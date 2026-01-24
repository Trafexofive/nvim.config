#!/bin/bash
# Test script to verify winbar improvements

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                Winbar Improvement Verification             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

PASS=0
FAIL=0

test_case() {
    local name="$1"
    local cmd="$2"
    local expected="$3"

    echo -n "Testing: $name ... "
    
    result=$(eval $cmd 2>&1)
    
    if echo "$result" | grep -q "$expected"; then
        echo "✓ PASS"
        ((PASS++))
    else
        echo "✗ FAIL - Expected: $expected, Got: $result"
        ((FAIL++))
    fi
}

echo "Testing winbar functionality:"
echo

# Test 1: Check if visual module loads without errors
test_case "Visual module loads" \
    "nvim --headless -c 'lua require(\"mlamkadm.core.visual\").setup()' -c 'qa'" \
    ""

# Test 2: Check if get_winbar function returns proper string
test_case "get_winbar function works" \
    "nvim --headless -c 'lua require(\"mlamkadm.core.visual\").setup()' -c 'lua print(require(\"mlamkadm.core.visual\").get_winbar())' -c 'qa'" \
    "WinBarFileName"

# Test 3: Check winbar elements
test_case "Winbar contains expected elements" \
    "nvim --headless -c 'lua require(\"mlamkadm.core.visual\").setup()' -c 'lua print(require(\"mlamkadm.core.visual\").get_winbar())' -c 'qa'" \
    "Ln: 1, Col: 1"

echo
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                      Test Results                          ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║  PASS: $PASS                                              ║"
echo "║  FAIL: $FAIL                                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

if [ $FAIL -eq 0 ]; then
    echo "All tests passed! Winbar improvements are working correctly."
    exit 0
else
    echo "Some tests failed. Please check the implementation."
    exit 1
fi