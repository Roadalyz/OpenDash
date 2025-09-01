# Simple code formatting script for OpenDash (Windows PowerShell)
# Usage: .\format.ps1 [-Check]

param(
    [switch]$Check,
    [switch]$Help
)

# Error handling
$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "OpenDash Code Formatter" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\format.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Check    Check formatting without modifying files (dry run)"
    Write-Host "  -Help     Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\format.ps1          # Format all C++ files"
    Write-Host "  .\format.ps1 -Check   # Check formatting without changes"
    Write-Host ""
    exit 0
}

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectRoot

# Function to print colored output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if clang-format is available
try {
    Get-Command clang-format -ErrorAction Stop | Out-Null
}
catch {
    Write-Error "clang-format not found. Please install it:"
    Write-Host "  Windows: choco install llvm (requires Chocolatey)"
    Write-Host "  Or download from: https://releases.llvm.org/"
    exit 1
}

# Parse arguments and show status
if ($Check) {
    Write-Info "Checking code formatting (dry run)..."
}
else {
    Write-Info "Formatting code..."
}

# Find all C++ source files
$Files = @()
$SourceDirs = @("src", "include", "tests")

foreach ($dir in $SourceDirs) {
    if (Test-Path $dir) {
        $Files += Get-ChildItem -Path $dir -Recurse -Include "*.cpp", "*.h", "*.hpp" | ForEach-Object { $_.FullName }
    }
}

if ($Files.Count -eq 0) {
    Write-Error "No C++ files found to format"
    exit 1
}

# Count files
$FileCount = $Files.Count
Write-Info "Found $FileCount C++ files"

if ($Check) {
    # Check formatting without modifying files
    $IssuesFound = $false
    foreach ($file in $Files) {
        try {
            & clang-format --dry-run --Werror $file 2>$null
        }
        catch {
            Write-Host "  ❌ $file needs formatting"
            $IssuesFound = $true
        }
    }
    
    if ($IssuesFound) {
        Write-Error "Some files need formatting. Run '.\scripts\format.ps1' to fix them."
        exit 1
    }
    else {
        Write-Success "All files are properly formatted!"
    }
}
else {
    # Apply formatting
    foreach ($file in $Files) {
        & clang-format -i $file
    }
    Write-Success "All $FileCount files formatted successfully!"
    Write-Info "Tip: Use '.\scripts\format.ps1 -Check' to verify formatting without changes"
}
