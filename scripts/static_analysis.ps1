# Static Analysis Script for Dashcam Project (Windows PowerShell)
# ================================================================
# This script runs comprehensive static analysis on the codebase using multiple tools.
# It follows Tiger Style principles for early bug detection and code quality assurance.

param(
    [switch]$ClangTidyOnly,
    [switch]$CppcheckOnly,
    [switch]$FormatOnly,
    [switch]$Fix,
    [switch]$ShowAll,
    [switch]$Verbose,
    [switch]$Help
)

# Error handling
$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "OpenDash Static Analysis Tool" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\static_analysis.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -ClangTidyOnly    Run only clang-tidy analysis"
    Write-Host "  -CppcheckOnly     Run only cppcheck analysis"
    Write-Host "  -FormatOnly       Run only format checking"
    Write-Host "  -Fix              Automatically fix issues where possible"
    Write-Host "  -ShowAll          Show all output including filtered system header errors"
    Write-Host "  -Verbose          Verbose output"
    Write-Host "  -Help             Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\static_analysis.ps1                    # Run all analysis tools"
    Write-Host "  .\static_analysis.ps1 -ClangTidyOnly     # Run only clang-tidy"
    Write-Host "  .\static_analysis.ps1 -Fix               # Run analysis and fix issues"
    Write-Host ""
    exit 0
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $ProjectRoot "build"

# Configuration
$RunClangTidy = $true
$RunCppcheck = $true
$RunClangFormatCheck = $true

if ($ClangTidyOnly) {
    $RunCppcheck = $false
    $RunClangFormatCheck = $false
}

if ($CppcheckOnly) {
    $RunClangTidy = $false
    $RunClangFormatCheck = $false
}

if ($FormatOnly) {
    $RunClangTidy = $false
    $RunCppcheck = $false
}

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

Write-Status "Starting static analysis for dashcam project..."
Write-Status "Project root: $ProjectRoot"

# Check if build directory exists
if (-not (Test-Path $BuildDir)) {
    Write-Error "Build directory not found. Please run .\scripts\build.ps1 first"
    exit 1
}

# Check for compile_commands.json
$CompileCommandsPath = Join-Path $BuildDir "compile_commands.json"
if (-not (Test-Path $CompileCommandsPath)) {
    Write-Warning "compile_commands.json not found. Building with CMAKE_EXPORT_COMPILE_COMMANDS=ON"
    Push-Location $BuildDir
    try {
        cmake $ProjectRoot -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    }
    finally {
        Pop-Location
    }
}

# Find source files
$SourceDirs = @(
    Join-Path $ProjectRoot "src",
    Join-Path $ProjectRoot "include", 
    Join-Path $ProjectRoot "tests"
)

$SourceFiles = @()
foreach ($dir in $SourceDirs) {
    if (Test-Path $dir) {
        $files = Get-ChildItem -Path $dir -Recurse -Include "*.cpp", "*.h", "*.hpp"
        $SourceFiles += $files.FullName
    }
}

if ($SourceFiles.Count -eq 0) {
    Write-Error "No source files found to analyze"
    exit 1
}

Write-Status "Found $($SourceFiles.Count) source files to analyze"

# Run clang-tidy
if ($RunClangTidy) {
    Write-Status "Running clang-tidy analysis..."
    
    if (-not (Test-Command "clang-tidy")) {
        Write-Warning "clang-tidy not found. Skipping clang-tidy analysis."
        Write-Warning "Install with: choco install llvm (requires Chocolatey) or download from LLVM website"
    }
    else {
        $ClangTidyArgs = @(
            "--config-file=$ProjectRoot\.clang-tidy",
            "-p=$BuildDir",
            "--header-filter=$($ProjectRoot.Replace('\', '\\'))\\(src|include|tests)\\.*"
        )
        
        if ($Fix) {
            $ClangTidyArgs += "--fix"
            Write-Status "clang-tidy will attempt to fix issues automatically"
        }
        
        if ($Verbose) {
            $ClangTidyArgs += "--explain-config"
        }
        
        # Run clang-tidy on all source files
        $ClangTidyExitCode = 0
        $SystemHeaderIssues = 0
        $RealIssues = 0
        $CleanFiles = 0
        
        foreach ($file in $SourceFiles) {
            if ($file -match '\.(cpp|h|hpp)$') {
                Write-Host "Analyzing: $file"
                
                # Capture output and filter out system header errors
                try {
                    $output = & clang-tidy @ClangTidyArgs $file 2>&1
                    $exitCode = $LASTEXITCODE
                }
                catch {
                    $output = $_.Exception.Message
                    $exitCode = 1
                }
                
                if ($exitCode -ne 0) {
                    if ($ShowAll) {
                        Write-Host "  🔍 Raw output (--show-all enabled):" -ForegroundColor Cyan
                        Write-Host $output
                        $ClangTidyExitCode = 1
                        $RealIssues++
                    }
                    elseif ($output -match "file not found" -and $output -match "(Availability\.h|atomic|cstddef)" -and $output -notmatch "warning:") {
                        # Only system header errors, no actual warnings
                        $missingHeader = [regex]::Match($output, "'[^']*' file not found").Value
                        Write-Host "  🔧 Filtered: clang-tidy can't find system header $missingHeader" -ForegroundColor Yellow
                        Write-Host "     → Use -ShowAll to see full error details" -ForegroundColor Yellow
                        $SystemHeaderIssues++
                    }
                    else {
                        # Extract and show real warnings/errors (not system header issues)
                        $realWarnings = $output -split "`n" | Where-Object { $_ -match "warning:|error:" -and $_ -notmatch "file not found" }
                        if ($realWarnings.Count -gt 0) {
                            Write-Host "  ⚠️  Found issues:" -ForegroundColor Yellow
                            foreach ($warning in $realWarnings) {
                                Write-Host $warning
                            }
                            $ClangTidyExitCode = 1
                            $RealIssues++
                        }
                        else {
                            # Only system header errors
                            $missingHeader = [regex]::Match($output, "'[^']*' file not found").Value
                            Write-Host "  🔧 Filtered: clang-tidy can't find system header $missingHeader" -ForegroundColor Yellow
                            Write-Host "     → Use -ShowAll to see full error details" -ForegroundColor Yellow
                            $SystemHeaderIssues++
                        }
                    }
                }
                else {
                    # Show non-error output if any (warnings, suggestions)
                    if ($output) {
                        Write-Host "  ⚠️  Found warnings/suggestions:" -ForegroundColor Yellow
                        Write-Host $output
                        $RealIssues++
                    }
                    else {
                        Write-Host "  ✅ Clean" -ForegroundColor Green
                        $CleanFiles++
                    }
                }
            }
        }
        
        # Summary of clang-tidy results
        Write-Host ""
        Write-Status "clang-tidy analysis summary:"
        Write-Host "  ✅ Clean files: $CleanFiles"
        if ($RealIssues -gt 0) {
            Write-Host "  ⚠️  Files with issues: $RealIssues"
        }
        if ($SystemHeaderIssues -gt 0) {
            Write-Host "  🔧 Files with filtered system header errors: $SystemHeaderIssues"
            Write-Host "     → Use '.\scripts\static_analysis.ps1 -ShowAll -ClangTidyOnly' to see raw errors"
        }
        
        if ($ClangTidyExitCode -eq 0) {
            Write-Success "clang-tidy analysis completed successfully"
        }
        else {
            Write-Warning "clang-tidy found issues that need attention"
        }
    }
}

