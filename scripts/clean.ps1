# Tiger Style Cleanup Script for Dashcam Project
# =============================================
# This script provides comprehensive cleanup capabilities for the Dashcam project,
# removing temporary files, build artifacts, and resetting the development environment.
#
# Features:
# - Default: Clean temporary files and artifacts (excludes IDE files for safety)
# - Selective cleanup: Choose specific components to clean
# - Safe operation: Confirmation prompts for destructive operations
# - Cross-platform: Works on Windows, Linux, and macOS
# - Comprehensive logging: Clear feedback on what's being cleaned
# - Size tracking: Reports how much disk space is freed

param(
    [switch]$All,              # Clean everything including IDE files (use explicitly)
    [switch]$Build,            # Clean build directory and CMake cache
    [switch]$Conan,            # Clean Conan cache and packages
    [switch]$Python,           # Clean Python virtual environment and cache
    [switch]$Docker,           # Clean Docker containers and images
    [switch]$Logs,             # Clean log files
    [switch]$Generated,        # Clean generated files (protobuf/gRPC)
    [switch]$IDE,              # Clean IDE-specific files (.vscode settings, etc.)
    [switch]$Temp,             # Clean temporary files and system caches
    [switch]$Force,            # Skip confirmation prompts
    [switch]$DryRun,           # Show what would be cleaned without actually cleaning
    [switch]$Help              # Show help information
)

# Color output functions for better user experience
function Write-Info($message) { Write-Host $message -ForegroundColor Cyan }
function Write-Success($message) { Write-Host $message -ForegroundColor Green }
function Write-Warning($message) { Write-Host $message -ForegroundColor Yellow }
function Write-Error($message) { Write-Host $message -ForegroundColor Red }

# Variables to track cleanup statistics
$global:TotalBytesCleared = 0
$global:TotalFilesCleared = 0

# Function to get human readable size
function Get-HumanReadableSize($bytes) {
    if ($bytes -lt 1KB) { return "$bytes B" }
    elseif ($bytes -lt 1MB) { return "{0:N1} KB" -f ($bytes / 1KB) }
    elseif ($bytes -lt 1GB) { return "{0:N1} MB" -f ($bytes / 1MB) }
    else { return "{0:N1} GB" -f ($bytes / 1GB) }
}

# Function to get size of file or directory
function Get-PathSize($path) {
    if (-not (Test-Path $path)) { return @{ Size = 0; Files = 0 } }
    
    if (Test-Path $path -PathType Leaf) {
        # It's a file
        $size = (Get-Item $path).Length
        return @{ Size = $size; Files = 1 }
    } else {
        # It's a directory
        try {
            $items = Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue
            $files = $items | Where-Object { -not $_.PSIsContainer }
            $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
            if ($null -eq $totalSize) { $totalSize = 0 }
            return @{ Size = $totalSize; Files = $files.Count }
        } catch {
            return @{ Size = 0; Files = 0 }
        }
    }
}

# Help information
if ($Help) {
    Write-Host @"
Dashcam Project Cleanup Script
=============================

USAGE:
    .\scripts\clean.ps1 [OPTIONS]

OPTIONS:
    -All            Clean everything including IDE files
    -Build          Clean build directory and CMake cache
    -Conan          Clean Conan cache and packages  
    -Python         Clean Python virtual environment and cache
    -Docker         Clean Docker containers and images
    -Logs           Clean log files
    -Generated      Clean generated files (protobuf/gRPC)
    -IDE            Clean IDE-specific files (.vscode settings, etc.)
    -Temp           Clean temporary files and system caches
    -Force          Skip confirmation prompts
    -DryRun         Show what would be cleaned without actually cleaning
    -Help           Show this help information

EXAMPLES:
    .\scripts\clean.ps1                    # Clean everything except IDE files (default behavior)
    .\scripts\clean.ps1 -All               # Clean everything including IDE files
    .\scripts\clean.ps1 -Build -Python     # Clean only build and Python artifacts
    .\scripts\clean.ps1 -IDE               # Clean only IDE files
    .\scripts\clean.ps1 -All -Force        # Clean everything without confirmation
    .\scripts\clean.ps1 -DryRun            # Preview what would be cleaned

COMPONENTS CLEANED:
    Default:    Build, Conan, Python, Docker, Logs, Generated, Temp (excludes IDE)
    Build:      build/, CMakeCache.txt, CMakeFiles/, compile_commands.json
    Conan:      ~/.conan2/ cache, conanfile.lock, conan generated files
    Python:     .venv/, __pycache__/, *.pyc, .pytest_cache/, .coverage
    Docker:     Project containers, images, volumes, networks
    Logs:       *.log files, crash dumps, debug output
    Generated:  Protobuf/gRPC generated files, build artifacts
    IDE:        .vscode/settings.json user overrides, temporary IDE files
    Temp:       System temp files, caches, swap files

"@ -ForegroundColor White
    exit 0
}

