# Tiger Style: Always motivate, always say why
# This script sets up the development environment for the dashcam project on Windows
# It installs uv (fast Python package manager), Conan, and prepares the build environment
# Using uv provides significant speed improvements over pip and better dependency resolution

param(
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\setup.ps1"
    Write-Host ""
    Write-Host "This script sets up the dashcam development environment on Windows"
    Write-Host "It will install uv (fast Python package manager), Conan, and prepare the build environment"
    Write-Host ""
    Write-Host "Benefits of using uv:"
    Write-Host "- 10-100x faster than pip"
    Write-Host "- Better dependency resolution"
    Write-Host "- Built-in virtual environment management"
    Write-Host "- Lock file support for reproducible builds"
    exit 0
}

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "Setting up dashcam development environment on Windows..."
Write-Host "Project root: $ProjectRoot"

# Function to check if command exists
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Check for required tools
function Test-Dependencies {
    Write-Host "Checking dependencies..."
    
    # Check for Visual Studio or Build Tools
    $vsInstalled = $false
    if (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe") {
        $vsInfo = & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($vsInfo) {
            Write-Host "Found Visual Studio: $vsInfo"
            $vsInstalled = $true
        }
    }
    
    if (-not $vsInstalled) {
        Write-Host "Error: Visual Studio with C++ tools not found."
        Write-Host "Please install Visual Studio 2019 or later with C++ development tools"
        exit 1
    }
    
    # Check for CMake
    if (-not (Test-Command "cmake")) {
        Write-Host "Error: CMake not found. Please install CMake 3.20 or later"
        exit 1
    }
    
    # Check CMake version
    $cmakeVersion = & cmake --version | Select-String "version" | ForEach-Object { $_.ToString().Split()[2] }
    $versionParts = $cmakeVersion.Split('.')
    $major = [int]$versionParts[0]
    $minor = [int]$versionParts[1]
    
    if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 20)) {
        Write-Host "Error: CMake 3.20 or later required, found $cmakeVersion"
        exit 1
    }
    
    # Check for Python
    if (-not (Test-Command "python")) {
        Write-Host "Error: Python not found. Please install Python 3.8 or later"
        exit 1
    }
    
    Write-Host "All required dependencies found"
}

# Install uv package manager
function Install-Uv {
    if (-not (Test-Command "uv")) {
        Write-Host "Installing uv (fast Python package manager)..."
        
        # Install uv using the official installer
        $uvInstaller = "$env:TEMP\install-uv.ps1"
        try {
            Invoke-WebRequest -Uri "https://astral.sh/uv/install.ps1" -OutFile $uvInstaller
            & powershell -ExecutionPolicy Bypass -File $uvInstaller
            Remove-Item $uvInstaller -ErrorAction SilentlyContinue
            
            # Add uv to PATH for current session
            $uvPath = "$env:USERPROFILE\.cargo\bin"
            if (Test-Path $uvPath) {
                $env:PATH = "$uvPath;$env:PATH"
                Write-Host "Added uv to PATH: $uvPath"
            }
            
            # Verify installation
            if (-not (Test-Command "uv")) {
                Write-Host "Warning: uv installation may require a shell restart"
                Write-Host "Falling back to pip for this session..."
                return $false
            }
            
            Write-Host "✅ uv installed successfully"
            return $true
        } catch {
            Write-Host "Warning: Failed to install uv, falling back to pip"
            Write-Host "Error: $_"
            return $false
        }
    } else {
        Write-Host "✅ uv already installed"
        return $true
    }
}

