#!/bin/bash
# Tiger Style Cleanup Script for Dashcam Project
# =============================================
# This script provides comprehensive cleanup capabilities for the Dashcam project,
# removing temporary files, build artifacts, and resetting the development environment.
#
# Features:
# - Default: Clean all temporary files and artifacts
# - Selective cleanup: Choose specific components to clean
# - Safe operation: Confirmation prompts for destructive operations
# - Cross-platform: Works on Linux and macOS
# - Comprehensive logging: Clear feedback on what's being cleaned

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color output functions for better user experience
info() { echo -e "\033[36m$1\033[0m"; }
success() { echo -e "\033[32m$1\033[0m"; }
warning() { echo -e "\033[33m$1\033[0m"; }
error() { echo -e "\033[31m$1\033[0m"; }

# Default values
CLEAN_ALL=false
CLEAN_BUILD=false
CLEAN_CONAN=false
CLEAN_PYTHON=false
CLEAN_DOCKER=false
CLEAN_LOGS=false
CLEAN_GENERATED=false
CLEAN_IDE=false
CLEAN_TEMP=false
FORCE=false
DRY_RUN=false
SHOW_HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all|-a)
            CLEAN_ALL=true
            shift
            ;;
        --build|-b)
            CLEAN_BUILD=true
            shift
            ;;
        --conan|-c)
            CLEAN_CONAN=true
            shift
            ;;
        --python|-p)
            CLEAN_PYTHON=true
            shift
            ;;
        --docker|-d)
            CLEAN_DOCKER=true
            shift
            ;;
        --logs|-l)
            CLEAN_LOGS=true
            shift
            ;;
        --generated|-g)
            CLEAN_GENERATED=true
            shift
            ;;
        --ide|-i)
            CLEAN_IDE=true
            shift
            ;;
        --temp|-t)
            CLEAN_TEMP=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Help information
if [[ "$SHOW_HELP" == "true" ]]; then
    cat << 'EOF'
Dashcam Project Cleanup Script
=============================

USAGE:
    ./scripts/clean.sh [OPTIONS]

OPTIONS:
    -a, --all            Clean everything (default if no other options specified)
    -b, --build          Clean build directory and CMake cache
    -c, --conan          Clean Conan cache and packages  
    -p, --python         Clean Python virtual environment and cache
    -d, --docker         Clean Docker containers and images
    -l, --logs           Clean log files
    -g, --generated      Clean generated files (protobuf/gRPC)
    -i, --ide            Clean IDE-specific files (.vscode settings, etc.)
    -t, --temp           Clean temporary files and system caches
    -f, --force          Skip confirmation prompts
    -n, --dry-run        Show what would be cleaned without actually cleaning
    -h, --help           Show this help information

EXAMPLES:
    ./scripts/clean.sh                     # Clean everything (with confirmation)
    ./scripts/clean.sh -b -p               # Clean only build and Python artifacts
    ./scripts/clean.sh -a -f               # Clean everything without confirmation
    ./scripts/clean.sh -n                  # Preview what would be cleaned

COMPONENTS CLEANED:
    Build:      build/, CMakeCache.txt, CMakeFiles/, compile_commands.json
    Conan:      ~/.conan2/ cache, conanfile.lock, conan generated files
    Python:     .venv/, __pycache__/, *.pyc, .pytest_cache/, .coverage
    Docker:     Project containers, images, volumes, networks
    Logs:       *.log files, crash dumps, debug output
    Generated:  Protobuf/gRPC generated files, build artifacts
    IDE:        .vscode/settings.json user overrides, temporary IDE files
    Temp:       System temp files, caches, swap files

EOF
    exit 0
fi

# Script initialization
info "🧹 Dashcam Project Cleanup Script"
info "Project root: $PROJECT_ROOT"
info ""

# Change to project root
cd "$PROJECT_ROOT"

# Determine what to clean
CLEAN_COMPONENTS=()