# Script initialization
$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Info "🧹 Dashcam Project Cleanup Script"
Write-Info "Project root: $ProjectRoot"
Write-Info ""

# Change to project root
Set-Location $ProjectRoot

# Determine what to clean
$CleanComponents = @()

if ($All) {
    # If -All is specified explicitly, clean everything including IDE files
    $CleanComponents = @('Build', 'Conan', 'Python', 'Docker', 'Logs', 'Generated', 'IDE', 'Temp')
    Write-Info "🎯 Cleaning mode: ALL components (including IDE files)"
} elseif (!$Build -and !$Conan -and !$Python -and !$Docker -and !$Logs -and !$Generated -and !$IDE -and !$Temp) {
    # If no specific components are specified, clean everything EXCEPT IDE files by default
    $CleanComponents = @('Build', 'Conan', 'Python', 'Docker', 'Logs', 'Generated', 'Temp')
    Write-Info "🎯 Cleaning mode: DEFAULT (excluding IDE files - use -All or -IDE to include them)"
} else {
    # Clean only specified components
    if ($Build) { $CleanComponents += 'Build' }
    if ($Conan) { $CleanComponents += 'Conan' }
    if ($Python) { $CleanComponents += 'Python' }
    if ($Docker) { $CleanComponents += 'Docker' }
    if ($Logs) { $CleanComponents += 'Logs' }
    if ($Generated) { $CleanComponents += 'Generated' }
    if ($IDE) { $CleanComponents += 'IDE' }
    if ($Temp) { $CleanComponents += 'Temp' }
    Write-Info "🎯 Cleaning mode: SELECTIVE ($($CleanComponents -join ', '))"
}

Write-Info ""

# Function to safely remove items with size tracking
function Remove-SafelyWithLogging {
    param(
        [string]$Path,
        [string]$Description,
        [switch]$Recurse = $false
    )
    
    if (Test-Path $Path) {
        # Calculate size before removal
        $sizeInfo = Get-PathSize $Path
        $humanSize = Get-HumanReadableSize $sizeInfo.Size
        
        if ($DryRun) {
            Write-Warning "  [DRY RUN] Would remove: $Description ($Path) - $humanSize"
            if ($sizeInfo.Files -gt 1) {
                Write-Warning "    Would free: $humanSize ($($sizeInfo.Files) files)"
            } else {
                Write-Warning "    Would free: $humanSize"
            }
        } else {
            try {
                if ($Recurse) {
                    Remove-Item $Path -Recurse -Force -ErrorAction Stop
                } else {
                    Remove-Item $Path -Force -ErrorAction Stop
                }
                $global:TotalBytesCleared += $sizeInfo.Size
                $global:TotalFilesCleared += $sizeInfo.Files
                if ($sizeInfo.Files -gt 1) {
                    Write-Success "  ✅ Removed: $Description - freed $humanSize ($($sizeInfo.Files) files)"
                } else {
                    Write-Success "  ✅ Removed: $Description - freed $humanSize"
                }
            } catch {
                Write-Error "  ❌ Failed to remove $Description`: $_"
            }
        }
    } else {
        Write-Info "  ℹ️  Not found: $Description"
    }
}

