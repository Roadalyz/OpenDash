# Dashcam Project

A homemade dash cam system built with C++ following Tiger Style programming principles. Designed for multi-platform deployment with robust logging, testing infrastructure, and Docker support.

## Features

- 🎥 **Multi-platform video recording** - Windows, macOS, Linux, Raspberry Pi
- 📝 **Robust logging system** - Configurable loggers with multiple output formats
- 🧪 **Comprehensive testing** - Unit tests (GoogleTest) and system tests (pytest)
- 🐳 **Docker support** - Containerized deployment and development
- 🔧 **Modern C++17** - Following Tiger Style safety and performance principles
- 📦 **Conan package management** - Easy dependency management
- 🛠️ **CMake build system** - Cross-platform build configuration

## Quick Start

### Prerequisites

- C++17 compatible compiler (GCC 9+, Clang 10+, MSVC 2019+)
- CMake 3.20 or later
- Python 3.8.1 or later
- Git

### Setup Development Environment

Our setup scripts automatically install [uv](https://github.com/astral-sh/uv), a fast Python package manager that provides 10-100x faster package installation than pip, plus better dependency resolution and virtual environment management.

#### Linux/macOS
```bash
# Clone the repository
git clone <repository-url>
cd dashcam

# Run setup script (installs uv, Conan, and creates virtual environment)
chmod +x scripts/setup.sh
./scripts/setup.sh

# Activate Python virtual environment (optional)
source .venv/bin/activate

# Build the project
./scripts/build.sh debug

# Run tests
./scripts/test.sh
```

#### Windows
```powershell
# Clone the repository
git clone <repository-url>
cd dashcam

# Run setup script (installs uv, Conan, and creates virtual environment)
.\scripts\setup.ps1

# Activate Python virtual environment (optional)
.venv\Scripts\Activate.ps1

# Build the project
.\scripts\build.ps1 Debug

# Run tests
.\scripts\test.ps1
```

### Python Virtual Environment

The setup script creates a virtual environment in `.venv/` with all required dependencies. You can either:

1. **Activate the environment** (traditional approach):
   ```bash
   # Linux/macOS
   source .venv/bin/activate
   
   # Windows
   .venv\Scripts\Activate.ps1
   ```

2. **Use uv to run commands** (modern approach):
   ```bash
   # Run Python scripts
   uv run python docs/serve_docs.py
   
   # Run tests
   uv run pytest
   
   # Install additional packages
   uv add package-name
   ```

### Docker Development

```bash
# Build Docker image
./scripts/docker_build.sh

# Run in container
./scripts/docker_run.sh --rm

# Or use Docker Compose
cd docker
docker-compose up
```

## Project Structure

```
dashcam/
├── src/                    # Source code
│   ├── main.cpp           # Application entry point
│   ├── core/              # Core dashcam functionality
│   └── utils/             # Utility classes (logger, config)
├── include/dashcam/       # Public headers
├── tests/                 # Test suite
│   ├── unit/              # Unit tests (GoogleTest)
│   └── system/            # System tests (pytest)
├── scripts/               # Build and utility scripts
├── docker/                # Docker configuration
├── docs/                  # Documentation
└── CMakeLists.txt         # Build configuration
```

## Development Tools

### Python Package Management with uv

This project uses [uv](https://github.com/astral-sh/uv) for Python package management, which provides significant advantages over traditional pip:

**Performance Benefits:**
- 🚀 **10-100x faster** package installation and resolution
- ⚡ **Parallel downloads** and installations
- 🔄 **Efficient caching** with global package cache

**Developer Experience:**
- 🎯 **Better dependency resolution** with clear conflict reporting
- 🔒 **Lock files** for reproducible builds (`uv.lock`)
- 🛡️ **Isolated tool installation** with `uv tool install`
- 🐍 **Automatic virtual environment management**

**Key Commands:**
```bash
# Install project dependencies
uv sync --extra test --extra docs

# Add a new dependency
uv add package-name

# Install development tools globally
uv tool install black

# Run commands in virtual environment
uv run python script.py
uv run pytest
```

**Fallback Support:** All scripts include automatic fallback to `pip` if `uv` is unavailable, ensuring compatibility across all environments.

## Building

### Debug Build (Development)
```bash
./scripts/build.sh debug
```
- Includes debug symbols
- Enables AddressSanitizer and UndefinedBehaviorSanitizer
- Assertions enabled
- Optimizations disabled

### Release Build (Production)
```bash
./scripts/build.sh release
```
- Optimizations enabled (-O3)
- Assertions disabled
- Minimal binary size
- Production ready

### Build System Documentation

The project uses a sophisticated CMake build system with protobuf/gRPC integration. For detailed information:

📖 **[CMake Build System Guide](docs/development/cmake_guide.md)**
- Complete CMake architecture overview
- Dependency management with Conan
- Protobuf/gRPC generation pipeline
- Advanced configuration options
- Troubleshooting common issues

📖 **[Build Process Guide](docs/development/build_process.md)**
- Step-by-step build walkthrough
- Performance optimization tips
- Build variant configuration
- Error diagnosis and resolution
- Build monitoring and metrics

📖 **[CMake Architecture Summary](docs/development/cmake_architecture.md)**
- High-level system design
- Target definitions and dependencies
- Cross-platform considerations
- Modern CMake best practices
- Customization points

Key build system features:
- **Automatic Code Generation**: Protocol buffer and gRPC code generation from `.proto` files
- **Cross-Platform Support**: Windows (MSVC/MinGW), Linux (GCC/Clang), macOS (Xcode/Homebrew)
- **Tiger Style Safety**: Memory sanitizers, comprehensive warnings, assertions in debug builds
- **Modern CMake**: Target-based configuration with proper dependency propagation
- **Conan Integration**: Professional C++ package management with binary caching

## Testing

The project includes comprehensive testing at multiple levels:

### Unit Tests
- Framework: GoogleTest
- Location: `tests/unit/`
- Run: `./scripts/test.sh` or directly `build/tests/unit_tests`

### System Tests  
- Framework: pytest
- Location: `tests/system/`
- Tests the complete application behavior
- Includes integration testing

### Running All Tests
```bash
./scripts/test.sh
```

## Logging

The dashcam includes a robust logging system with the following features:

- **Multiple log levels**: Trace, Debug, Info, Warning, Error, Critical
- **Configurable outputs**: Console, file, rotating files
- **Thread-safe operation**
- **High performance with level filtering**

### Example Usage

```cpp
#include "dashcam/utils/logger.h"

// Initialize logging system
dashcam::Logger::initialize(dashcam::LogLevel::Info);

// Use default logger
LOG_INFO("Application started");
LOG_ERROR("Error occurred: {}", error_message);

// Create custom logger
dashcam::LoggerConfig config;
config.name = "camera";
config.level = dashcam::LogLevel::Debug;
config.file_path = "logs/camera.log";

auto camera_logger = dashcam::Logger::create_logger(config);
camera_logger->debug("Camera initialized with resolution {}x{}", width, height);
```

## Platform Support

### Tested Platforms
- **Windows 10/11** - MSVC 2019+, MinGW
- **macOS** - Clang 10+
- **Ubuntu 20.04+** - GCC 9+
- **Arch Linux** - Latest GCC/Clang
- **Raspberry Pi OS** - ARM builds

### Cross-Compilation
The project supports cross-compilation using CMake toolchain files and Docker for consistent builds across platforms.

## Dependencies

Managed through Conan package manager:

- **spdlog** - High-performance logging library
- **GoogleTest** - Unit testing framework  
- **fmt** - String formatting library
- **protobuf** - Protocol buffers (planned)
- **gRPC** - RPC framework (planned)

## Contributing

1. **Follow Tiger Style** - See `docs/tiger_style_cpp.md`
2. **Write tests first** - All new functionality requires tests
3. **Use static analysis** - Enable all compiler warnings
4. **Document your code** - Include Doxygen comments for public APIs

### Code Style
- Use `clang-format` with provided configuration
- Follow Tiger Style principles for safety and performance
- Maximum function length: 70 lines
- Prefer const-correctness and RAII

## Debugging

See `docs/debugging.md` for comprehensive debugging guide including:
- Setting breakpoints in VS Code and Visual Studio
- Core dump analysis
- Memory debugging with sanitizers
- Performance profiling

## License

[Specify your license here]

## Roadmap

- [ ] Camera interface implementation
- [ ] Video encoding (H.264/H.265)
- [ ] Motion detection
- [ ] Web interface for configuration
- [ ] GPS tracking integration
- [ ] Cloud storage integration
- [ ] Real-time streaming

## Support

For issues and questions:
1. Check existing GitHub issues
2. Create a new issue with:
   - Platform information
   - Build configuration
   - Reproduction steps
   - Log output
