#!/bin/bash

# FoodVendorApp End-to-End Test Runner
# Runs all unit tests and integration tests

set -e

echo "=========================================="
echo "  FoodVendorApp Test Suite"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track test results
UNIT_TESTS_PASSED=0
INTEGRATION_TESTS_PASSED=0

echo -e "${YELLOW}[1/4] Getting dependencies...${NC}"
flutter pub get

echo ""
echo -e "${YELLOW}[2/4] Running static analysis...${NC}"
if flutter analyze --no-fatal-infos; then
    echo -e "${GREEN}✓ Static analysis passed${NC}"
else
    echo -e "${RED}✗ Static analysis found issues${NC}"
fi

echo ""
echo -e "${YELLOW}[3/4] Running unit tests...${NC}"
echo "----------------------------------------"

# Run unit tests with coverage
if flutter test --coverage; then
    UNIT_TESTS_PASSED=1
    echo ""
    echo -e "${GREEN}✓ All unit tests passed${NC}"
else
    echo ""
    echo -e "${RED}✗ Some unit tests failed${NC}"
fi

echo ""
echo -e "${YELLOW}[4/4] Running integration tests...${NC}"
echo "----------------------------------------"

# Check if a device/emulator is available
if flutter devices | grep -q "No devices"; then
    echo -e "${YELLOW}⚠ No device/emulator available for integration tests${NC}"
    echo "  To run integration tests, start an emulator or connect a device:"
    echo "  flutter emulators --launch <emulator_id>"
    echo ""
    echo "  Then run: flutter test integration_test/app_test.dart"
    INTEGRATION_TESTS_PASSED=2  # Skipped
else
    if flutter test integration_test/app_test.dart; then
        INTEGRATION_TESTS_PASSED=1
        echo ""
        echo -e "${GREEN}✓ All integration tests passed${NC}"
    else
        echo ""
        echo -e "${RED}✗ Some integration tests failed${NC}"
    fi
fi

echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="

if [ $UNIT_TESTS_PASSED -eq 1 ]; then
    echo -e "  Unit Tests:        ${GREEN}PASSED${NC}"
else
    echo -e "  Unit Tests:        ${RED}FAILED${NC}"
fi

if [ $INTEGRATION_TESTS_PASSED -eq 1 ]; then
    echo -e "  Integration Tests: ${GREEN}PASSED${NC}"
elif [ $INTEGRATION_TESTS_PASSED -eq 2 ]; then
    echo -e "  Integration Tests: ${YELLOW}SKIPPED (no device)${NC}"
else
    echo -e "  Integration Tests: ${RED}FAILED${NC}"
fi

echo ""

# Generate coverage report if lcov is available
if command -v genhtml &> /dev/null && [ -f coverage/lcov.info ]; then
    echo "Generating HTML coverage report..."
    genhtml coverage/lcov.info -o coverage/html --quiet
    echo -e "Coverage report: ${GREEN}coverage/html/index.html${NC}"
fi

echo ""

# Exit with appropriate code
if [ $UNIT_TESTS_PASSED -eq 1 ] && [ $INTEGRATION_TESTS_PASSED -ne 0 ]; then
    echo -e "${GREEN}All tests completed successfully!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Check output above for details.${NC}"
    exit 1
fi