# Function to run commands safely with Conan size estimation
function Invoke-SafelyWithLogging {
    param(
        [string]$Command,
        [string]$Description,
        [switch]$EstimateConanSize = $false
    )
    
    # Try to estimate size for Conan cache cleanup
    $estimatedSize = 0
    $estimatedFiles = 0
    if ($EstimateConanSize -and $Description -like "*Conan*") {
        $conanCacheDir = ""
        if (Test-Path "$env:USERPROFILE\.conan2") {
            $conanCacheDir = "$env:USERPROFILE\.conan2"
        } elseif (Test-Path "$env:USERPROFILE\.conan") {
            $conanCacheDir = "$env:USERPROFILE\.conan"
        }
        
        if ($conanCacheDir -and (Test-Path $conanCacheDir)) {
            $sizeInfo = Get-PathSize $conanCacheDir
            $estimatedSize = $sizeInfo.Size
            $estimatedFiles = $sizeInfo.Files
        }
    }
    
    if ($DryRun) {
        Write-Warning "  [DRY RUN] Would run: $Description"
        Write-Warning "    Command: $Command"
        if ($estimatedSize -gt 0) {
            $humanSize = Get-HumanReadableSize $estimatedSize
            Write-Warning "    Would potentially free: $humanSize ($estimatedFiles files)"
        }
    } else {
        try {
            Write-Info "  🔄 Running: $Description"
            if ($estimatedSize -gt 0) {
                $humanSize = Get-HumanReadableSize $estimatedSize
                Write-Info "  📊 Estimated cleanup: $humanSize ($estimatedFiles files)"
            }
            
            Invoke-Expression $Command | Out-Null
            
            if ($estimatedSize -gt 0) {
                $global:TotalBytesCleared += $estimatedSize
                $global:TotalFilesCleared += $estimatedFiles
                $humanSize = Get-HumanReadableSize $estimatedSize
                Write-Success "  ✅ Completed: $Description - freed ~$humanSize ($estimatedFiles files)"
            } else {
                Write-Success "  ✅ Completed: $Description"
            }
        } catch {
            Write-Error "  ❌ Failed: $Description - $_"
        }
    }
}

# Confirmation prompt (unless -Force is specified)
if (!$Force -and !$DryRun) {
    Write-Warning "⚠️  This will remove temporary files and build artifacts."
    Write-Warning "Components to clean: $($CleanComponents -join ', ')"
    Write-Warning ""
    $confirm = Read-Host "Do you want to continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Info "Cleanup cancelled."
        exit 0
    }
    Write-Info ""
}

# Start cleanup process
$startTime = Get-Date
Write-Info "🚀 Starting cleanup at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info ""

# Component: Build artifacts
if ('Build' -in $CleanComponents) {
    Write-Info "🔨 Cleaning Build artifacts..."
    
    # Main build directory
    Remove-SafelyWithLogging -Path "build" -Description "Build directory" -Recurse
    
    # CMake files
    Remove-SafelyWithLogging -Path "CMakeCache.txt" -Description "CMake cache file"
    Remove-SafelyWithLogging -Path "CMakeFiles" -Description "CMake files directory" -Recurse
    Remove-SafelyWithLogging -Path "cmake_install.cmake" -Description "CMake install script"
    Remove-SafelyWithLogging -Path "Makefile" -Description "Generated Makefile"
    
    # Compilation database
    Remove-SafelyWithLogging -Path "compile_commands.json" -Description "Compilation database"
    
    # Visual Studio files
    Remove-SafelyWithLogging -Path "*.sln" -Description "Visual Studio solution files"
    Remove-SafelyWithLogging -Path "*.vcxproj*" -Description "Visual Studio project files"
    
    # Build artifacts
    Get-ChildItem -Path "." -Include "*.o", "*.obj", "*.a", "*.lib", "*.dll", "*.so", "*.dylib" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyWithLogging -Path $_.FullName -Description "Build artifact: $($_.Name)"
    }
    
    Write-Info ""
}

