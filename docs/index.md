# Dashcam Project Documentation

Welcome to the comprehensive documentation for the Tiger Style C++ Dashcam project. This documentation is designed to provide clear guidance, design rationale, and practical examples for developers, maintainers, and users.

## 🎯 Project Overview

The Dashcam project is a modern C++ application built following **Tiger Style** programming principles, emphasizing safety, performance, and developer experience. This project demonstrates professional-grade software engineering practices suitable for embedded systems and real-time applications.

```mermaid
graph TB
    A[Dashcam Application] --> B[Core Components]
    A --> C[Utility Components]
    A --> D[External Dependencies]
    
    B --> B1[Camera Manager]
    B --> B2[Video Recorder]
    B --> B3[Storage Manager]
    
    C --> C1[Logger System]
    C --> C2[Config Parser]
    C --> C3[Error Handling]
    
    D --> D1[spdlog]
    D --> D2[GoogleTest]
    D --> D3[fmt]
    D --> D4[Conan]
    
    style A fill:#2563eb,stroke:#1e40af,stroke-width:3px,color:#fff
    style B fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style C fill:#8b5cf6,stroke:#7c3aed,stroke-width:2px,color:#fff
    style D fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
```

## 🏗️ Architecture Philosophy

### Design Principles

The project architecture is built on Tiger Style principles adapted for C++:

1. **Safety First**: Memory safety through RAII, smart pointers, and comprehensive assertions
2. **Performance**: Cache-friendly data structures, minimal allocations, bounded operations
3. **Developer Experience**: Clear APIs, excellent tooling, comprehensive testing

```mermaid
flowchart LR
    Safety[Safety] --> |RAII, Assertions| Implementation
    Performance[Performance] --> |Zero-copy, Batching| Implementation
    DevExp[Developer Experience] --> |Clear APIs, Testing| Implementation
    
    Implementation --> |Results in| RobustSystem[Robust System]
    
    style Safety fill:#ef4444,stroke:#dc2626,stroke-width:2px,color:#fff
    style Performance fill:#22c55e,stroke:#16a34a,stroke-width:2px,color:#fff
    style DevExp fill:#3b82f6,stroke:#2563eb,stroke-width:2px,color:#fff
    style RobustSystem fill:#8b5cf6,stroke:#7c3aed,stroke-width:2px,color:#fff
```

### Key Design Decisions

| Decision | Rationale | Trade-offs |
|----------|-----------|------------|
| **C++17 Standard** | Modern features without bleeding edge complexity | Some newer features unavailable |
| **CMake Build System** | Cross-platform, industry standard, good tooling | Learning curve for beginners |
| **Conan Package Manager** | Reproducible builds, version management | Additional dependency |
| **spdlog for Logging** | High performance, thread-safe, feature-rich | Larger binary size |
| **GoogleTest Framework** | Industry standard, excellent tooling integration | Heavyweight for simple tests |
| **Docker Containerization** | Consistent environments, easy deployment | Additional complexity |

## 📁 Documentation Structure

This documentation is organized to mirror the project structure and development workflow:

### 🏠 Getting Started
- **[Architecture Overview](architecture/)** - High-level system design and component relationships
- **[Project Setup](development/setup.html)** - Environment setup and first build
- **[GitHub Actions Quick Start](guides/github-actions-quickstart.html)** - Get started with CI/CD (beginners)

### 📖 Developer Guides
- **[CMake Build System](development/cmake_guide.html)** - Complete CMake architecture and protobuf/gRPC integration
- **[CMake Architecture](development/cmake_architecture.html)** - High-level build system design and structure
- **[Build Process Guide](development/build_process.html)** - Step-by-step build walkthrough and troubleshooting
- **[Cleanup Guide](development/cleanup_guide.html)** - Comprehensive cleanup scripts for maintaining clean development environment
- **[Logging System](guides/logging.html)** - Comprehensive logging usage and configuration
- **[Testing Strategy](guides/testing.html)** - Unit and system testing approaches
- **[Python Development with uv](guides/python-uv.html)** - Fast Python package management
- **[GitHub Actions Documentation](deployment/github-actions.html)** - Complete CI/CD system documentation
- **[Debugging Guide](guides/debugging.html)** - Debugging tools and techniques
- **[Tiger Style Guide](guides/tiger_style.html)** - C++ coding standards and principles

