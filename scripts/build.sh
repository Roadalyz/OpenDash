#!/bin/bash

# Tiger Style: Always motivate, always say why
# This script builds the dashcam project with proper error checking
# and support for both debug and release configurations

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"

# Ensure uv is available in PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verify uv is available
if ! command_exists uv; then
    echo "Error: uv not found in PATH. Please run the setup script first:"
    echo "  ./scripts/setup.sh"
    exit 1
fi

# Default build type
BUILD_TYPE="Debug"
ENABLE_CLANG_TIDY=""
ENABLE_CPPCHECK=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        debug|Debug|DEBUG)
            BUILD_TYPE="Debug"
            shift
            ;;
        release|Release|RELEASE)
            BUILD_TYPE="Release"
            shift
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        --clang-tidy)
            ENABLE_CLANG_TIDY="-DENABLE_CLANG_TIDY=ON"
            shift
            ;;
        --cppcheck)
            ENABLE_CPPCHECK="-DENABLE_CPPCHECK=ON"
            shift
            ;;
        --static-analysis)
            ENABLE_CLANG_TIDY="-DENABLE_CLANG_TIDY=ON"
            ENABLE_CPPCHECK="-DENABLE_CPPCHECK=ON"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [debug|release] [OPTIONS]"
            echo ""
            echo "Arguments:"
            echo "  debug|release      Build type (default: debug)"
            echo ""
            echo "Options:"
            echo "  -j, --jobs NUM     Number of parallel jobs (default: auto-detect)"
            echo "  --clang-tidy       Enable clang-tidy static analysis"
            echo "  --cppcheck         Enable cppcheck static analysis"
            echo "  --static-analysis  Enable all static analysis tools"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 debug                    # Debug build"
            echo "  $0 release --clang-tidy     # Release build with clang-tidy"
            echo "  $0 debug --static-analysis  # Debug build with all static analysis"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Auto-detect number of jobs if not specified
if [ -z "$JOBS" ]; then
    if command -v nproc >/dev/null 2>&1; then
        JOBS=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        JOBS=$(sysctl -n hw.ncpu)
    else
        JOBS=4  # Default fallback
    fi
fi

echo "Building dashcam project..."
echo "Build type: $BUILD_TYPE"
echo "Using $JOBS parallel jobs"
echo "Project root: $PROJECT_ROOT"
echo "Build directory: $BUILD_DIR"

# Create build directory if it doesn't exist
if [ ! -d "$BUILD_DIR" ]; then
    echo "Creating build directory..."
    mkdir -p "$BUILD_DIR"
fi

cd "$BUILD_DIR"

# Install Conan dependencies
echo "Installing Conan dependencies..."
uv run conan install "$PROJECT_ROOT" --output-folder=. --build=missing \
    --profile="$PROJECT_ROOT/conanprofile" --settings=build_type="$BUILD_TYPE"

# Configure with CMake
echo "Configuring with CMake..."
CMAKE_ARGS=(
    "$PROJECT_ROOT"
    -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
)

# Add static analysis options if enabled
if [ -n "$ENABLE_CLANG_TIDY" ]; then
    CMAKE_ARGS+=("$ENABLE_CLANG_TIDY")
    echo "Static analysis: clang-tidy enabled"
fi

if [ -n "$ENABLE_CPPCHECK" ]; then
    CMAKE_ARGS+=("$ENABLE_CPPCHECK")
    echo "Static analysis: cppcheck enabled"
fi

cmake "${CMAKE_ARGS[@]}"

# Build
echo "Building..."
cmake --build . --parallel "$JOBS"

# Generate compile_commands.json for language servers
if [ -f compile_commands.json ]; then
    cp compile_commands.json "$PROJECT_ROOT/"
fi

# Update VS Code configuration with Conan include paths
echo "Updating VS Code configuration..."
if [ -f "$PROJECT_ROOT/scripts/update_vscode_config.py" ] && command_exists python3; then
    cd "$PROJECT_ROOT"
    python3 scripts/update_vscode_config.py
    cd "$BUILD_DIR"
else
    echo "Warning: Could not update VS Code configuration (missing script or python3)"
fi

echo ""
echo "Build completed successfully!"
echo "Build type: $BUILD_TYPE"
echo "Executable: $BUILD_DIR/src/dashcam_main"
echo "Unit tests: $BUILD_DIR/tests/unit_tests"
echo ""

# Provide next steps
if [ "$BUILD_TYPE" = "Debug" ]; then
    echo "Debug build includes:"
    echo "- Debug symbols for debugging"
    echo "- AddressSanitizer and UndefinedBehaviorSanitizer"
    echo "- Assertions enabled"
    echo ""
    echo "To run with debugging:"
    echo "  gdb $BUILD_DIR/src/dashcam_main"
    echo ""
else
    echo "Release build includes:"
    echo "- Optimizations enabled (-O3)"
    echo "- Assertions disabled"
    echo "- Suitable for production use"
    echo ""
fi

echo "To run tests:"
echo "  ./scripts/test.sh"
echo ""
echo "To run the application:"
echo "  $BUILD_DIR/src/dashcam_main"

# Return to project root for better developer experience
cd "$PROJECT_ROOT"