# Component: Conan artifacts
if ('Conan' -in $CleanComponents) {
    Write-Info "📦 Cleaning Conan artifacts..."
    
    # Local Conan files
    Remove-SafelyWithLogging -Path "conanfile.lock" -Description "Conan lock file"
    Remove-SafelyWithLogging -Path "conandata.yml" -Description "Conan data file"
    Remove-SafelyWithLogging -Path "conanbuild.sh" -Description "Conan build script (Linux)"
    Remove-SafelyWithLogging -Path "conanbuild.bat" -Description "Conan build script (Windows)"
    Remove-SafelyWithLogging -Path "conanrun.sh" -Description "Conan run script (Linux)"
    Remove-SafelyWithLogging -Path "conanrun.bat" -Description "Conan run script (Windows)"
    Remove-SafelyWithLogging -Path "conan_toolchain.cmake" -Description "Conan CMake toolchain"
    Remove-SafelyWithLogging -Path "CMakePresets.json" -Description "CMake presets (Conan generated)"
    Remove-SafelyWithLogging -Path "CMakeUserPresets.json" -Description "CMake user presets"
    
    # Conan generated CMake files
    Get-ChildItem -Path "." -Include "*conan*.cmake", "Find*.cmake" -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyWithLogging -Path $_.FullName -Description "Conan CMake file: $($_.Name)"
    }
    
    # Optional: Clean global Conan cache (ask for confirmation)
    if (!$Force -and !$DryRun) {
        $cleanGlobalConan = Read-Host "Also clean global Conan cache? This affects other projects. (y/N)"
        if ($cleanGlobalConan -eq 'y' -or $cleanGlobalConan -eq 'Y') {
            # Check if conan is available via uv run, fallback to direct conan command
            if ((Test-Path "$ProjectRoot\.venv\Scripts\python.exe") -and (Get-Command "uv" -ErrorAction SilentlyContinue)) {
                Invoke-SafelyWithLogging -Command "uv run conan remove '*' --confirm" -Description "Global Conan package cache" -EstimateConanSize
            } else {
                Invoke-SafelyWithLogging -Command "conan remove '*' --confirm" -Description "Global Conan package cache" -EstimateConanSize
            }
        }
    }
    
    Write-Info ""
}

# Component: Python artifacts
if ('Python' -in $CleanComponents) {
    Write-Info "🐍 Cleaning Python artifacts..."
    
    # Virtual environment
    Remove-SafelyWithLogging -Path ".venv" -Description "Python virtual environment" -Recurse
    Remove-SafelyWithLogging -Path "venv" -Description "Alternative Python virtual environment" -Recurse
    
    # Python cache files
    Get-ChildItem -Path "." -Include "__pycache__" -Recurse -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyWithLogging -Path $_.FullName -Description "Python cache: $($_.FullName)" -Recurse
    }
    
    # Python compiled files
    Get-ChildItem -Path "." -Include "*.pyc", "*.pyo", "*.pyd" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyWithLogging -Path $_.FullName -Description "Python compiled file: $($_.Name)"
    }
    
    # Python testing artifacts
    Remove-SafelyWithLogging -Path ".pytest_cache" -Description "Pytest cache" -Recurse
    Remove-SafelyWithLogging -Path ".coverage" -Description "Coverage data file"
    Remove-SafelyWithLogging -Path "htmlcov" -Description "Coverage HTML report" -Recurse
    Remove-SafelyWithLogging -Path ".tox" -Description "Tox testing artifacts" -Recurse
    
    # Python packaging artifacts
    Remove-SafelyWithLogging -Path "dist" -Description "Python distribution directory" -Recurse
    Remove-SafelyWithLogging -Path "*.egg-info" -Description "Python egg info directories" -Recurse
    
    Write-Info ""
}

