# Debugging Guide

This guide covers debugging techniques for the dashcam project across different platforms and scenarios.

## Table of Contents

1. [Debug Builds](#debug-builds)
2. [Interactive Debugging](#interactive-debugging)
3. [Core Dump Analysis](#core-dump-analysis)
4. [Memory Debugging](#memory-debugging)
5. [Performance Debugging](#performance-debugging)
6. [Platform-Specific Notes](#platform-specific-notes)

## Debug Builds

Always use debug builds for development and debugging:

```bash
# Linux/macOS
./scripts/build.sh debug

# Windows
.\scripts\build.ps1 Debug
```

Debug builds include:
- Debug symbols (`-g`)
- No optimizations (`-O0`)
- AddressSanitizer and UndefinedBehaviorSanitizer
- All assertions enabled
- Debug logging enabled

## Interactive Debugging

### VS Code (Recommended)

1. **Install Extensions**:
   - C/C++ Extension Pack
   - CMake Tools

2. **Configure Launch Settings** (`.vscode/launch.json`):
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Dashcam",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/src/dashcam_main",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "/usr/bin/gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "build-debug"
        },
        {
            "name": "Debug Unit Tests",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/tests/unit_tests",
            "args": ["--gtest_break_on_failure"],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "/usr/bin/gdb"
        }
    ]
}
```

3. **Configure Build Tasks** (`.vscode/tasks.json`):
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "build-debug",
            "type": "shell",
            "command": "./scripts/build.sh",
            "args": ["debug"],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": "$gcc"
        }
    ]
}
```

4. **Setting Breakpoints**:
   - Click in the left margin next to line numbers
   - Use `F9` to toggle breakpoints
   - Conditional breakpoints: Right-click → "Conditional Breakpoint"

5. **Debugging Controls**:
   - `F5`: Start debugging
   - `F10`: Step over
   - `F11`: Step into
   - `Shift+F11`: Step out
   - `F5`: Continue

### GDB Command Line

For advanced debugging scenarios:

```bash
# Start with GDB
gdb build/src/dashcam_main

# Common GDB commands
(gdb) break main                    # Set breakpoint at main
(gdb) break logger.cpp:45           # Set breakpoint at specific line
(gdb) break Logger::initialize      # Set breakpoint at function
(gdb) run                          # Start execution
(gdb) continue                     # Continue execution
(gdb) step                         # Step into functions
(gdb) next                         # Step over functions
(gdb) print variable_name          # Print variable value
(gdb) backtrace                    # Show call stack
(gdb) info registers               # Show CPU registers
(gdb) disassemble                  # Show assembly code
```

### Visual Studio (Windows)

1. **Open Project**:
   - Open Visual Studio
   - File → Open → CMake → Select root CMakeLists.txt

2. **Set Build Configuration**:
   - Select "x64-Debug" configuration
   - Build → Build All

3. **Set Startup Project**:
   - Right-click on dashcam_main → Set as Startup Project

4. **Debugging**:
   - `F9`: Toggle breakpoint
   - `F5`: Start debugging
   - `F10`: Step over
   - `F11`: Step into

## Core Dump Analysis

### Enabling Core Dumps (Linux)

```bash
# Check current limit
ulimit -c

# Enable unlimited core dumps
ulimit -c unlimited

# Make permanent by adding to ~/.bashrc
echo "ulimit -c unlimited" >> ~/.bashrc

# Set core dump pattern (optional)
sudo sysctl -w kernel.core_pattern=/tmp/core.%e.%p.%t
```

### Analyzing Core Dumps

```bash
# If application crashes and produces core dump
gdb build/src/dashcam_main core.dashcam_main.12345.1234567890

# In GDB
(gdb) bt                           # Show backtrace at crash
(gdb) bt full                      # Show backtrace with local variables
(gdb) frame 3                      # Switch to frame 3
(gdb) print *this                  # Print object state
(gdb) info registers               # Show register state at crash
```

### Automated Core Dump Analysis

Create a script to automatically analyze crashes:

```bash
#!/bin/bash
# scripts/analyze_crash.sh

CORE_FILE="$1"
EXECUTABLE="$2"

if [ -z "$CORE_FILE" ] || [ -z "$EXECUTABLE" ]; then
    echo "Usage: $0 <core_file> <executable>"
    exit 1
fi

gdb -batch -ex "bt" -ex "bt full" -ex "info registers" -ex "quit" "$EXECUTABLE" "$CORE_FILE"
```

## Memory Debugging

### AddressSanitizer (ASan)

Enabled automatically in debug builds. To run with ASan:

```bash
# Build with ASan (automatic in debug builds)
./scripts/build.sh debug

# Run application
./build/src/dashcam_main

# ASan will detect and report:
# - Buffer overflows
# - Use-after-free
# - Memory leaks
# - Stack overflow
```

### Valgrind (Linux)

For additional memory checking:

```bash
# Install Valgrind
sudo apt install valgrind  # Ubuntu/Debian
sudo pacman -S valgrind    # Arch Linux

# Run with Valgrind
valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all \
         --track-origins=yes --verbose \
         ./build/src/dashcam_main

# For performance profiling
valgrind --tool=callgrind ./build/src/dashcam_main
```

### Memory Usage Monitoring

```bash
# Monitor memory usage during execution
./scripts/monitor_memory.sh &
./build/src/dashcam_main
```

Create `scripts/monitor_memory.sh`:
```bash
#!/bin/bash
while true; do
    if pgrep dashcam_main > /dev/null; then
        ps -o pid,ppid,%mem,%cpu,cmd -p $(pgrep dashcam_main)
    fi
    sleep 1
done
```

## Performance Debugging

### Built-in Profiling

Add timing code to critical sections:

```cpp
#include <chrono>

void performance_critical_function() {
    auto start = std::chrono::high_resolution_clock::now();
    
    // Your code here
    
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    LOG_DEBUG("Function took {} microseconds", duration.count());
}
```

### perf (Linux)

```bash
# Install perf
sudo apt install linux-tools-common linux-tools-generic

# Record performance data
sudo perf record -g ./build/src/dashcam_main

# Analyze results
sudo perf report

# Real-time monitoring
sudo perf top -p $(pgrep dashcam_main)
```

### Instruments (macOS)

1. Open Instruments app
2. Choose "Time Profiler" template
3. Select dashcam_main as target
4. Click Record

## Platform-Specific Notes

### Windows

1. **Visual Studio Debugger**:
   - Superior debugging experience on Windows
   - Integrated memory usage tools
   - IntelliTrace for historical debugging

2. **Application Verifier**:
   ```cmd
   # Enable heap checking
   gflags.exe /p /enable dashcam_main.exe
   ```

3. **Windows Performance Toolkit**:
   - WPA (Windows Performance Analyzer)
   - ETW (Event Tracing for Windows)

### macOS

1. **Xcode Debugger**:
   - Import CMake project
   - Use LLDB debugger

2. **dtrace**:
   ```bash
   # Monitor system calls
   sudo dtrace -n 'syscall:::entry /execname == "dashcam_main"/ { @[probefunc] = count(); }'
   ```

### Raspberry Pi

1. **Remote Debugging**:
   ```bash
   # On Pi: Start gdbserver
   gdbserver :1234 ./build/src/dashcam_main
   
   # On development machine: Connect
   gdb-multiarch build/src/dashcam_main
   (gdb) target remote pi_ip_address:1234
   ```

2. **Cross-compilation debugging**:
   - Use cross-compiled GDB
   - Ensure debug symbols are preserved

## Debugging Tips

### Assertion Debugging

Tiger Style emphasizes assertions. When an assertion fails:

1. **Note the assertion condition**
2. **Check the call stack** leading to the failure
3. **Examine variable states** at the assertion point
4. **Look for invariant violations** in the code path

### Logging for Debugging

Use different log levels strategically:

```cpp
LOG_TRACE("Entering function with param: {}", param);  // Function entry/exit
LOG_DEBUG("Processing frame {}", frame_id);            // Detailed flow
LOG_INFO("Camera initialized successfully");           // Major milestones
LOG_WARNING("Retrying operation: {}", retry_count);    // Recoverable issues
LOG_ERROR("Failed to open camera: {}", error_msg);     // Errors
LOG_CRITICAL("System shutdown required");              // Fatal conditions
```

### Race Condition Debugging

1. **Use ThreadSanitizer**:
   ```bash
   # Build with ThreadSanitizer
   cmake -DCMAKE_CXX_FLAGS="-fsanitize=thread" ..
   ```

2. **Add strategic logging**:
   ```cpp
   LOG_DEBUG("Thread {} acquiring lock", std::this_thread::get_id());
   ```

3. **Use `std::atomic` for debugging**:
   ```cpp
   std::atomic<int> debug_counter{0};
   LOG_DEBUG("Debug point reached {} times", ++debug_counter);
   ```

### Common Issues

1. **Segmentation Faults**:
   - Check for null pointer dereferences
   - Verify array bounds
   - Look for use-after-free

2. **Memory Leaks**:
   - Ensure RAII patterns
   - Check smart pointer usage
   - Verify resource cleanup

3. **Deadlocks**:
   - Check lock ordering
   - Use lock timeouts
   - Enable deadlock detection

4. **Performance Issues**:
   - Profile before optimizing
   - Check for excessive memory allocations
   - Look for blocking I/O in main thread

Remember: Tiger Style emphasizes testing both positive and negative cases. When debugging, consider not just what should work, but also what should fail gracefully.
