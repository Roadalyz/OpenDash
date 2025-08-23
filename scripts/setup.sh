#!/bin/bash

# Tiger Style: Always motivate, always say why
# This script sets up the development environment for the dashcam project
# It installs uv (fast Python package manager), Conan, and prepares the build environment
# Using uv provides significant speed improvements over pip and better dependency resolution

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly LOG_FILE="$PROJECT_ROOT/setup.log"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default options
MINIMAL_INSTALL=false
SKIP_TOOLS=false
VERBOSE=false

# Initialize log file
echo "Setup started at $(date)" > "$LOG_FILE"

echo "Setting up dashcam development environment..."
echo "Project root: $PROJECT_ROOT"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log_error "Setup failed: $1"
    log_error "Check $LOG_FILE for details"
    exit 1
}

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v pacman >/dev/null 2>&1; then
            echo "arch"
        elif command -v apt >/dev/null 2>&1; then
            echo "debian"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        log_error "Unsupported platform: $OSTYPE"
        exit 1
    fi
}

PLATFORM=$(detect_platform)
log_info "Detected platform: $PLATFORM"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check for C++ compiler
    if ! command_exists g++ && ! command_exists clang++; then
        error_exit "No C++ compiler found. Please install g++ or clang++"
    fi
    
    # Check for CMake
    if ! command_exists cmake; then
        error_exit "CMake not found. Please install CMake 3.20 or later"
    fi
    
    # Check CMake version
    CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
    CMAKE_MAJOR=$(echo $CMAKE_VERSION | cut -d'.' -f1)
    CMAKE_MINOR=$(echo $CMAKE_VERSION | cut -d'.' -f2)
    
    if [ "$CMAKE_MAJOR" -lt 3 ] || ([ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 20 ]); then
        error_exit "CMake 3.20 or later required, found $CMAKE_VERSION"
    fi
    
    # Check for Python
    if ! command_exists python3; then
        error_exit "Python 3 not found. Please install Python 3.8.1 or later"
    fi
    
    log_success "All required dependencies found"
}

# Install uv package manager
install_uv() {
    if ! command_exists uv; then
        log_info "Installing uv (fast Python package manager)..."
        
        # Install uv using the official installer
        if command_exists curl; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
        elif command_exists wget; then
            wget -qO- https://astral.sh/uv/install.sh | sh
        else
            error_exit "Neither curl nor wget found. Please install one of them."
        fi
        
        # Source the environment to get uv in PATH
        export PATH="$HOME/.cargo/bin:$PATH"
        
        # Verify installation
        if ! command_exists uv; then
            log_warning "uv installation may require shell restart"
            log_warning "Falling back to pip for this session..."
            return 1
        fi
        
        log_success "uv installed successfully"
        return 0
    else
        log_success "uv already installed"
        return 0
    fi
}