# Component: Docker artifacts
if ('Docker' -in $CleanComponents) {
    Write-Info "🐳 Cleaning Docker artifacts..."
    
    # Check if Docker is available
    try {
        docker --version | Out-Null
        $dockerAvailable = $true
    } catch {
        Write-Warning "  Docker not available, skipping Docker cleanup"
        $dockerAvailable = $false
    }
    
    if ($dockerAvailable) {
        # Project-specific containers
        Invoke-SafelyWithLogging -Command "docker ps -a --filter 'label=project=dashcam' -q | ForEach-Object { docker rm -f `$_ }" -Description "Project Docker containers"
        
        # Project-specific images
        Invoke-SafelyWithLogging -Command "docker images --filter 'label=project=dashcam' -q | ForEach-Object { docker rmi -f `$_ }" -Description "Project Docker images"
        
        # Project-specific volumes
        Invoke-SafelyWithLogging -Command "docker volume ls --filter 'label=project=dashcam' -q | ForEach-Object { docker volume rm `$_ }" -Description "Project Docker volumes"
        
        # Project-specific networks
        Invoke-SafelyWithLogging -Command "docker network ls --filter 'label=project=dashcam' -q | ForEach-Object { docker network rm `$_ }" -Description "Project Docker networks"
    }
    
    Write-Info ""
}

# Component: Log files
if ('Logs' -in $CleanComponents) {
    Write-Info "📄 Cleaning Log files..."
    
    # Application log files
    Get-ChildItem -Path "." -Include "*.log", "*.log.*" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyWithLogging -Path $_.FullName -Description "Log file: $($_.Name)"
    }
    
    # Debug and crash files
    Get-ChildItem -Path "." -Include "core", "core.*", "*.dmp", "*.crashlog" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyWithLogging -Path $_.FullName -Description "Debug/crash file: $($_.Name)"
    }
    
    # Logs directory
    Remove-SafelyWithLogging -Path "logs" -Description "Logs directory" -Recurse
    
    Write-Info ""
}

# Component: Generated files
if ('Generated' -in $CleanComponents) {
    Write-Info "⚙️ Cleaning Generated files..."
    
    # Protobuf/gRPC generated files
    if (Test-Path "build/generated") {
        Remove-SafelyWithLogging -Path "build/generated" -Description "Generated protobuf/gRPC files" -Recurse
    }
    
    # Any .pb.cc, .pb.h, .grpc.pb.cc, .grpc.pb.h files outside build directory
    Get-ChildItem -Path "." -Include "*.pb.cc", "*.pb.h", "*.grpc.pb.cc", "*.grpc.pb.h" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.FullName -notlike "*build*") {
            Remove-SafelyWithLogging -Path $_.FullName -Description "Generated protobuf file: $($_.Name)"
        }
    }
    
    # Auto-generated documentation
    Remove-SafelyWithLogging -Path "docs/_build" -Description "Generated documentation" -Recurse
    Remove-SafelyWithLogging -Path "docs/html" -Description "Generated HTML documentation" -Recurse
    
    Write-Info ""
}

# Component: IDE files
if ('IDE' -in $CleanComponents) {
    Write-Info "💻 Cleaning IDE files..."
    
    # VS Code user settings (keep workspace settings)
    Remove-SafelyWithLogging -Path ".vscode/settings.json" -Description "VS Code user settings"
    Remove-SafelyWithLogging -Path ".vscode/.ropeproject" -Description "VS Code rope project" -Recurse
    
    # Visual Studio files
    Remove-SafelyWithLogging -Path "*.user" -Description "Visual Studio user files"
    Remove-SafelyWithLogging -Path "*.suo" -Description "Visual Studio solution user options"
    Remove-SafelyWithLogging -Path ".vs" -Description "Visual Studio directory" -Recurse
    
    # JetBrains files
    Remove-SafelyWithLogging -Path ".idea" -Description "JetBrains IDE directory" -Recurse
    
    # Other IDE files
    Remove-SafelyWithLogging -Path "*.swp" -Description "Vim swap files"
    Remove-SafelyWithLogging -Path "*.swo" -Description "Vim swap files"
    Remove-SafelyWithLogging -Path "*~" -Description "Editor backup files"
    
    Write-Info ""
}

