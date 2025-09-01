# Tiger Style: Always motivate, always say why
# This script builds the dashcam project on Windows with proper error checking
# and support for both debug and release configurations

param(
    [string]$BuildType = "Debug",
    [int]$Jobs = 0,
    [switch]$ClangTidy,
    [switch]$Cppcheck,
    [switch]$StaticAnalysis,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\build.ps1 [Debug|Release] [OPTIONS]"
    Write-Host ""
    Write-Host "Arguments:"
    Write-Host "  BuildType         Build type: Debug or Release (default: Debug)"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Jobs NUM         Number of parallel jobs (default: auto-detect)"
    Write-Host "  -ClangTidy        Enable clang-tidy static analysis"
    Write-Host "  -Cppcheck         Enable cppcheck static analysis"
    Write-Host "  -StaticAnalysis   Enable all static analysis tools"
    Write-Host "  -Help             Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\build.ps1 Debug                    # Debug build"
    Write-Host "  .\build.ps1 Release -ClangTidy       # Release build with clang-tidy"
    Write-Host "  .\build.ps1 Debug -StaticAnalysis    # Debug build with all static analysis"
    exit 0
}

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir
$BuildDir = "$ProjectRoot\build"

# Validate build type
if ($BuildType -notin @("Debug", "Release", "debug", "release")) {
    Write-Host "Error: Invalid build type '$BuildType'. Use 'Debug' or 'Release'"
    exit 1
}

# Normalize build type
$BuildType = (Get-Culture).TextInfo.ToTitleCase($BuildType.ToLower())

# Auto-detect number of jobs if not specified
if ($Jobs -eq 0) {
    $Jobs = $env:NUMBER_OF_PROCESSORS
    if (-not $Jobs) {
        $Jobs = 4  # Default fallback
    }
}

Write-Host "Building dashcam project..."
Write-Host "Build type: $BuildType"
Write-Host "Using $Jobs parallel jobs"
Write-Host "Project root: $ProjectRoot"
Write-Host "Build directory: $BuildDir"

# Create build directory if it doesn't exist
if (-not (Test-Path $BuildDir)) {
    Write-Host "Creating build directory..."
    New-Item -ItemType Directory -Path $BuildDir | Out-Null
}

Set-Location $BuildDir

# Install Conan dependencies
Write-Host "Installing Conan dependencies..."
& conan install $ProjectRoot --output-folder=. --build=missing --profile="$ProjectRoot\conanprofile" --settings=build_type=$BuildType

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Conan install failed"
    Set-Location $ProjectRoot
    exit 1
}

# Configure with CMake
Write-Host "Configuring with CMake..."
$CmakeArgs = @(
    "$ProjectRoot"
    "-DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake"
    "-DCMAKE_BUILD_TYPE=$BuildType"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
)

# Add static analysis options if enabled
if ($ClangTidy -or $StaticAnalysis) {
    $CmakeArgs += "-DENABLE_CLANG_TIDY=ON"
    Write-Host "Static analysis: clang-tidy enabled"
}

if ($Cppcheck -or $StaticAnalysis) {
    $CmakeArgs += "-DENABLE_CPPCHECK=ON"
    Write-Host "Static analysis: cppcheck enabled"
}

& cmake @CmakeArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: CMake configuration failed"
    Set-Location $ProjectRoot
    exit 1
}

# Build
Write-Host "Building..."
& cmake --build . --parallel $Jobs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed"
    Set-Location $ProjectRoot
    exit 1
}

# Generate compile_commands.json for language servers
if (Test-Path "compile_commands.json") {
    Copy-Item "compile_commands.json" $ProjectRoot
}

Write-Host ""
Write-Host "Build completed successfully!"
Write-Host "Build type: $BuildType"
Write-Host "Executable: $BuildDir\src\dashcam_main.exe"
Write-Host "Unit tests: $BuildDir\tests\unit_tests.exe"
Write-Host ""

# Provide next steps
if ($BuildType -eq "Debug") {
    Write-Host "Debug build includes:"
    Write-Host "- Debug symbols for debugging"
    Write-Host "- AddressSanitizer and UndefinedBehaviorSanitizer (if supported)"
    Write-Host "- Assertions enabled"
    Write-Host ""
    Write-Host "To run with debugging:"
    Write-Host "  Visual Studio: Open solution and debug"
    Write-Host "  VS Code: Use C++ debugging configuration"
    Write-Host ""
} else {
    Write-Host "Release build includes:"
    Write-Host "- Optimizations enabled"
    Write-Host "- Assertions disabled"
    Write-Host "- Suitable for production use"
    Write-Host ""
}

Write-Host "To run tests:"
Write-Host "  .\scripts\test.ps1"
Write-Host ""
Write-Host "To run the application:"
Write-Host "  $BuildDir\src\dashcam_main.exe"

# Return to project root for better developer experience
Set-Location $ProjectRoot
