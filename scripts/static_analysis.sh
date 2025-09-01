#!/bin/bash

# Static Analysis Script for Dashcam Project
# ==========================================
# This script runs comprehensive static analysis on the codebase using multiple tools.
# It follows Tiger Style principles for early bug detection and code quality assurance.

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"

# Configuration
RUN_CLANG_TIDY=true
RUN_CPPCHECK=true
RUN_CLANG_FORMAT_CHECK=true
FIX_ISSUES=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clang-tidy-only)
            RUN_CPPCHECK=false
            RUN_CLANG_FORMAT_CHECK=false
            shift
            ;;
        --cppcheck-only)
            RUN_CLANG_TIDY=false
            RUN_CLANG_FORMAT_CHECK=false
            shift
            ;;
        --format-only)
            RUN_CLANG_TIDY=false
            RUN_CPPCHECK=false
            shift
            ;;
        --fix)
            FIX_ISSUES=true
            shift
            ;;
        --show-all)
            SHOW_ALL_OUTPUT=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --clang-tidy-only     Run only clang-tidy analysis"
            echo "  --cppcheck-only       Run only cppcheck analysis"
            echo "  --format-only         Run only format checking"
            echo "  --fix                 Automatically fix issues where possible"
            echo "  --show-all            Show all output including filtered system header errors"
            echo "  --verbose, -v         Verbose output"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Run all static analysis tools"
            echo "  $0 --clang-tidy-only  # Run only clang-tidy"
            echo "  $0 --fix              # Run analysis and fix issues"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

print_status "Starting static analysis for dashcam project..."
print_status "Project root: $PROJECT_ROOT"

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    print_error "Build directory not found. Please run ./scripts/build.sh first"
    exit 1
fi

# Check for compile_commands.json
if [ ! -f "$BUILD_DIR/compile_commands.json" ]; then
    print_warning "compile_commands.json not found. Building with CMAKE_EXPORT_COMPILE_COMMANDS=ON"
    cd "$BUILD_DIR"
    cmake "$PROJECT_ROOT" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
fi

# Find source files
SOURCE_DIRS=("$PROJECT_ROOT/src" "$PROJECT_ROOT/include" "$PROJECT_ROOT/tests")
SOURCE_FILES=()

for dir in "${SOURCE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        while IFS= read -r -d '' file; do
            SOURCE_FILES+=("$file")
        done < <(find "$dir" \( -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) -print0)
    fi
done

