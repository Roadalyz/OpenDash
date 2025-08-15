# Python Development with uv

This document explains how the Dashcam project uses [uv](https://github.com/astral-sh/uv), a fast Python package manager, to provide superior development experience compared to traditional pip-based workflows.

## Why uv?

### Performance Benefits

uv provides significant performance improvements over pip:

- **10-100x faster** package installation and resolution
- **Parallel downloads** and installations for maximum efficiency
- **Global package cache** eliminates redundant downloads
- **Faster dependency resolution** with intelligent conflict detection

### Developer Experience Improvements

- **Better error messages** with clear dependency conflict explanations
- **Lock files** (`uv.lock`) for reproducible builds across environments
- **Isolated tool installation** preventing dependency conflicts
- **Automatic virtual environment management**
- **Project-based dependency management** with `pyproject.toml`

### Real-world Performance Comparison

```bash
# Traditional pip approach
pip install pytest pytest-cov black flake8 mypy  # ~30-60 seconds

# uv approach  
uv sync --extra test --extra dev                 # ~2-5 seconds
```

## Project Structure

The Dashcam project is configured as a proper Python project with `pyproject.toml`:

```toml
[project]
name = "dashcam-project"
requires-python = ">=3.8.1"
dependencies = [
    "markdown>=3.4.0",
    "pygments>=2.15.0",
    "watchdog>=3.0.0",
]

[project.optional-dependencies]
test = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "pytest-html>=3.2.0",
]
docs = [
    "markdown>=3.4.0",
    "jinja2>=3.1.0",
]
dev = [
    "black>=23.0.0",
    "flake8>=6.0.0",
    "mypy>=1.5.0",
]
```

## Common Workflows

### Initial Setup

The setup scripts automatically handle uv installation and virtual environment creation:

```bash
# Linux/macOS
./scripts/setup.sh

# Windows
.\scripts\setup.ps1
```

### Working with Dependencies

```bash
# Install all project dependencies
uv sync

# Install with optional extras
uv sync --extra test --extra docs --extra dev

# Add a new dependency
uv add requests

# Add a development dependency
uv add --group dev black

# Remove a dependency
uv remove requests
```

### Running Commands

You can run Python commands either by activating the virtual environment or using `uv run`:

```bash
# Option 1: Activate virtual environment
source .venv/bin/activate  # Linux/macOS
.venv\Scripts\Activate.ps1  # Windows
python docs/serve_docs.py

# Option 2: Use uv run (recommended)
uv run python docs/serve_docs.py
uv run pytest
uv run black src/
```

### Tool Management

uv can install and manage Python tools globally without polluting your project environment:

```bash
# Install tools globally
uv tool install black
uv tool install pytest
uv tool install conan

# List installed tools
uv tool list

# Upgrade a tool
uv tool upgrade black

# Run a tool
uv tool run black --check .
```

## Virtual Environment Management

### Automatic Creation

uv automatically creates and manages virtual environments:

```bash
# Creates .venv/ if it doesn't exist
uv sync

# Explicitly create with specific Python version
uv venv --python 3.12
```

### Environment Information

```bash
# Show current environment
uv python list

# Show environment path
uv run python -c "import sys; print(sys.executable)"
```

## Lock Files and Reproducibility

uv generates `uv.lock` files for reproducible builds:

```bash
# Update lock file
uv lock

# Install exactly from lock file
uv sync --frozen

# Check if lock file is up to date
uv lock --check
```

**Note:** The `uv.lock` file should be committed to version control for reproducible builds across team members and CI/CD.

## Integration with IDEs

### VS Code

Configure VS Code to use the uv-managed virtual environment:

1. Open Command Palette (`Ctrl+Shift+P`)
2. Run "Python: Select Interpreter"
3. Choose `.venv/Scripts/python.exe` (Windows) or `.venv/bin/python` (Linux/macOS)

VS Code settings (`.vscode/settings.json`):
```json
{
    "python.defaultInterpreterPath": ".venv/bin/python",
    "python.terminal.activateEnvironment": true
}
```

### PyCharm

1. Go to Settings → Project → Python Interpreter
2. Click the gear icon → Add
3. Choose "Existing environment"
4. Point to `.venv/bin/python` or `.venv/Scripts/python.exe`

## Fallback to pip

All setup scripts include automatic fallback to pip if uv is unavailable:

```bash
# The setup scripts automatically detect uv availability
if command_exists uv; then
    echo "Using uv for fast package management"
    uv sync --extra test
else
    echo "Falling back to pip"
    pip install -r requirements.txt
fi
```

This ensures compatibility across all environments and CI systems.

## Troubleshooting

### Common Issues

**uv not found after installation:**
```bash
# Add to PATH
export PATH="$HOME/.cargo/bin:$PATH"  # Linux/macOS
$env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"  # Windows
```

**Permission errors on Windows:**
```bash
# Use --user flag or ensure proper permissions
uv tool install --user conan
```

**Lock file conflicts:**
```bash
# Regenerate lock file
rm uv.lock
uv lock
```

### Getting Help

```bash
# uv help system
uv --help
uv sync --help
uv tool --help

# Check uv version
uv --version

# Verbose output for debugging
uv sync --verbose
```

## Performance Monitoring

You can monitor uv's performance benefits:

```bash
# Time dependency installation
time uv sync --extra test  # Usually 2-5 seconds

# Compare with pip equivalent
time pip install -r requirements.txt  # Usually 30-60 seconds
```

This performance difference becomes even more pronounced in CI/CD environments where dependency installation happens frequently.

## Migration from pip

If you're migrating an existing project from pip to uv:

1. **Create pyproject.toml** from requirements.txt:
   ```bash
   uv init --python 3.12
   uv add $(cat requirements.txt)
   ```

2. **Migrate pip tools** to uv tools:
   ```bash
   uv tool install black
   uv tool install pytest
   uv tool install mypy
   ```

3. **Update CI/CD** to use uv:
   ```yaml
   - name: Install uv
     run: curl -LsSf https://astral.sh/uv/install.sh | sh
   
   - name: Install dependencies
     run: uv sync --extra test
   ```

The Dashcam project setup scripts handle this migration automatically, so you get the benefits of uv without manual migration work.