# Install Conan package manager
function Install-Conan {
    param([bool]$UseUv = $true)
    
    if (-not (Test-Command "conan")) {
        Write-Host "Installing Conan package manager..."
        
        if ($UseUv) {
            & uv tool install conan
            
            # Add uv tools to PATH
            $uvToolsPath = "$env:USERPROFILE\.local\bin"
            if (Test-Path $uvToolsPath) {
                $env:PATH = "$uvToolsPath;$env:PATH"
                Write-Host "Added uv tools directory to PATH: $uvToolsPath"
            }
        } else {
            Write-Host "Using pip fallback..."
            & pip install --user conan
            
            # Add Python Scripts directory to PATH
            $pythonScriptsPath = "$env:APPDATA\..\Local\Packages\PythonSoftwareFoundation.Python.3.12_qbz5n2kfra8p0\LocalCache\local-packages\Python312\Scripts"
            if (Test-Path $pythonScriptsPath) {
                $env:PATH = "$pythonScriptsPath;$env:PATH"
                Write-Host "Added Python Scripts directory to PATH: $pythonScriptsPath"
            } else {
                # Fallback: try to find Python installation path
                $pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
                if ($pythonPath) {
                    $pythonDir = Split-Path -Parent $pythonPath
                    $scriptsDir = Join-Path $pythonDir "Scripts"
                    if (Test-Path $scriptsDir) {
                        $env:PATH = "$scriptsDir;$env:PATH"
                        Write-Host "Added Python Scripts directory to PATH: $scriptsDir"
                    }
                }
            }
        }
        
        # Refresh PATH from registry
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
        
        if (-not (Test-Command "conan")) {
            Write-Host "Error: Conan installation failed or not in PATH"
            if ($UseUv) {
                Write-Host "Manually add this directory to your PATH:"
                Write-Host "  $uvToolsPath"
            } else {
                Write-Host "Manually add this directory to your PATH:"
                Write-Host "  $pythonScriptsPath"
            }
            Write-Host "Then re-run this script"
            exit 1
        }
        
        Write-Host "✅ Conan installed successfully"
    } else {
        Write-Host "✅ Conan already installed"
    }
    
    # Create Conan profile if it doesn't exist
    $conanProfilePath = "$env:USERPROFILE\.conan2\profiles\default"
    if (-not (Test-Path $conanProfilePath)) {
        Write-Host "Creating Conan profile..."
        & conan profile detect --force
    }
}

# Install Python testing dependencies
function Install-PythonDependencies {
    param([bool]$UseUv = $true)
    
    Write-Host "Installing Python testing dependencies..."
    
    $requirementsFile = "$ProjectRoot\tests\system\requirements.txt"
    if (Test-Path $requirementsFile) {
        if ($UseUv) {
            # Use uv to create and sync virtual environment
            Write-Host "Using uv to create virtual environment and install dependencies..."
            
            # Create virtual environment in project
            & uv venv --python 3.12
            
            # Install project dependencies (including optional test dependencies)
            & uv sync --extra test --extra docs --extra dev
            
            # Also install system test requirements if they exist
            & uv pip install -r $requirementsFile
        } else {
            Write-Host "Using pip fallback..."
            & pip install --user -r $requirementsFile
        }
        Write-Host "✅ Python dependencies installed successfully"
    } else {
        if ($UseUv) {
            # Just create virtual environment and sync pyproject.toml dependencies
            Write-Host "Using uv to create virtual environment..."
            & uv venv --python 3.12
            & uv sync --extra test --extra docs --extra dev
            Write-Host "✅ Python virtual environment created and dependencies installed"
        } else {
            Write-Host "Warning: Requirements file not found at $requirementsFile"
        }
    }
}

# Create build directory
function New-BuildDirectory {
    $buildDir = "$ProjectRoot\build"
    if (-not (Test-Path $buildDir)) {
        Write-Host "Creating build directory..."
        New-Item -ItemType Directory -Path $buildDir | Out-Null
    }
}

# Main setup sequence
function Main {
    Test-Dependencies
    
    # Install uv for faster Python package management
    $uvAvailable = Install-Uv
    
    # Install tools using uv when available, fallback to pip
    Install-Conan -UseUv $uvAvailable
    Install-PythonDependencies -UseUv $uvAvailable
    New-BuildDirectory
    
    Write-Host ""
    Write-Host "✅ Development environment setup complete!"
    Write-Host ""
    if ($uvAvailable) {
        Write-Host "🚀 Using uv for fast Python package management"
        Write-Host ""
        Write-Host "🐍 Python virtual environment created in .venv/"
        Write-Host "   To activate: .venv\Scripts\Activate.ps1"
        Write-Host "   Or use: uv run <command> to run commands in the environment"
    } else {
        Write-Host "📦 Using pip for Python package management"
    }
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Run '.\scripts\build.ps1 debug' to build debug version"
    Write-Host "2. Run '.\scripts\build.ps1 release' to build release version"  
    Write-Host "3. Run '.\scripts\test.ps1' to run all tests"
    Write-Host ""
    Write-Host "For Python development:"
    Write-Host "1. Activate virtual environment: .venv\Scripts\Activate.ps1"
    Write-Host "2. Or use uv commands: uv run python <script>"
    Write-Host ""
    Write-Host "For Docker development:"
    Write-Host "1. Run '.\scripts\docker_build.ps1' to build Docker image"
    Write-Host "2. Run '.\scripts\docker_run.ps1' to run in container"
}

Main