if [ ${#SOURCE_FILES[@]} -eq 0 ]; then
    print_error "No source files found to analyze"
    exit 1
fi

print_status "Found ${#SOURCE_FILES[@]} source files to analyze"

# Run clang-tidy
if [ "$RUN_CLANG_TIDY" = true ]; then
    print_status "Running clang-tidy analysis..."
    
    if ! command_exists clang-tidy; then
        print_warning "clang-tidy not found. Skipping clang-tidy analysis."
        print_warning "Install with: brew install llvm (macOS) or apt install clang-tidy (Linux)"
    else
        CLANG_TIDY_ARGS=(
            "--config-file=$PROJECT_ROOT/.clang-tidy"
            "-p=$BUILD_DIR"
            "--header-filter=$PROJECT_ROOT/(src|include|tests)/.*"
        )
        
        if [ "$FIX_ISSUES" = true ]; then
            CLANG_TIDY_ARGS+=("--fix")
            print_status "clang-tidy will attempt to fix issues automatically"
        fi
        
        if [ "$VERBOSE" = true ]; then
            CLANG_TIDY_ARGS+=("--explain-config")
        fi
        
        # Run clang-tidy on all source files
        CLANG_TIDY_EXIT_CODE=0
        SYSTEM_HEADER_ISSUES=0
        REAL_ISSUES=0
        CLEAN_FILES=0
        
        for file in "${SOURCE_FILES[@]}"; do
            if [[ "$file" == *.cpp ]] || [[ "$file" == *.h ]] || [[ "$file" == *.hpp ]]; then
                echo "Analyzing: $file"
                # Capture output and filter out system header errors
                if ! clang_tidy_output=$(clang-tidy "${CLANG_TIDY_ARGS[@]}" "$file" 2>&1); then
                    # Check if the error is ONLY system header issues
                    if [[ "$SHOW_ALL_OUTPUT" == true ]]; then
                        echo "  🔍 Raw output (--show-all enabled):"
                        echo "$clang_tidy_output"
                        CLANG_TIDY_EXIT_CODE=1
                        ((REAL_ISSUES++))
                    elif echo "$clang_tidy_output" | grep -q "file not found" && echo "$clang_tidy_output" | grep -qE "(Availability\.h|atomic|cstddef)" && ! echo "$clang_tidy_output" | grep -q "warning:"; then
                        # Only system header errors, no actual warnings
                        missing_header=$(echo "$clang_tidy_output" | grep -oE "'[^']*' file not found" | head -1)
                        echo "  🔧 Filtered: clang-tidy can't find system header $missing_header"
                        echo "     → Use --show-all to see full error details"
                        ((SYSTEM_HEADER_ISSUES++))
                    else
                        # Extract and show real warnings/errors (not system header issues)
                        real_warnings=$(echo "$clang_tidy_output" | grep -E "warning:|error:" | grep -v "file not found")
                        if [ -n "$real_warnings" ]; then
                            echo "  ⚠️  Found issues:"
                            echo "$real_warnings"
                            CLANG_TIDY_EXIT_CODE=1
                            ((REAL_ISSUES++))
                        else
                            # Only system header errors
                            missing_header=$(echo "$clang_tidy_output" | grep -oE "'[^']*' file not found" | head -1)
                            echo "  🔧 Filtered: clang-tidy can't find system header $missing_header"
                            echo "     → Use --show-all to see full error details"
                            ((SYSTEM_HEADER_ISSUES++))
                        fi
                    fi
                else
                    # Show non-error output if any (warnings, suggestions)
                    if [ -n "$clang_tidy_output" ]; then
                        echo "  ⚠️  Found warnings/suggestions:"
                        echo "$clang_tidy_output"
                        ((REAL_ISSUES++))
                    else
                        echo "  ✅ Clean"
                        ((CLEAN_FILES++))
                    fi
                fi
            fi
        done
        
        # Summary of clang-tidy results
        echo ""
        print_status "clang-tidy analysis summary:"
        echo "  ✅ Clean files: $CLEAN_FILES"
        if [ $REAL_ISSUES -gt 0 ]; then
            echo "  ⚠️  Files with issues: $REAL_ISSUES"
        fi
        if [ $SYSTEM_HEADER_ISSUES -gt 0 ]; then
            echo "  🔧 Files with filtered system header errors: $SYSTEM_HEADER_ISSUES"
            echo "     → Use 'scripts/static_analysis.sh --show-all --clang-tidy-only' to see raw errors"
        fi
        
        if [ $CLANG_TIDY_EXIT_CODE -eq 0 ]; then
            print_success "clang-tidy analysis completed successfully"
        else
            print_error "clang-tidy found issues"
        fi
    fi
fi

# Run cppcheck
if [ "$RUN_CPPCHECK" = true ]; then
    print_status "Running cppcheck analysis..."
    
    if ! command_exists cppcheck; then
        print_warning "cppcheck not found. Skipping cppcheck analysis."
        print_warning "Install with: brew install cppcheck (macOS) or apt install cppcheck (Linux)"
    else
        CPPCHECK_ARGS=(
            "--enable=warning,style,performance,portability"
            "--inconclusive"
            "--force"
            "--inline-suppr"
            "--std=c++17"
            "--language=c++"
            "--error-exitcode=1"
            "--suppress=missingIncludeSystem"
            "--suppress=unusedFunction"
            "--suppress=unmatchedSuppression"
            "--suppress=syntaxError:*/tests/*"
            "--suppress=missingInclude:*/grpc/*"
            "--suppress=functionStatic"
            "--suppress=normalCheckLevelMaxBranches"
            "-DTEST_F(x,y)=void"
            "-DTEST(x,y)=void"
            "-DEXPECT_EQ(x,y)="
            "-DEXPECT_NE(x,y)="
            "-DEXPECT_TRUE(x)="
            "-DEXPECT_FALSE(x)="
            "-DASSERT_EQ(x,y)="
            "-DASSERT_NE(x,y)="
            "-DASSERT_TRUE(x)="
            "-DASSERT_FALSE(x)="
            "-DASSERT_THAT(x,y)="
        )
        
        if [ "$VERBOSE" = true ]; then
            CPPCHECK_ARGS+=("--verbose")
        fi
        
        # Add include directories
        for dir in "${SOURCE_DIRS[@]}"; do
            if [ -d "$dir" ]; then
                CPPCHECK_ARGS+=("-I$dir")
            fi
        done
        
        # Run cppcheck
        CPPCHECK_EXIT_CODE=0
        if ! cppcheck "${CPPCHECK_ARGS[@]}" "${SOURCE_DIRS[@]}" 2>&1; then
            CPPCHECK_EXIT_CODE=1
        fi
        
        if [ $CPPCHECK_EXIT_CODE -eq 0 ]; then
            print_success "cppcheck analysis completed successfully"
        else
            print_error "cppcheck found issues"
        fi
    fi
fi

# Run clang-format check
if [ "$RUN_CLANG_FORMAT_CHECK" = true ]; then
    print_status "Checking code formatting..."
    
    if ! command_exists clang-format; then
        print_warning "clang-format not found. Skipping format check."
        print_warning "Install with: brew install clang-format (macOS) or apt install clang-format (Linux)"
    else
        FORMAT_EXIT_CODE=0
        
        for file in "${SOURCE_FILES[@]}"; do
            if [[ "$file" == *.cpp ]] || [[ "$file" == *.h ]] || [[ "$file" == *.hpp ]]; then
                if [ "$FIX_ISSUES" = true ]; then
                    # Fix formatting in place
                    clang-format -i "$file"
                    echo "Formatted: $file"
                else
                    # Check if file needs formatting
                    if ! clang-format "$file" | diff -q "$file" - >/dev/null; then
                        print_warning "File needs formatting: $file"
                        FORMAT_EXIT_CODE=1
                    fi
                fi
            fi
        done
        
        if [ "$FIX_ISSUES" = true ]; then
            print_success "Code formatting applied"
        elif [ $FORMAT_EXIT_CODE -eq 0 ]; then
            print_success "All files are properly formatted"
        else
            print_error "Some files need formatting. Run with --fix to automatically format them."
        fi
    fi
fi

print_status "Static analysis complete!"

# Summary
echo ""
echo "=== ANALYSIS SUMMARY ==="
if [ "$RUN_CLANG_TIDY" = true ]; then
    echo "✓ clang-tidy: $(command_exists clang-tidy && echo "run" || echo "skipped (not installed)")"
fi
if [ "$RUN_CPPCHECK" = true ]; then
    echo "✓ cppcheck: $(command_exists cppcheck && echo "run" || echo "skipped (not installed)")"
fi
if [ "$RUN_CLANG_FORMAT_CHECK" = true ]; then
    echo "✓ format check: $(command_exists clang-format && echo "run" || echo "skipped (not installed)")"
fi

echo ""
print_success "Consider running this analysis regularly to maintain code quality!"
print_status "For CI/CD integration, add this script to your build pipeline."