if [[ "$CLEAN_ALL" == "true" ]] || [[ "$CLEAN_BUILD" == "false" && "$CLEAN_CONAN" == "false" && "$CLEAN_PYTHON" == "false" && "$CLEAN_DOCKER" == "false" && "$CLEAN_LOGS" == "false" && "$CLEAN_GENERATED" == "false" && "$CLEAN_IDE" == "false" && "$CLEAN_TEMP" == "false" ]]; then
    # If --all is specified or no specific components are specified, clean everything
    CLEAN_COMPONENTS=("Build" "Conan" "Python" "Docker" "Logs" "Generated" "IDE" "Temp")
    info "🎯 Cleaning mode: ALL components"
else
    # Clean only specified components
    [[ "$CLEAN_BUILD" == "true" ]] && CLEAN_COMPONENTS+=("Build")
    [[ "$CLEAN_CONAN" == "true" ]] && CLEAN_COMPONENTS+=("Conan")
    [[ "$CLEAN_PYTHON" == "true" ]] && CLEAN_COMPONENTS+=("Python")
    [[ "$CLEAN_DOCKER" == "true" ]] && CLEAN_COMPONENTS+=("Docker")
    [[ "$CLEAN_LOGS" == "true" ]] && CLEAN_COMPONENTS+=("Logs")
    [[ "$CLEAN_GENERATED" == "true" ]] && CLEAN_COMPONENTS+=("Generated")
    [[ "$CLEAN_IDE" == "true" ]] && CLEAN_COMPONENTS+=("IDE")
    [[ "$CLEAN_TEMP" == "true" ]] && CLEAN_COMPONENTS+=("Temp")
    info "🎯 Cleaning mode: SELECTIVE ($(IFS=', '; echo "${CLEAN_COMPONENTS[*]}"))"
fi

info ""

