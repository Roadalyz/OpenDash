#!/bin/bash

# Tiger Style: Always motivate, always say why
# This script runs all tests (unit and system) with proper reporting
# It provides clear feedback on test results and coverage

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"

echo "Running dashcam test suite..."

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found. Please run './scripts/build.sh' first"
    exit 1
fi

# Check if executables exist
UNIT_TEST_EXEC="$BUILD_DIR/tests/unit_tests"
MAIN_EXEC="$BUILD_DIR/src/dashcam_main"

if [ ! -f "$UNIT_TEST_EXEC" ]; then
    echo "Error: Unit test executable not found. Please build the project first"
    exit 1
fi

if [ ! -f "$MAIN_EXEC" ]; then
    echo "Error: Main executable not found. Please build the project first"
    exit 1
fi

cd "$BUILD_DIR"

echo "===================="
echo "Running Unit Tests"
echo "===================="

# Run unit tests with GoogleTest
if "$UNIT_TEST_EXEC" --gtest_output=xml:unit_test_results.xml; then
    echo "✅ Unit tests PASSED"
    UNIT_TESTS_PASSED=1
else
    echo "❌ Unit tests FAILED"
    UNIT_TESTS_PASSED=0
fi

echo ""
echo "===================="
echo "Running System Tests"
echo "===================="

# Run system tests with pytest using uv run to ensure proper environment
cd "$PROJECT_ROOT"
if uv run pytest tests/system/ -v --tb=short --junit-xml=build/system_test_results.xml --no-cov; then
    echo "✅ System tests PASSED"
    SYSTEM_TESTS_PASSED=1
else
    echo "❌ System tests FAILED"
    SYSTEM_TESTS_PASSED=0
fi

echo ""
echo "===================="
echo "Test Results Summary"
echo "===================="

if [ $UNIT_TESTS_PASSED -eq 1 ] && [ $SYSTEM_TESTS_PASSED -eq 1 ]; then
    echo "🎉 ALL TESTS PASSED!"
    echo ""
    echo "Test reports generated:"
    echo "  Unit tests: build/unit_test_results.xml"
    echo "  System tests: build/system_test_results.xml"
    cd "$PROJECT_ROOT"
    exit 0
else
    echo "💥 SOME TESTS FAILED!"
    echo ""
    if [ $UNIT_TESTS_PASSED -eq 0 ]; then
        echo "❌ Unit tests failed"
    fi
    if [ $SYSTEM_TESTS_PASSED -eq 0 ]; then
        echo "❌ System tests failed"
    fi
    echo ""
    echo "Check the test output above for details"
    exit 1
fi

# Ensure we always return to project root
cd "$PROJECT_ROOT"
