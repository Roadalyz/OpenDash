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
        -h|--help)
            echo "Usage: $0 [debug|release] [-j|--jobs NUM_JOBS]"
            echo ""
            echo "Arguments:"
            echo "  debug|release    Build type (default: debug)"
            echo "  -j, --jobs       Number of parallel jobs (default: auto-detect)"
            echo "  -h, --help       Show this help message"
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
cmake "$PROJECT_ROOT" \
    -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build
echo "Building..."
cmake --build . --parallel "$JOBS"

# Generate compile_commands.json for language servers
if [ -f compile_commands.json ]; then
    cp compile_commands.json "$PROJECT_ROOT/"
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
