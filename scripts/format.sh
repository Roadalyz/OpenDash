#!/bin/bash

# Simple code formatting script for OpenDash
# Usage: ./scripts/format.sh [--check]

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if clang-format is available
if ! command -v clang-format >/dev/null 2>&1; then
    print_error "clang-format not found. Please install it:"
    echo "  macOS: brew install clang-format"
    echo "  Ubuntu: sudo apt install clang-format"
    exit 1
fi

# Parse arguments
CHECK_ONLY=false
if [[ "$1" == "--check" ]]; then
    CHECK_ONLY=true
    print_info "Checking code formatting (dry run)..."
else
    print_info "Formatting code..."
fi

# Find all C++ source files
FILES=$(find src include tests -name "*.cpp" -o -name "*.h" -o -name "*.hpp" 2>/dev/null || true)

if [[ -z "$FILES" ]]; then
    print_error "No C++ files found to format"
    exit 1
fi

# Count files
FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
print_info "Found $FILE_COUNT C++ files"

if [[ "$CHECK_ONLY" == true ]]; then
    # Check formatting without modifying files
    ISSUES_FOUND=false
    while IFS= read -r file; do
        if ! clang-format --dry-run --Werror "$file" >/dev/null 2>&1; then
            echo "  ❌ $file needs formatting"
            ISSUES_FOUND=true
        fi
    done <<< "$FILES"
    
    if [[ "$ISSUES_FOUND" == true ]]; then
        print_error "Some files need formatting. Run './scripts/format.sh' to fix them."
        exit 1
    else
        print_success "All files are properly formatted!"
    fi
else
    # Apply formatting
    echo "$FILES" | xargs clang-format -i
    print_success "All $FILE_COUNT files formatted successfully!"
    print_info "Tip: Use './scripts/format.sh --check' to verify formatting without changes"
fi