# Component: Temporary files
if ('Temp' -in $CleanComponents) {
    Write-Info "🗑️ Cleaning Temporary files..."
    
    # System temporary files
    Get-ChildItem -Path "." -Include "*.tmp", "*.temp", "*.bak", "*.backup" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-SafelyWithLogging -Path $_.FullName -Description "Temporary file: $($_.Name)"
    }
    
    # OS-specific files
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        Get-ChildItem -Path "." -Include "Thumbs.db", "desktop.ini" -Recurse -Hidden -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-SafelyWithLogging -Path $_.FullName -Description "Windows system file: $($_.Name)"
        }
    } else {
        Get-ChildItem -Path "." -Include ".DS_Store", "._*" -Recurse -Hidden -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-SafelyWithLogging -Path $_.FullName -Description "macOS system file: $($_.Name)"
        }
    }
    
    # Node.js files (if any)
    Remove-SafelyWithLogging -Path "node_modules" -Description "Node.js modules" -Recurse
    Remove-SafelyWithLogging -Path "package-lock.json" -Description "Node.js package lock"
    
    Write-Info ""
}

# Reset environment variables (if any were set explicitly by our scripts)
Write-Info "🔄 Resetting environment variables..."

$envVarsToReset = @(
    'DASHCAM_BUILD_TYPE',
    'DASHCAM_INSTALL_PREFIX', 
    'DASHCAM_CONFIG_PATH',
    'CONAN_USER_HOME',
    'CMAKE_GENERATOR'
)

foreach ($var in $envVarsToReset) {
    if ([Environment]::GetEnvironmentVariable($var, "User")) {
        if ($DryRun) {
            Write-Warning "  [DRY RUN] Would reset environment variable: $var"
        } else {
            try {
                [Environment]::SetEnvironmentVariable($var, $null, "User")
                Write-Success "  ✅ Reset environment variable: $var"
            } catch {
                Write-Error "  ❌ Failed to reset environment variable $var`: $_"
            }
        }
    }
}

Write-Info ""

# Final summary
$endTime = Get-Date
$duration = $endTime - $startTime

# Cleanup statistics
Write-Success "🎉 Cleanup completed!"
Write-Info "Duration: $($duration.TotalSeconds.ToString('F1')) seconds"
Write-Info "Cleaned components: $($CleanComponents -join ', ')"

if ($global:TotalBytesCleared -gt 0 -or $global:TotalFilesCleared -gt 0) {
    Write-Info ""
    Write-Info "📊 Cleanup Statistics:"
    Write-Info "  Files removed: $global:TotalFilesCleared"
    Write-Info "  Disk space freed: $(Get-HumanReadableSize $global:TotalBytesCleared)"
    
    # Additional breakdown if significant cleanup occurred
    if ($global:TotalBytesCleared -gt 10MB) {  # > 10MB
        Write-Success "  🚀 Significant cleanup completed - freed $(Get-HumanReadableSize $global:TotalBytesCleared)!"
    } elseif ($global:TotalBytesCleared -gt 1MB) {  # > 1MB
        Write-Info "  ✨ Good cleanup - freed $(Get-HumanReadableSize $global:TotalBytesCleared)"
    }
} else {
    Write-Info "📊 No files were removed (everything was already clean)"
}

if ($DryRun) {
    Write-Warning "This was a DRY RUN - no files were actually removed."
    Write-Info "Run without -DryRun to perform actual cleanup."
}

Write-Info ""
Write-Info "💡 Tips:"
Write-Info "  - Use -DryRun to preview what will be cleaned"
Write-Info "  - Use specific flags (-Build, -Python, etc.) for targeted cleanup"
Write-Info "  - Use -Force to skip confirmation prompts"
Write-Info ""

# Return to original directory
Set-Location $ProjectRoot
