# Cleanup Script Documentation

## Overview

The Dashcam project includes comprehensive cleanup scripts that help maintain a clean development environment by removing temporary files, build artifacts, and resetting environment variables. The cleanup system provides both complete and selective cleaning capabilities with safety features and detailed logging.

## Scripts

### Windows PowerShell Script
- **Location**: `scripts/clean.ps1`
- **Platform**: Windows
- **Shell**: PowerShell 5.1+

### Linux/macOS Bash Script
- **Location**: `scripts/clean.sh`
- **Platform**: Linux, macOS
- **Shell**: Bash 4.0+

## Features

### 🧹 Comprehensive Cleaning
The cleanup scripts can remove all development artifacts including:
- Build directories and CMake cache files
- Conan package management artifacts
- Python virtual environments and cache files
- Docker containers, images, and volumes
- Log files and debug output
- Generated protobuf/gRPC files
- IDE-specific temporary files
- System temporary files and caches

### 🎯 Selective Cleaning
Clean only specific components using targeted flags:
- `--build` / `-Build`: Build artifacts only
- `--python` / `-Python`: Python environment only
- `--docker` / `-Docker`: Docker artifacts only
- And more...

### 🛡️ Safety Features
- **Confirmation prompts**: Prevents accidental data loss
- **Dry run mode**: Preview what will be cleaned
- **Force mode**: Skip confirmations for automation
- **Error handling**: Graceful failure with detailed logging
- **Selective cleaning**: Avoid removing important files

### 📊 Detailed Logging
- Color-coded output for easy reading
- Progress indicators for long operations
- Success/failure status for each operation
- Duration tracking and summary statistics

## Default Behavior

**Safety First**: By default, the cleanup scripts exclude IDE files to prevent accidental removal of important development configurations. The default behavior includes:

✅ **Cleaned by default:**
- Build directories and CMake cache files
- Conan package management artifacts  
- Python virtual environments and cache files
- Docker containers, images, and volumes
- Log files and debug output
- Generated protobuf/gRPC files
- System temporary files and caches

❌ **Excluded by default (for safety):**
- IDE-specific files (.vscode settings, .idea directories, etc.)

To clean IDE files, you must explicitly:
- Use the `--all` / `-All` flag to clean everything including IDE files
- Use the `--ide` / `-IDE` flag to clean only IDE files
- Use specific component flags if you want other components + IDE files

This ensures that important IDE configurations, workspace settings, and development preferences are preserved during routine cleanup operations.

## Usage

### Basic Usage

#### Windows (PowerShell)
```powershell
# Clean development artifacts (excludes IDE files by default)
.\scripts\clean.ps1

# Clean everything including IDE files
.\scripts\clean.ps1 -All

# Clean everything including IDE files without confirmation
.\scripts\clean.ps1 -All -Force

# Preview what will be cleaned
.\scripts\clean.ps1 -DryRun

# Get help
.\scripts\clean.ps1 -Help
```

#### Linux/macOS (Bash)
```bash
# Clean development artifacts (excludes IDE files by default)
./scripts/clean.sh

# Clean everything including IDE files
./scripts/clean.sh --all

# Clean everything including IDE files without confirmation
./scripts/clean.sh --all --force

# Preview what will be cleaned
./scripts/clean.sh --dry-run

# Get help
./scripts/clean.sh --help
```

### Selective Cleaning

#### Windows Examples
```powershell
# Clean only build artifacts
.\scripts\clean.ps1 -Build

# Clean build and Python artifacts
.\scripts\clean.ps1 -Build -Python

# Clean everything except Docker
.\scripts\clean.ps1 -Build -Conan -Python -Logs -Generated -IDE -Temp

# Force clean Python environment
.\scripts\clean.ps1 -Python -Force
```

#### Linux/macOS Examples
```bash
# Clean only build artifacts
./scripts/clean.sh --build

# Clean build and Python artifacts
./scripts/clean.sh --build --python

# Clean everything except Docker
./scripts/clean.sh --build --conan --python --logs --generated --ide --temp

# Force clean Python environment
./scripts/clean.sh --python --force
```

## Command Line Options

