#!/usr/bin/env pwsh

# Tiger Style: Always motivate, always say why
# This script runs all tests (unit and system) with proper reporting
# It provides clear feedback on test results and coverage

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $ProjectRoot "build"

Write-Host "Running dashcam test suite..." -ForegroundColor Cyan

# Check if build directory exists
if (-not (Test-Path $BuildDir)) {
    Write-Host "Error: Build directory not found. Please run '.\scripts\build.ps1' first" -ForegroundColor Red
    exit 1
}

# Check if executables exist
$UnitTestExec = Join-Path $BuildDir "tests\Debug\unit_tests.exe"
$MainExec = Join-Path $BuildDir "src\Debug\dashcam_main.exe"

if (-not (Test-Path $UnitTestExec)) {
    Write-Host "Error: Unit test executable not found. Please build the project first" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $MainExec)) {
    Write-Host "Error: Main executable not found. Please build the project first" -ForegroundColor Red
    exit 1
}

Set-Location $BuildDir

Write-Host "====================" -ForegroundColor Yellow
Write-Host "Running Unit Tests" -ForegroundColor Yellow
Write-Host "====================" -ForegroundColor Yellow

# Run unit tests with GoogleTest
$UnitTestResult = & $UnitTestExec --gtest_output=xml:unit_test_results.xml
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Unit tests PASSED" -ForegroundColor Green
    $UnitTestsPassed = $true
} else {
    Write-Host "❌ Unit tests FAILED" -ForegroundColor Red
    $UnitTestsPassed = $false
}

Write-Host ""

Write-Host "====================" -ForegroundColor Yellow
Write-Host "Running System Tests" -ForegroundColor Yellow
Write-Host "====================" -ForegroundColor Yellow

# Run system tests with pytest
Set-Location $ProjectRoot
if (Get-Command uv -ErrorAction SilentlyContinue) {
    $PytestResult = uv run pytest tests/system/ -v --tb=short --no-cov --junit-xml=build/system_test_results.xml
} else {
    $PytestResult = python -m pytest tests/system/ -v --tb=short --no-cov --junit-xml=build/system_test_results.xml
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ System tests PASSED" -ForegroundColor Green
    $SystemTestsPassed = $true
} else {
    Write-Host "❌ System tests FAILED" -ForegroundColor Red
    $SystemTestsPassed = $false
}

Write-Host ""
Write-Host "====================" -ForegroundColor Yellow
Write-Host "Test Results Summary" -ForegroundColor Yellow
Write-Host "====================" -ForegroundColor Yellow

if ($UnitTestsPassed -and $SystemTestsPassed) {
    Write-Host "🎉 ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Test reports generated:" -ForegroundColor Cyan
    Write-Host "  Unit tests: build/unit_test_results.xml" -ForegroundColor White
    Write-Host "  System tests: build/system_test_results.xml" -ForegroundColor White
    Set-Location $ProjectRoot
    exit 0
} else {
    Write-Host "💥 SOME TESTS FAILED!" -ForegroundColor Red
    Write-Host ""
    if (-not $UnitTestsPassed) {
        Write-Host "❌ Unit tests failed" -ForegroundColor Red
    }
    if (-not $SystemTestsPassed) {
        Write-Host "❌ System tests failed" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Check the test output above for details" -ForegroundColor Yellow
    exit 1
}

# Ensure we always return to project root
Set-Location $ProjectRoot