# Install Conan package manager
install_conan() {
    local use_uv=${1:-true}
    
    if ! command_exists conan; then
        log_info "Installing Conan package manager..."
        
        if [ "$use_uv" = true ]; then
            # Use uv to install conan in the virtual environment
            log_info "Installing Conan using uv in virtual environment..."
            cd "$PROJECT_ROOT"
            uv add conan
            
            # Conan should now be available via 'uv run conan'
            log_success "Conan installed in virtual environment"
            
            # Create a wrapper function for easier access
            log_info "Note: Use 'uv run conan' to run Conan commands"
        else
            log_info "Using pip3 fallback..."
            pip3 install --user conan
            
            # Add Python user bin directories to PATH (macOS specific paths)
            if [[ "$PLATFORM" == "macos" ]]; then
                # Check common Python installation paths on macOS
                for python_path in /Library/Frameworks/Python.framework/Versions/*/bin; do
                    if [[ -d "$python_path" ]]; then
                        export PATH="$python_path:$PATH"
                    fi
                done
                # Also add the user Library path
                export PATH="$HOME/Library/Python/3.12/bin:$PATH"
            fi
            
            # Add standard user bin to PATH
            export PATH="$HOME/.local/bin:$PATH"
            
            # Verify installation
            if ! command_exists conan; then
                log_error "Conan installation failed. Conan may be installed but not in PATH."
                log_info "Try adding these directories to your PATH:"
                log_info "  ~/.local/bin"
                if [[ "$PLATFORM" == "macos" ]]; then
                    log_info "  ~/Library/Python/3.12/bin"
                fi
                log_info "Then re-run this script"
                return 1
            fi
        fi
    else
        log_success "Conan already installed"
    fi
    
    # Create Conan profile if it doesn't exist
    if [ ! -f ~/.conan2/profiles/default ]; then
        log_info "Creating Conan profile..."
        if [ "$use_uv" = true ]; then
            # Use uv run to execute conan in the virtual environment
            cd "$PROJECT_ROOT"
            uv run conan profile detect --force
        else
            conan profile detect --force
        fi
    fi
}

# Install Python testing dependencies
install_python_deps() {
    local use_uv=${1:-true}
    
    log_info "Installing Python testing dependencies..."
    
    cd "$PROJECT_ROOT"
    
    if [ "$use_uv" = true ]; then
        # Use uv to create virtual environment and install dependencies
        log_info "Using uv to create virtual environment and install dependencies..."
        
        # Create virtual environment
        uv venv --python 3.12
        
        # Install project dependencies (including optional test dependencies)
        uv sync --extra test --extra docs --extra dev
        
        # Also install system test requirements if they exist
        if [ -f "tests/system/requirements.txt" ]; then
            uv pip install -r tests/system/requirements.txt
        fi
        
        log_success "Python dependencies installed successfully"
    else
        log_info "Using pip3 fallback..."
        if [ -f "tests/system/requirements.txt" ]; then
            pip3 install --user -r tests/system/requirements.txt
        fi
        log_success "Python dependencies installed successfully"
    fi
}

# Package managers for different platforms
install_packages_arch() {
    local packages=("$@")
    log_info "Installing packages with pacman: ${packages[*]}"
    sudo pacman -S --noconfirm "${packages[@]}" || error_exit "Failed to install packages"
}

install_packages_debian() {
    local packages=("$@")
    log_info "Installing packages with apt: ${packages[*]}"
    sudo apt update
    sudo apt install -y "${packages[@]}" || error_exit "Failed to install packages"
}

install_packages_macos() {
    local packages=("$@")
    log_info "Installing packages with brew: ${packages[*]}"
    
    # Install Homebrew if not present
    if ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew install "${packages[@]}" || error_exit "Failed to install packages"
}

# VS Code setup
setup_vscode() {
    if [[ "$SKIP_TOOLS" == true ]]; then
        log_info "Skipping VS Code setup (--skip-tools specified)"
        return
    fi
    
    log_info "Setting up VS Code..."
    
    # Install VS Code if not present
    if ! command_exists code; then
        case "$PLATFORM" in
            arch)
                if command_exists yay; then
                    yay -S --noconfirm visual-studio-code-bin
                elif command_exists snap; then
                    sudo snap install code --classic
                else
                    log_warning "Please install VS Code manually from the AUR or using snap"
                fi
                ;;
            debian)
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
                sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
                sudo apt update
                sudo apt install -y code
                ;;
            macos)
                brew install --cask visual-studio-code
                ;;
        esac
    fi
    
    # Install extensions
    if [[ "$MINIMAL_INSTALL" == false ]] && command_exists code; then
        log_info "Installing VS Code extensions..."
        local extensions=(
            "ms-vscode.cpptools"
            "ms-vscode.cmake-tools"
            "ms-python.python"
            "ms-vscode.cpptools-extension-pack"
        )
        
        for ext in "${extensions[@]}"; do
            log_info "Installing extension: $ext"
            code --install-extension "$ext" || log_warning "Failed to install extension: $ext"
        done
    fi
    
    log_success "VS Code setup complete"
}

# Docker setup
setup_docker() {
    if [[ "$SKIP_TOOLS" == true ]]; then
        log_info "Skipping Docker setup (--skip-tools specified)"
        return
    fi
    
    log_info "Setting up Docker..."
    
    if ! command_exists docker; then
        case "$PLATFORM" in
            arch)
                install_packages_arch docker docker-compose
                ;;
            debian)
                install_packages_debian docker.io docker-compose
                ;;
            macos)
                brew install --cask docker
                ;;
        esac
    fi
    
    # Add user to docker group (Linux only)
    if [[ "$PLATFORM" != "macos" ]] && ! groups $USER | grep -q docker; then
        sudo usermod -aG docker "$USER" || log_warning "Failed to add user to docker group"
        log_warning "Please log out and log back in for Docker group changes to take effect"
    fi
    
    log_success "Docker setup complete"
}

# Create build directory
setup_build_dir() {
    BUILD_DIR="$PROJECT_ROOT/build"
    if [ ! -d "$BUILD_DIR" ]; then
        log_info "Creating build directory..."
        mkdir -p "$BUILD_DIR"
    fi
}

# Verification
verify_setup() {
    log_info "Verifying installation..."
    
    local tools=(
        "cmake:cmake --version"
        "python3:python3 --version"
    )
    
    if [[ "$SKIP_TOOLS" == false ]]; then
        if command_exists code; then
            tools+=("code:code --version")
        fi
        if command_exists docker; then
            tools+=("docker:docker --version")
        fi
    fi
    
    local failed=0
    for tool_check in "${tools[@]}"; do
        local tool="${tool_check%%:*}"
        local cmd="${tool_check#*:}"
        
        if command_exists "$tool"; then
            log_success "$tool is available"
        else
            log_error "$tool is not available"
            ((failed++))
        fi
    done
    
    # Special check for Conan (might be in virtual environment)
    if command_exists conan; then
        log_success "conan is available globally"
    elif [ -f "$PROJECT_ROOT/.venv/bin/python" ] || [ -f "$PROJECT_ROOT/.venv/Scripts/python.exe" ]; then
        # Check if conan is available in the virtual environment
        cd "$PROJECT_ROOT"
        if uv run conan --version >/dev/null 2>&1; then
            log_success "conan is available in virtual environment (use 'uv run conan')"
        else
            log_error "conan is not available"
            ((failed++))
        fi
    else
        log_error "conan is not available"
        ((failed++))
    fi
    
    if [[ $failed -eq 0 ]]; then
        log_success "All tools verified successfully!"
        return 0
    else
        log_error "$failed tools failed verification"
        return 1
    fi
}

# Usage information
show_help() {
    cat << EOF
Dashcam Development Environment Setup

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --minimal       Install only essential tools (no IDE extensions)
    --skip-tools    Skip optional development tools (VS Code, Docker)
    --verbose       Enable verbose output
    --help          Show this help message

EXAMPLES:
    $0                    # Full setup
    $0 --minimal          # Minimal setup
    $0 --skip-tools       # Skip optional tools

EOF
}

# Argument parsing
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --minimal)
                MINIMAL_INSTALL=true
                shift
                ;;
            --skip-tools)
                SKIP_TOOLS=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                set -x  # Enable bash tracing
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main setup sequence
main() {
    parse_arguments "$@"
    
    log_info "Starting Dashcam development environment setup..."
    
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
    setup_vscode
    setup_docker
    
    # Verify installation
    if ! verify_setup; then
        log_warning "Some tools failed verification, but continuing..."
    fi
    
    echo ""
    log_success "Development environment setup complete!"
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
    echo ""
    echo "For Conan (C++ package management):"
    if [ "$uv_available" = true ]; then
        echo "1. Use 'uv run conan' for Conan commands"
        echo "2. Example: 'uv run conan install . --build=missing'"
    else
        echo "1. Use 'conan' for Conan commands"
        echo "2. Example: 'conan install . --build=missing'"
    fi
    echo ""
    if [[ "$PLATFORM" != "macos" ]] && [[ "$SKIP_TOOLS" == false ]]; then
        echo "⚠️  Note: If you installed Docker, please log out and log back in"
        echo "   for Docker group changes to take effect."
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