### Windows PowerShell Parameters

| Parameter | Short | Description |
|-----------|-------|-------------|
| `-All` | | Clean everything including IDE files (use explicitly) |
| `-Build` | | Clean build directory and CMake cache |
| `-Conan` | | Clean Conan cache and packages |
| `-Python` | | Clean Python virtual environment and cache |
| `-Docker` | | Clean Docker containers and images |
| `-Logs` | | Clean log files |
| `-Generated` | | Clean generated files (protobuf/gRPC) |
| `-IDE` | | Clean IDE-specific files |
| `-Temp` | | Clean temporary files and system caches |
| `-Force` | | Skip confirmation prompts |
| `-DryRun` | | Show what would be cleaned without cleaning |
| `-Help` | | Show help information |

### Linux/macOS Command Line Arguments

| Argument | Short | Description |
|----------|-------|-------------|
| `--all` | `-a` | Clean everything including IDE files (use explicitly) |
| `--build` | `-b` | Clean build directory and CMake cache |
| `--conan` | `-c` | Clean Conan cache and packages |
| `--python` | `-p` | Clean Python virtual environment and cache |
| `--docker` | `-d` | Clean Docker containers and images |
| `--logs` | `-l` | Clean log files |
| `--generated` | `-g` | Clean generated files (protobuf/gRPC) |
| `--ide` | `-i` | Clean IDE-specific files |
| `--temp` | `-t` | Clean temporary files and system caches |
| `--force` | `-f` | Skip confirmation prompts |
| `--dry-run` | `-n` | Show what would be cleaned without cleaning |
| `--help` | `-h` | Show help information |

## Components Cleaned

### 🔨 Build Artifacts
**Files and directories removed:**
- `build/` - Main build directory
- `CMakeCache.txt` - CMake configuration cache
- `CMakeFiles/` - CMake internal files
- `cmake_install.cmake` - CMake installation script
- `Makefile` - Generated makefiles
- `compile_commands.json` - Compilation database
- `*.sln`, `*.vcxproj*` - Visual Studio files
- `*.o`, `*.obj`, `*.a`, `*.lib`, `*.dll`, `*.so`, `*.dylib` - Object and library files

**Why clean this:**
- Resolves build system configuration issues
- Forces complete rebuild with fresh configuration
- Removes architecture-specific compiled code
- Clears outdated dependency information

### 📦 Conan Artifacts
**Files and directories removed:**
- `conanfile.lock` - Conan dependency lock file
- `conandata.yml` - Conan package metadata
- `conanbuild.*` - Conan build environment scripts
- `conanrun.*` - Conan runtime environment scripts
- `conan_toolchain.cmake` - CMake toolchain from Conan
- `CMakePresets.json` - CMake presets (Conan generated)
- `*conan*.cmake`, `Find*.cmake` - Conan CMake modules

**Optional:**
- Global Conan cache (`~/.conan2/`) - Requires confirmation

**Why clean this:**
- Resolves package dependency conflicts
- Forces fresh package resolution
- Clears corrupted package cache
- Resets build environment configuration

### 🐍 Python Artifacts
**Files and directories removed:**
- `.venv/`, `venv/` - Virtual environments
- `__pycache__/` - Python bytecode cache
- `*.pyc`, `*.pyo`, `*.pyd` - Compiled Python files
- `.pytest_cache/` - Pytest cache
- `.coverage`, `htmlcov/` - Coverage reports
- `.tox/` - Tox testing environments
- `dist/`, `*.egg-info/` - Python packaging artifacts

**Why clean this:**
- Resolves Python environment conflicts
- Forces fresh dependency installation
- Clears test result cache
- Removes stale compiled bytecode

### 🐳 Docker Artifacts
**Resources removed:**
- Project-specific containers (labeled `project=dashcam`)
- Project-specific images (labeled `project=dashcam`)
- Project-specific volumes (labeled `project=dashcam`)
- Project-specific networks (labeled `project=dashcam`)

**Safety feature:**
- Only removes resources with the `project=dashcam` label
- Does not affect other Docker resources on the system

