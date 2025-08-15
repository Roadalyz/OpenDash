#!/bin/bash

# Tiger Style: Always motivate, always say why
# This script sets up the development environment for the dashcam project
# It installs uv (fast Python package manager), Conan, and prepares the build environment
# Using uv provides significant speed improvements over pip and better dependency resolution

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Setting up dashcam development environment..."
echo "Project root: $PROJECT_ROOT"

# Detect platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="windows"
else
    echo "Unsupported platform: $OSTYPE"
    exit 1
fi

echo "Detected platform: $PLATFORM"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
check_dependencies() {
    echo "Checking dependencies..."
    
    # Check for C++ compiler
    if ! command_exists g++ && ! command_exists clang++; then
        echo "Error: No C++ compiler found. Please install g++ or clang++"
        exit 1
    fi
    
    # Check for CMake
    if ! command_exists cmake; then
        echo "Error: CMake not found. Please install CMake 3.20 or later"
        exit 1
    fi
    
    # Check CMake version
    CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
    CMAKE_MAJOR=$(echo $CMAKE_VERSION | cut -d'.' -f1)
    CMAKE_MINOR=$(echo $CMAKE_VERSION | cut -d'.' -f2)
    
    if [ "$CMAKE_MAJOR" -lt 3 ] || ([ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 20 ]); then
        echo "Error: CMake 3.20 or later required, found $CMAKE_VERSION"
        exit 1
    fi
    
    # Check for Python
    if ! command_exists python3; then
        echo "Error: Python 3 not found. Please install Python 3.8.1 or later"
        exit 1
    fi
    
    echo "All required dependencies found"
}

# Install uv package manager
install_uv() {
    if ! command_exists uv; then
        echo "Installing uv (fast Python package manager)..."
        
        # Install uv using the official installer
        if command_exists curl; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
        elif command_exists wget; then
            wget -qO- https://astral.sh/uv/install.sh | sh
        else
            echo "Error: Neither curl nor wget found. Please install one of them."
            exit 1
        fi
        
        # Source the environment to get uv in PATH
        export PATH="$HOME/.cargo/bin:$PATH"
        
        # Verify installation
        if ! command_exists uv; then
            echo "Warning: uv installation may require shell restart"
            echo "Falling back to pip for this session..."
            return 1
        fi
        
        echo "✅ uv installed successfully"
        return 0
    else
        echo "✅ uv already installed"
        return 0
    fi
}

# Install Conan package manager
install_conan() {
    local use_uv=${1:-true}
    
    if ! command_exists conan; then
        echo "Installing Conan package manager..."
        
        if [ "$use_uv" = true ]; then
            uv tool install conan
            
            # Add uv tools to PATH
            export PATH="$HOME/.local/bin:$PATH"
        else
            echo "Using pip3 fallback..."
            pip3 install --user conan
            
            # Add to PATH if not already there
            export PATH="$HOME/.local/bin:$PATH"
        fi
        
        # Verify installation
        if ! command_exists conan; then
            echo "Please add ~/.local/bin to your PATH and re-run this script"
            exit 1
        fi
        
        echo "✅ Conan installed successfully"
    else
        echo "✅ Conan already installed"
    fi
    
    # Create Conan profile if it doesn't exist
    if [ ! -f ~/.conan2/profiles/default ]; then
        echo "Creating Conan profile..."
        conan profile detect --force
    fi
}

# Install Python testing dependencies
install_python_deps() {
    local use_uv=${1:-true}
    
    echo "Installing Python testing dependencies..."
    
    cd "$PROJECT_ROOT"
    
    if [ "$use_uv" = true ]; then
        # Use uv to create virtual environment and install dependencies
        echo "Using uv to create virtual environment and install dependencies..."
        
        # Create virtual environment
        uv venv --python 3.12
        
        # Install project dependencies (including optional test dependencies)
        uv sync --extra test --extra docs --extra dev
        
        # Also install system test requirements if they exist
        if [ -f "tests/system/requirements.txt" ]; then
            uv pip install -r tests/system/requirements.txt
        fi
        
        echo "✅ Python dependencies installed successfully"
    else
        echo "Using pip3 fallback..."
        if [ -f "tests/system/requirements.txt" ]; then
            pip3 install --user -r tests/system/requirements.txt
        fi
        echo "✅ Python dependencies installed successfully"
    fi
}

# Create build directory
setup_build_dir() {
    BUILD_DIR="$PROJECT_ROOT/build"
    if [ ! -d "$BUILD_DIR" ]; then
        echo "Creating build directory..."
        mkdir -p "$BUILD_DIR"
    fi
}

# Platform-specific setup
platform_setup() {
    case $PLATFORM in
        linux)
            echo "Setting up for Linux..."
            # Install additional Linux-specific dependencies if needed
            ;;
        macos)
            echo "Setting up for macOS..."
            # Install additional macOS-specific dependencies if needed
            ;;
        windows)
            echo "Setting up for Windows..."
            # Install additional Windows-specific dependencies if needed
            ;;
    esac
}

# Main setup sequence
main() {
    check_dependencies
    
    # Install uv for faster Python package management
    if install_uv; then
        uv_available=true
    else
        uv_available=false
    fi
    
    # Install tools using uv when available, fallback to pip
    install_conan "$uv_available"
    install_python_deps "$uv_available"
    setup_build_dir
    platform_setup
    
    echo ""
    echo "✅ Development environment setup complete!"
    echo ""
    if [ "$uv_available" = true ]; then
        echo "🚀 Using uv for fast Python package management"
        echo ""
        echo "🐍 Python virtual environment created in .venv/"
        echo "   To activate: source .venv/bin/activate"
        echo "   Or use: uv run <command> to run commands in the environment"
    else
        echo "📦 Using pip for Python package management"
    fi
    echo ""
    echo "Next steps:"
    echo "1. Run './scripts/build.sh debug' to build debug version"
    echo "2. Run './scripts/build.sh release' to build release version"
    echo "3. Run './scripts/test.sh' to run all tests"
    echo ""
    echo "For Python development:"
    echo "1. Activate virtual environment: source .venv/bin/activate"
    echo "2. Or use uv commands: uv run python <script>"
    echo ""
    echo "For Docker development:"
    echo "1. Run './scripts/docker_build.sh' to build Docker image"
    echo "2. Run './scripts/docker_run.sh' to run in container"
}

main "$@"