# Run cppcheck
if ($RunCppcheck) {
    Write-Status "Running cppcheck analysis..."
    
    if (-not (Test-Command "cppcheck")) {
        Write-Warning "cppcheck not found. Skipping cppcheck analysis."
        Write-Warning "Install with: choco install cppcheck (requires Chocolatey) or download from cppcheck website"
    }
    else {
        $CppcheckArgs = @(
            "--enable=warning,style,performance,portability",
            "--inconclusive",
            "--force",
            "--inline-suppr",
            "--quiet",
            "--template='{file}:{line}: {severity}: {message} [{id}]'",
            "--suppress=missingInclude",
            "--suppress=missingIncludeSystem",
            "--suppress=unusedFunction",
            "--suppress=unmatchedSuppression",
            "--suppress=syntaxError:*/tests/*",
            "--suppress=missingInclude:*/grpc/*",
            "--suppress=functionStatic",
            "--suppress=normalCheckLevelMaxBranches",
            "-DTEST_F(x,y)=void",
            "-DTEST(x,y)=void",
            "-DEXPECT_EQ(x,y)=",
            "-DEXPECT_NE(x,y)=",
            "-DEXPECT_TRUE(x)=",
            "-DEXPECT_FALSE(x)=",
            "-DASSERT_EQ(x,y)=",
            "-DASSERT_NE(x,y)=",
            "-DASSERT_TRUE(x)=",
            "-DASSERT_FALSE(x)=",
            "-DASSERT_THAT(x,y)="
        )
        
        if ($Verbose) {
            $CppcheckArgs += "--verbose"
        }
        
        # Add source directories
        foreach ($dir in $SourceDirs) {
            if (Test-Path $dir) {
                $CppcheckArgs += $dir
            }
        }
        
        try {
            & cppcheck @CppcheckArgs
            Write-Success "cppcheck analysis completed successfully"
        }
        catch {
            Write-Warning "cppcheck found issues that need attention"
        }
    }
}

# Run clang-format check
if ($RunClangFormatCheck) {
    Write-Status "Checking code formatting..."
    
    if (-not (Test-Command "clang-format")) {
        Write-Warning "clang-format not found. Skipping format checking."
        Write-Warning "Install with: choco install llvm (requires Chocolatey) or download from LLVM website"
    }
    else {
        $FormatIssues = $false
        
        foreach ($file in $SourceFiles) {
            if ($file -match '\.(cpp|h|hpp)$') {
                try {
                    & clang-format --dry-run --Werror $file 2>$null
                }
                catch {
                    Write-Host "Format issue in: $file" -ForegroundColor Yellow
                    $FormatIssues = $true
                }
            }
        }
        
        if ($FormatIssues) {
            Write-Warning "Some files need formatting. Run '.\scripts\format.ps1' to fix them."
        }
        else {
            Write-Success "All files are properly formatted"
        }
    }
}

Write-Status "Static analysis complete!"

# Summary
Write-Host ""
Write-Host "=== ANALYSIS SUMMARY ===" -ForegroundColor Cyan
if ($RunClangTidy) {
    $clangTidyStatus = if (Test-Command "clang-tidy") { "run" } else { "skipped (not installed)" }
    Write-Host "✓ clang-tidy: $clangTidyStatus"
}
if ($RunCppcheck) {
    $cppcheckStatus = if (Test-Command "cppcheck") { "run" } else { "skipped (not installed)" }
    Write-Host "✓ cppcheck: $cppcheckStatus"
}
if ($RunClangFormatCheck) {
    $formatStatus = if (Test-Command "clang-format") { "run" } else { "skipped (not installed)" }
    Write-Host "✓ format check: $formatStatus"
}

Write-Host ""
Write-Success "Consider running this analysis regularly to maintain code quality!"
Write-Status "For CI/CD integration, add this script to your build pipeline."