**Why clean this:**
- Frees up disk space
- Removes outdated container configurations
- Clears development database state
- Resolves Docker network conflicts

### 📄 Log Files
**Files removed:**
- `*.log`, `*.log.*` - Application log files
- `core`, `core.*` - Unix core dumps
- `*.dmp` - Windows memory dumps
- `*.crashlog` - Crash report files
- `logs/` - Log directory

**Why clean this:**
- Frees up disk space
- Removes sensitive debug information
- Clears outdated diagnostic data
- Prevents log file accumulation

### ⚙️ Generated Files
**Files and directories removed:**
- `build/generated/` - Generated protobuf/gRPC files
- `*.pb.cc`, `*.pb.h` - Protobuf C++ files (outside build)
- `*.grpc.pb.cc`, `*.grpc.pb.h` - gRPC C++ files (outside build)
- `docs/_build/`, `docs/html/` - Generated documentation

**Why clean this:**
- Forces regeneration of protobuf/gRPC code
- Ensures generated code matches current .proto files
- Resolves code generation inconsistencies
- Clears outdated documentation

### 💻 IDE Files
**Files and directories removed:**
- `.vscode/settings.json` - VS Code user settings (keeps workspace settings)
- `.vscode/.ropeproject/` - Python rope project cache
- `*.user`, `*.suo` - Visual Studio user files
- `.vs/` - Visual Studio directory
- `.idea/` - JetBrains IDE directory
- `*.swp`, `*.swo`, `*~` - Editor temporary files

**Safety feature:**
- Preserves workspace-level VS Code settings
- Only removes user-specific IDE configurations

**Why clean this:**
- Resolves IDE configuration conflicts
- Removes user-specific paths and settings
- Clears outdated project metadata
- Fixes corrupted IDE state

### 🗑️ Temporary Files
**Files removed:**
- `*.tmp`, `*.temp`, `*.bak`, `*.backup` - Temporary files
- `Thumbs.db`, `desktop.ini` - Windows system files
- `.DS_Store`, `._*` - macOS system files
- `node_modules/`, `package-lock.json` - Node.js artifacts (if present)

**Why clean this:**
- Frees up disk space
- Removes operating system clutter
- Clears development tool caches
- Removes accidental file artifacts

### 🔄 Environment Variables
**Variables reset:**
- `DASHCAM_BUILD_TYPE` - Build configuration type
- `DASHCAM_INSTALL_PREFIX` - Installation directory
- `DASHCAM_CONFIG_PATH` - Configuration file path
- `CONAN_USER_HOME` - Conan user directory
- `CMAKE_GENERATOR` - CMake generator preference

**Why reset these:**
- Ensures clean environment for next build
- Removes development-specific configurations
- Prevents environment variable conflicts
- Resets to default system behavior

## Safety and Best Practices

### ⚠️ Important Safety Notes

1. **Backup Important Data**: Always ensure important work is committed to version control before running cleanup
2. **Review Before Cleaning**: Use `--dry-run` mode to preview what will be removed
3. **Selective Cleaning**: Use specific component flags instead of cleaning everything when possible
4. **Global Cache Warning**: Cleaning global Conan cache affects other projects on your system

### 🔐 Confirmation Prompts

The cleanup scripts include several safety prompts:

1. **Main confirmation**: Asked before any cleaning begins (unless `--force` is used)
2. **Global Conan cache**: Asked before cleaning system-wide Conan packages
3. **Docker resources**: Only affects project-labeled resources

### 📋 Pre-Cleanup Checklist

Before running the cleanup script:

- [ ] Commit or stash any uncommitted changes
- [ ] Ensure no important files are in temporary locations
- [ ] Close any running development servers or processes
- [ ] Consider using `--dry-run` first to preview changes
- [ ] Backup any custom configuration files

### 🔄 Post-Cleanup Steps

After running cleanup, you may need to:

1. **Reinstall dependencies**: Run build script to reinstall Conan packages
2. **Reconfigure environment**: Re-run Python environment setup
3. **Regenerate files**: CMake will regenerate protobuf/gRPC files on next build
4. **Restore IDE settings**: Reconfigure VS Code or other IDE preferences

## Integration with Development Workflow

