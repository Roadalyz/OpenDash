#!/bin/bash
# Standalone script to update VS Code configuration with Conan include paths

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Updating VS Code configuration with Conan include paths..."

cd "$PROJECT_ROOT"

if [ ! -f "compile_commands.json" ]; then
    echo "Error: compile_commands.json not found."
    echo "Please build the project first with: ./scripts/build.sh"
    exit 1
fi

if [ ! -f "scripts/update_vscode_config.py" ]; then
    echo "Error: update_vscode_config.py script not found."
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 not found. Please install Python 3."
    exit 1
fi

python3 scripts/update_vscode_config.py

echo ""
echo "VS Code configuration updated successfully!"
echo ""
echo "To apply the changes:"
echo "1. Reload VS Code window (Cmd+Shift+P -> 'Developer: Reload Window')"
echo "2. Or restart the C++ language server (Cmd+Shift+P -> 'C/C++: Reset IntelliSense Database')"