### 🐳 Deployment
- **[Docker Setup](deployment/docker.html)** - Container development and deployment
- **[Production Deployment](deployment/production.html)** - Production configuration and monitoring
- **[Raspberry Pi Deployment](deployment/raspberry_pi.html)** - Embedded deployment guide

### 🔧 Development Tools
- **[Build Scripts](development/scripts.html)** - Automation scripts including build, test, and cleanup utilities
- **[Cleanup Guide](development/cleanup_guide.html)** - Environment cleanup and maintenance scripts
- **[VS Code Integration](development/vscode.html)** - IDE setup and debugging configuration
- **[Contributing Guide](development/contributing.html)** - Development workflow and standards

### 📚 API Reference
- **[Logger API](api/logger.html)** - Complete logging system API
- **[Core Components](api/core.html)** - Camera, recorder, and storage APIs
- **[Utilities](api/utils.html)** - Helper functions and utilities

## 🚀 Quick Start

### Prerequisites Check

Before starting, ensure you have the required tools:

```mermaid
flowchart TD
    Start([Start Development]) --> CheckOS{Operating System?}
    
    CheckOS -->|Windows| WinTools[Visual Studio 2019+<br/>CMake 3.20+<br/>Python 3.8+]
    CheckOS -->|macOS| MacTools[Xcode Command Line Tools<br/>CMake 3.20+<br/>Python 3.8+]
    CheckOS -->|Linux| LinuxTools[GCC 9+ or Clang 10+<br/>CMake 3.20+<br/>Python 3.8+]
    
    WinTools --> SetupEnv[Run setup.ps1]
    MacTools --> SetupEnv[Run setup.sh]
    LinuxTools --> SetupEnv[Run setup.sh]
    
    SetupEnv --> Build[Build Debug Version]
    Build --> Test[Run Tests]
    Test --> Ready[Ready for Development!]
    
    style Start fill:#22c55e,stroke:#16a34a,stroke-width:2px,color:#fff
    style Ready fill:#3b82f6,stroke:#2563eb,stroke-width:2px,color:#fff
```

### First Build

```bash
# 1. Setup environment
./scripts/setup.sh          # Linux/macOS
# or
.\scripts\setup.ps1          # Windows

# 2. Build debug version
./scripts/build.sh debug     # Linux/macOS
# or  
.\scripts\build.ps1 Debug    # Windows

# 3. Run tests
./scripts/test.sh            # Linux/macOS
# or
.\scripts\test.ps1           # Windows

# 4. Run application
./build/src/dashcam_main
```

## 🎯 Key Features

### Tiger Style Implementation

The project demonstrates Tiger Style principles in C++:

- **Bounded Operations**: All loops have fixed upper bounds
- **Explicit Error Handling**: No exceptions in critical paths
- **Assertion-Driven Development**: Comprehensive precondition/postcondition checking
- **70-Line Function Limit**: Enforced for maintainability
- **Static Memory Management**: Minimal dynamic allocation after initialization

### Robust Logging System

```mermaid
classDiagram
    class Logger {
        +initialize(level: LogLevel): bool
        +create_logger(config: LoggerConfig): shared_ptr~Logger~
        +get_logger(name: string): shared_ptr~Logger~
        +trace(message: string)
        +debug(message: string)
        +info(message: string)
        +warning(message: string)
        +error(message: string)
        +critical(message: string)
    }
    
    class LoggerConfig {
        +name: string
        +level: LogLevel
        +enable_console: bool
        +enable_file: bool
        +file_path: string
        +max_file_size_bytes: size_t
        +max_files: size_t
        +pattern: string
    }
    
    Logger --> LoggerConfig : uses
```