### 🔧 Common Scenarios

#### Before Major Changes
```bash
# Clean everything including IDE files to ensure completely fresh start
./scripts/clean.sh --all --force
./scripts/build.sh  # Rebuild from scratch
```

#### Debugging Build Issues
```bash
# Clean only build artifacts (default excludes IDE files)
./scripts/clean.sh --build
./scripts/build.sh  # Try build again
```

#### Daily Development Cleanup
```bash
# Safe cleanup that preserves IDE settings (default behavior)
./scripts/clean.sh --force
```

#### Switching Branches
```bash
# Clean generated files to match new branch
./scripts/clean.sh --generated --build
```

#### Freeing Disk Space
```bash
# Clean logs and temporary files
./scripts/clean.sh --logs --temp --docker
```

#### Environment Reset
```bash
# Clean Python and Conan for fresh dependency resolution
./scripts/clean.sh --python --conan
```

### 🤖 Automation Integration

The cleanup script supports automation through the `--force` flag:

```bash
# In CI/CD pipeline - clean everything including IDE files
./scripts/clean.sh --all --force

# In automated testing - clean only build and Python artifacts
./scripts/clean.sh --build --python --force
./scripts/build.sh
./scripts/test.sh

# Daily maintenance - clean everything except IDE files
./scripts/clean.sh --force
```

### 📈 Performance Considerations

- **Full cleanup**: 5-30 seconds depending on project size
- **Selective cleanup**: 1-10 seconds for specific components
- **Dry run**: Near-instantaneous, good for frequent checking
- **Docker cleanup**: May take longer if many containers/images exist

## Troubleshooting

### Common Issues

#### Permission Errors
```
❌ Failed to remove: Permission denied
```
**Solution**: Run with administrator/sudo privileges or close applications using the files

#### Docker Not Available
```
Docker not available, skipping Docker cleanup
```
**Solution**: This is normal if Docker isn't installed; Docker cleanup is skipped automatically

#### Conan Command Not Found
```
❌ Failed: Global Conan package cache - conan: command not found
```
**Solution**: Install Conan or skip Conan cleanup using selective cleaning

#### Path Too Long (Windows)
```
❌ Failed to remove: The specified path, file name, or both are too long
```
**Solution**: Use selective cleaning to avoid deep directory structures

### Recovery Procedures

#### If Important Files Were Removed
1. Check version control for committed files
2. Look in system recycle bin/trash
3. Restore from backup if available
4. Re-run build process to regenerate files

#### If Build Fails After Cleanup
1. Verify all dependencies are installed
2. Run full build process: `./scripts/build.sh`
3. Check for missing environment variables
4. Consult build documentation

## Advanced Usage

### Custom Environment Variables

You can add custom environment variables to the cleanup script by modifying the `env_vars_to_reset` array:

#### Windows PowerShell
```powershell
$envVarsToReset = @(
    'DASHCAM_BUILD_TYPE',
    'DASHCAM_INSTALL_PREFIX',
    'YOUR_CUSTOM_VAR'  # Add custom variables here
)
```

#### Linux/macOS Bash
```bash
env_vars_to_reset=(
    "DASHCAM_BUILD_TYPE"
    "DASHCAM_INSTALL_PREFIX"
    "YOUR_CUSTOM_VAR"  # Add custom variables here
)
```

### Adding Custom Cleanup Logic

To add custom cleanup logic, find the appropriate component section and add your code:

```bash
# Example: Clean custom cache directory
if [[ " ${CLEAN_COMPONENTS[*]} " =~ " Temp " ]]; then
    # Existing temp cleanup code...
    
    # Add custom cleanup
    remove_safely_with_logging "my_custom_cache" "Custom cache directory" true
fi
```

## Conclusion

The cleanup scripts provide a comprehensive, safe, and efficient way to maintain a clean development environment for the Dashcam project. By using these scripts regularly, developers can:

- Resolve build and dependency issues quickly
- Maintain optimal disk space usage
- Ensure consistent development environment
- Automate cleanup as part of development workflow

For questions or issues with the cleanup scripts, refer to the main project documentation or submit an issue in the project repository.