# Function to safely remove items
remove_safely_with_logging() {
    local path="$1"
    local description="$2"
    local recursive="${3:-false}"
    
    if [[ -e "$path" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            warning "  [DRY RUN] Would remove: $description ($path)"
        else
            if [[ "$recursive" == "true" ]]; then
                if rm -rf "$path" 2>/dev/null; then
                    success "  ✅ Removed: $description"
                else
                    error "  ❌ Failed to remove $description"
                fi
            else
                if rm -f "$path" 2>/dev/null; then
                    success "  ✅ Removed: $description"
                else
                    error "  ❌ Failed to remove $description"
                fi
            fi
        fi
    else
        info "  ℹ️  Not found: $description"
    fi
}

# Function to run commands safely
invoke_safely_with_logging() {
    local command="$1"
    local description="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "  [DRY RUN] Would run: $description"
        warning "    Command: $command"
    else
        info "  🔄 Running: $description"
        if eval "$command" >/dev/null 2>&1; then
            success "  ✅ Completed: $description"
        else
            error "  ❌ Failed: $description"
        fi
    fi
}

# Confirmation prompt (unless --force is specified)
if [[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]]; then
    warning "⚠️  This will remove temporary files and build artifacts."
    warning "Components to clean: $(IFS=', '; echo "${CLEAN_COMPONENTS[*]}")"
    warning ""
    read -p "Do you want to continue? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        info "Cleanup cancelled."
        exit 0
    fi
    info ""
fi

# Start cleanup process
start_time=$(date +%s)
info "🚀 Starting cleanup at $(date '+%Y-%m-%d %H:%M:%S')"
info ""

# Component: Build artifacts
if [[ " ${CLEAN_COMPONENTS[*]} " =~ " Build " ]]; then
    info "🔨 Cleaning Build artifacts..."
    
    # Main build directory
    remove_safely_with_logging "build" "Build directory" true
    
    # CMake files
    remove_safely_with_logging "CMakeCache.txt" "CMake cache file"
    remove_safely_with_logging "CMakeFiles" "CMake files directory" true
    remove_safely_with_logging "cmake_install.cmake" "CMake install script"
    remove_safely_with_logging "Makefile" "Generated Makefile"
    
    # Compilation database
    remove_safely_with_logging "compile_commands.json" "Compilation database"
    
    # Build artifacts
    find . -name "*.o" -o -name "*.obj" -o -name "*.a" -o -name "*.lib" -o -name "*.so" -o -name "*.dylib" 2>/dev/null | while read -r file; do
        remove_safely_with_logging "$file" "Build artifact: $(basename "$file")"
    done
    
    info ""
fi

# Component: Conan artifacts
if [[ " ${CLEAN_COMPONENTS[*]} " =~ " Conan " ]]; then
    info "📦 Cleaning Conan artifacts..."
    
    # Local Conan files
    remove_safely_with_logging "conanfile.lock" "Conan lock file"
    remove_safely_with_logging "conandata.yml" "Conan data file"
    remove_safely_with_logging "conanbuild.sh" "Conan build script"
    remove_safely_with_logging "conanrun.sh" "Conan run script"
    remove_safely_with_logging "conan_toolchain.cmake" "Conan CMake toolchain"
    remove_safely_with_logging "CMakePresets.json" "CMake presets (Conan generated)"
    remove_safely_with_logging "CMakeUserPresets.json" "CMake user presets"
    
    # Conan generated CMake files
    find . -maxdepth 1 -name "*conan*.cmake" -o -name "Find*.cmake" 2>/dev/null | while read -r file; do
        remove_safely_with_logging "$file" "Conan CMake file: $(basename "$file")"
    done
    
    # Optional: Clean global Conan cache (ask for confirmation)
    if [[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]]; then
        read -p "Also clean global Conan cache? This affects other projects. (y/N): " clean_global_conan
        if [[ "$clean_global_conan" == "y" || "$clean_global_conan" == "Y" ]]; then
            invoke_safely_with_logging "conan remove '*' --confirm" "Global Conan package cache"
        fi
    fi
    
    info ""
fi

# Component: Python artifacts
if [[ " ${CLEAN_COMPONENTS[*]} " =~ " Python " ]]; then
    info "🐍 Cleaning Python artifacts..."
    
    # Virtual environment
    remove_safely_with_logging ".venv" "Python virtual environment" true
    remove_safely_with_logging "venv" "Alternative Python virtual environment" true
    
    # Python cache files
    find . -name "__pycache__" -type d 2>/dev/null | while read -r dir; do
        remove_safely_with_logging "$dir" "Python cache: $dir" true
    done
    
    # Python compiled files
    find . -name "*.pyc" -o -name "*.pyo" -o -name "*.pyd" 2>/dev/null | while read -r file; do
        remove_safely_with_logging "$file" "Python compiled file: $(basename "$file")"
    done
    
    # Python testing artifacts
    remove_safely_with_logging ".pytest_cache" "Pytest cache" true
    remove_safely_with_logging ".coverage" "Coverage data file"
    remove_safely_with_logging "htmlcov" "Coverage HTML report" true
    remove_safely_with_logging ".tox" "Tox testing artifacts" true
    
    # Python packaging artifacts
    remove_safely_with_logging "dist" "Python distribution directory" true
    find . -name "*.egg-info" -type d 2>/dev/null | while read -r dir; do
        remove_safely_with_logging "$dir" "Python egg info directory: $(basename "$dir")" true
    done
    
    info ""
fi

# Component: Docker artifacts
if [[ " ${CLEAN_COMPONENTS[*]} " =~ " Docker " ]]; then
    info "🐳 Cleaning Docker artifacts..."
    
    # Check if Docker is available
    if command -v docker &> /dev/null; then
        # Project-specific containers
        invoke_safely_with_logging "docker ps -a --filter 'label=project=dashcam' -q | xargs -r docker rm -f" "Project Docker containers"
        
        # Project-specific images
        invoke_safely_with_logging "docker images --filter 'label=project=dashcam' -q | xargs -r docker rmi -f" "Project Docker images"
        
        # Project-specific volumes
        invoke_safely_with_logging "docker volume ls --filter 'label=project=dashcam' -q | xargs -r docker volume rm" "Project Docker volumes"
        
        # Project-specific networks
        invoke_safely_with_logging "docker network ls --filter 'label=project=dashcam' -q | xargs -r docker network rm" "Project Docker networks"
    else
        warning "  Docker not available, skipping Docker cleanup"
    fi
    
    info ""
fi

# Component: Log files
if [[ " ${CLEAN_COMPONENTS[*]} " =~ " Logs " ]]; then
    info "📄 Cleaning Log files..."
    
    # Application log files
    find . -name "*.log" -o -name "*.log.*" 2>/dev/null | while read -r file; do
        remove_safely_with_logging "$file" "Log file: $(basename "$file")"
    done
    
    # Debug and crash files
    find . -name "core" -o -name "core.*" -o -name "*.dmp" -o -name "*.crashlog" 2>/dev/null | while read -r file; do
        remove_safely_with_logging "$file" "Debug/crash file: $(basename "$file")"
    done
    
    # Logs directory
    remove_safely_with_logging "logs" "Logs directory" true
    
    info ""
fi

# Component: Generated files
if [[ " ${CLEAN_COMPONENTS[*]} " =~ " Generated " ]]; then
    info "⚙️ Cleaning Generated files..."
    
    # Protobuf/gRPC generated files
    if [[ -d "build/generated" ]]; then
        remove_safely_with_logging "build/generated" "Generated protobuf/gRPC files" true
    fi
    
    # Any .pb.cc, .pb.h, .grpc.pb.cc, .grpc.pb.h files outside build directory
    find . -name "*.pb.cc" -o -name "*.pb.h" -o -name "*.grpc.pb.cc" -o -name "*.grpc.pb.h" 2>/dev/null | grep -v "/build/" | while read -r file; do
        remove_safely_with_logging "$file" "Generated protobuf file: $(basename "$file")"
    done
    
    # Auto-generated documentation
    remove_safely_with_logging "docs/_build" "Generated documentation" true
    remove_safely_with_logging "docs/html" "Generated HTML documentation" true
    
    info ""
fi

# Component: IDE files
if [[ " ${CLEAN_COMPONENTS[*]} " =~ " IDE " ]]; then
    info "💻 Cleaning IDE files..."
    
    # VS Code user settings (keep workspace settings)
    remove_safely_with_logging ".vscode/settings.json" "VS Code user settings"
    remove_safely_with_logging ".vscode/.ropeproject" "VS Code rope project" true
    
    # JetBrains files
    remove_safely_with_logging ".idea" "JetBrains IDE directory" true
    
    # Editor files
    find . -name "*.swp" -o -name "*.swo" -o -name "*~" 2>/dev/null | while read -r file; do
        remove_safely_with_logging "$file" "Editor file: $(basename "$file")"
    done
    
    info ""
fi

# Component: Temporary files
if [[ " ${CLEAN_COMPONENTS[*]} " =~ " Temp " ]]; then
    info "🗑️ Cleaning Temporary files..."
    
    # System temporary files
    find . -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -o -name "*.backup" 2>/dev/null | while read -r file; do
        remove_safely_with_logging "$file" "Temporary file: $(basename "$file")"
    done
    
    # OS-specific files
    if [[ "$OSTYPE" == "darwin"* ]]; then
        find . -name ".DS_Store" -o -name "._*" 2>/dev/null | while read -r file; do
            remove_safely_with_logging "$file" "macOS system file: $(basename "$file")"
        done
    fi
    
    # Node.js files (if any)
    remove_safely_with_logging "node_modules" "Node.js modules" true
    remove_safely_with_logging "package-lock.json" "Node.js package lock"
    
    info ""
fi

# Reset environment variables (if any were set explicitly by our scripts)
info "🔄 Resetting environment variables..."

env_vars_to_reset=(
    "DASHCAM_BUILD_TYPE"
    "DASHCAM_INSTALL_PREFIX"
    "DASHCAM_CONFIG_PATH"
    "CONAN_USER_HOME"
    "CMAKE_GENERATOR"
)

for var in "${env_vars_to_reset[@]}"; do
    if [[ -n "${!var:-}" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            warning "  [DRY RUN] Would reset environment variable: $var"
        else
            unset "$var"
            success "  ✅ Reset environment variable: $var"
        fi
    fi
done

info ""

# Final summary
end_time=$(date +%s)
duration=$((end_time - start_time))

success "🎉 Cleanup completed!"
info "Duration: $duration seconds"
info "Cleaned components: $(IFS=', '; echo "${CLEAN_COMPONENTS[*]}")"

if [[ "$DRY_RUN" == "true" ]]; then
    warning "This was a DRY RUN - no files were actually removed."
    info "Run without --dry-run to perform actual cleanup."
fi

info ""
info "💡 Tips:"
info "  - Use --dry-run to preview what will be cleaned"
info "  - Use specific flags (--build, --python, etc.) for targeted cleanup"
info "  - Use --force to skip confirmation prompts"
info ""

# Return to original directory
cd "$PROJECT_ROOT"