### Comprehensive Testing

The project includes multiple testing layers:

1. **Unit Tests** (GoogleTest) - Component isolation and functionality
2. **Integration Tests** - Component interaction testing  
3. **System Tests** (pytest) - End-to-end behavior validation
4. **Performance Tests** - Timing and resource usage validation

### Multi-Platform Support

```mermaid
graph LR
    SourceCode[Source Code] --> CMake[CMake Build System]
    CMake --> Windows[Windows Build]
    CMake --> macOS[macOS Build]
    CMake --> Linux[Linux Build]
    CMake --> RaspberryPi[Raspberry Pi Build]
    
    Windows --> Docker[Docker Container]
    macOS --> Docker
    Linux --> Docker
    RaspberryPi --> Docker
    
    style SourceCode fill:#8b5cf6,stroke:#7c3aed,stroke-width:2px,color:#fff
    style Docker fill:#0ea5e9,stroke:#0284c7,stroke-width:2px,color:#fff
```

## 🔧 Development Workflow

### Recommended Development Process

```mermaid
flowchart TD
    Clone[Clone Repository] --> Setup[Run Setup Script]
    Setup --> Feature[Create Feature Branch]
    Feature --> Develop[Write Code + Tests]
    Develop --> Build[Build Debug Version]
    Build --> LocalTest[Run Local Tests]
    LocalTest --> Debug[Debug Issues]
    Debug --> |Issues Found| Develop
    LocalTest --> |Tests Pass| Format[Format Code]
    Format --> Commit[Commit Changes]
    Commit --> Push[Push to Remote]
    Push --> CI[CI/CD Pipeline]
    CI --> Review[Code Review]
    Review --> |Approved| Merge[Merge to Main]
    
    style Clone fill:#22c55e,stroke:#16a34a,stroke-width:2px,color:#fff
    style Merge fill:#3b82f6,stroke:#2563eb,stroke-width:2px,color:#fff
```

## 📖 How to Use This Documentation

### For New Developers
1. Start with **[Project Setup](development/setup.html)** to get your environment ready
2. Read **[Architecture Overview](architecture/)** to understand the system design
3. Follow **[Building Guide](development/building.html)** for your first successful build
4. Explore **[Logging System](guides/logging.html)** to understand debugging tools

### For Contributors
1. Review **[Tiger Style Guide](guides/tiger_style.html)** for coding standards
2. Understand **[Testing Strategy](guides/testing.html)** for quality requirements
3. Use **[Contributing Guide](development/contributing.html)** for workflow
4. Reference **[API Documentation](api/)** for implementation details

### For Deployment Engineers
1. Study **[Docker Setup](deployment/docker.html)** for containerization
2. Follow **[Production Deployment](deployment/production.html)** for live systems
3. Use **[Raspberry Pi Guide](deployment/raspberry_pi.html)** for embedded deployment

## 🌟 Documentation Philosophy

This documentation follows these principles:

- **Justify Every Decision**: Design choices include rationale and trade-offs
- **Visual Learning**: Mermaid diagrams illustrate complex relationships
- **Practical Examples**: Real code samples demonstrate concepts
- **Progressive Disclosure**: Information is layered from basic to advanced
- **Searchable Content**: Well-structured for easy navigation and reference

## 🤝 Contributing to Documentation

Documentation is as important as code. When contributing:

1. **Update docs with code changes** - Documentation should never lag behind implementation
2. **Include design rationale** - Explain not just what, but why
3. **Add diagrams for complex concepts** - Use Mermaid for visual explanation
4. **Test documentation locally** - Use the documentation server to verify formatting
5. **Consider the audience** - Write for developers at different experience levels

---

*This documentation is served by a custom Python server with Mermaid diagram support. Start the server with `python docs/serve_docs.py` and navigate to `http://localhost:8080`*
