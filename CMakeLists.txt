# Tiger Style CMake Configuration for Dashcam Project
# =================================================
# This is the root CMakeLists.txt file for the Dashcam project.
# It configures the build system with modern CMake practices, integrates
# Conan for dependency management, and sets up protobuf/gRPC code generation.
#
# Key Features:
# - Cross-platform support (Windows, Linux, macOS)
# - Modern C++17 standard with Tiger Style safety practices
# - Conan-based dependency management
# - Automatic protobuf/gRPC code generation
# - Comprehensive compiler warnings and sanitizers for debug builds
# - Optimized release builds for production

# CMake Version Requirement
# -------------------------
# We require CMake 3.20+ for:
# - Modern target-based configuration
# - Improved Conan integration
# - Better generator expression support
# - Cross-platform toolchain handling
cmake_minimum_required(VERSION 3.20)

# Project Declaration
# ------------------
# Defines project metadata and enabled languages.
# The project name affects various CMake variables and target names.
project(dashcam
    VERSION 1.0.0
    DESCRIPTION "Homemade Dash Cam System"
    LANGUAGES CXX  # Only C++ is used in this project
)

# C++ Standard Configuration
# -------------------------
# Tiger Style uses C++17 for the balance of modern features and compatibility:
# - std::optional, std::variant for safer code
# - structured bindings for cleaner code
# - filesystem library for cross-platform file operations
# - parallel algorithms for performance
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)  # Fail if C++17 is not available
set(CMAKE_CXX_EXTENSIONS OFF)        # Use standard C++, not compiler extensions

# Build Type Configuration
# ------------------------
# Set default build type to Debug for development convenience.
# Debug builds include symbols, assertions, and sanitizers for Tiger Style safety.
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

# Compiler-Specific Configuration
# -------------------------------
# Configure compiler flags for different toolchains with Tiger Style emphasis on:
# - Maximum warning levels to catch potential issues early
# - Memory safety through sanitizers in debug builds  
# - Aggressive optimization in release builds for performance
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    # GCC/Clang configuration for Linux, macOS, and MinGW on Windows
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic")
    
    # Debug build: prioritize debugging and safety
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0 -DDEBUG")
    # Memory safety sanitizers (Tiger Style safety-first approach)
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fsanitize=address -fsanitize=undefined")
    
    # Release build: prioritize performance
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    # Microsoft Visual C++ configuration for Windows
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")  # High warning level
    
    # Debug build: debugging symbols and no optimization
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /Od /Zi /DDEBUG")
    
    # Release build: full optimization
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /DNDEBUG")
endif()

# Platform-Specific Configuration
# -------------------------------
# Handle platform differences for optimal builds on each supported system.
# These settings ensure consistent behavior across Windows, Linux, and macOS.
if(WIN32)
    # Windows-specific definitions to reduce header bloat and avoid conflicts
    add_definitions(-DWIN32_LEAN_AND_MEAN)  # Exclude rarely-used Windows API parts
    add_definitions(-DNOMINMAX)             # Prevent min/max macro conflicts with std::min/max
elseif(UNIX AND NOT APPLE)
    # Linux-specific settings
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")  # Enable POSIX threading
elseif(APPLE)
    # macOS-specific settings  
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")  # Enable POSIX threading
endif()

# Package Configuration Discovery
# ------------------------------
# Find PkgConfig on Unix systems for system library discovery.
# This is primarily used for finding system libraries that may not have CMake support.
if(UNIX)
    find_package(PkgConfig REQUIRED)
endif()

# Conan Dependency Management
# --------------------------
# The project uses Conan for C++ package management, providing:
# - Consistent dependency versions across platforms
# - Binary package caching for faster builds
# - Automatic transitive dependency resolution
# - Cross-platform compatibility
#
# These packages are defined in conanfile.txt and installed during the build process.
# Each find_package() call loads Conan-generated CMake modules that define targets.

# Conan Integration
# ----------------
# Ensure CMake prioritizes Conan-generated config files over system find modules
list(PREPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_BINARY_DIR})
list(PREPEND CMAKE_PREFIX_PATH ${CMAKE_CURRENT_BINARY_DIR})

# Core Dependencies:
find_package(GTest REQUIRED)     # GoogleTest framework for unit testing
find_package(spdlog REQUIRED)    # High-performance logging library  
find_package(protobuf REQUIRED)  # Protocol buffer serialization (includes protoc compiler)
find_package(gRPC REQUIRED)      # gRPC framework for remote procedure calls

# gRPC C++ Plugin Detection
# -------------------------
# The gRPC C++ plugin (protoc-gen-grpc) is required to generate C++ service code
# from .proto files. Conan packages may provide this through different target names,
# so we try multiple possibilities and fall back to PATH search if needed.
if(TARGET gRPC::grpc_cpp_plugin)
    # Preferred Conan target name (newer packages)
    set(gRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:gRPC::grpc_cpp_plugin>)
    message(STATUS "Found gRPC C++ plugin: gRPC::grpc_cpp_plugin")
elseif(TARGET grpc_cpp_plugin)
    # Alternative Conan target name (some package versions)
    set(gRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:grpc_cpp_plugin>)
    message(STATUS "Found gRPC C++ plugin: grpc_cpp_plugin")
else()
    # Last resort: search system PATH for the plugin executable
    find_program(gRPC_CPP_PLUGIN_EXECUTABLE grpc_cpp_plugin)
    if(NOT gRPC_CPP_PLUGIN_EXECUTABLE)
        message(FATAL_ERROR "gRPC C++ plugin not found. Please ensure gRPC is properly installed.")
    endif()
    message(STATUS "Found gRPC C++ plugin: ${gRPC_CPP_PLUGIN_EXECUTABLE}")
endif()

# Protoc Compiler Configuration
# -----------------------------
# Set up the protocol buffer compiler for code generation.
# This generator expression resolves to the actual protoc executable path at build time.
set(PROTOBUF_PROTOC_EXECUTABLE $<TARGET_FILE:protobuf::protoc>)

# Protoc Executable Resolution for Custom Commands
# -----------------------------------------------
# CMake custom commands require the actual executable path, not generator expressions.
# This section resolves the protoc executable path from the Conan-provided target
# for use in custom commands that generate C++ code from .proto files.
#
# Challenge: Conan imported targets use complex property structures that vary
# between package versions and build configurations. We try multiple approaches
# to find the actual protoc executable path.

if(TARGET protobuf::protoc)
    # Method 1: Try to get the executable location from imported target properties
    # Different Conan packages may use different property names
    get_target_property(PROTOC_EXECUTABLE protobuf::protoc IMPORTED_LOCATION)
    if(NOT PROTOC_EXECUTABLE)
        # Try release-specific location
        get_target_property(PROTOC_EXECUTABLE protobuf::protoc IMPORTED_LOCATION_RELEASE)
    endif()
    if(NOT PROTOC_EXECUTABLE)
        # Try debug-specific location  
        get_target_property(PROTOC_EXECUTABLE protobuf::protoc IMPORTED_LOCATION_DEBUG)
    endif()
    
    # Method 2: Search in common Conan package locations
    # If target properties don't work, search known Conan directory structures
    if(NOT PROTOC_EXECUTABLE)
        find_program(PROTOC_EXECUTABLE 
            NAMES protoc protoc.exe
            PATHS 
                "${CONAN_PROTOBUF_ROOT}/bin"      # Conan package root
                "${CONAN_BIN_DIRS_PROTOBUF}"      # Conan binary directories
                "${CMAKE_BINARY_DIR}/bin"         # Build output directory
            NO_DEFAULT_PATH  # Don't search system PATH yet
        )
    endif()
endif()

# Method 3: System-wide search as fallback
# If Conan target resolution fails, search the system PATH
if(NOT PROTOC_EXECUTABLE)
    find_program(PROTOC_EXECUTABLE 
        NAMES protoc protoc.exe
        PATHS ENV PATH
    )
endif()

# Method 4: Use generator expression for build-time resolution
# This is the most robust approach - let CMake resolve the target at build time
# even if we can't determine the path during configuration
if(NOT PROTOC_EXECUTABLE AND TARGET protobuf::protoc)
    set(PROTOC_EXECUTABLE "$<TARGET_FILE:protobuf::protoc>")
    message(STATUS "Using protoc target: protobuf::protoc (path will be resolved at build time)")
else()
    if(PROTOC_EXECUTABLE)
        message(STATUS "Using protoc executable: ${PROTOC_EXECUTABLE}")
    else()
        message(FATAL_ERROR "Could not find protoc executable. Make sure protobuf is properly installed.")
    endif()
endif()

# Protobuf and gRPC Code Generation Pipeline
# ==========================================
# This section sets up automatic code generation from .proto files to C++ source code.
# The pipeline generates both protobuf message classes and gRPC service stubs.
set(PROTO_FILES
    ${CMAKE_SOURCE_DIR}/proto/dashcam.proto
)

# Create output directory for generated files
set(PROTO_OUTPUT_DIR ${CMAKE_BINARY_DIR}/generated)
file(MAKE_DIRECTORY ${PROTO_OUTPUT_DIR})

# Generate both protobuf and gRPC files using custom commands for consistency
set(PROTO_SRCS)
set(PROTO_HDRS)
set(GRPC_SRCS)
set(GRPC_HDRS)

foreach(PROTO_FILE ${PROTO_FILES})
    get_filename_component(PROTO_NAME ${PROTO_FILE} NAME_WE)
    
    # Define output file paths
    set(PROTO_SRC ${PROTO_OUTPUT_DIR}/${PROTO_NAME}.pb.cc)
    set(PROTO_HDR ${PROTO_OUTPUT_DIR}/${PROTO_NAME}.pb.h)
    set(GRPC_SRC ${PROTO_OUTPUT_DIR}/${PROTO_NAME}.grpc.pb.cc)
    set(GRPC_HDR ${PROTO_OUTPUT_DIR}/${PROTO_NAME}.grpc.pb.h)
    
    # Add to lists
    list(APPEND PROTO_SRCS ${PROTO_SRC})
    list(APPEND PROTO_HDRS ${PROTO_HDR})
    list(APPEND GRPC_SRCS ${GRPC_SRC})
    list(APPEND GRPC_HDRS ${GRPC_HDR})
    
    # Generate protobuf files
    add_custom_command(
        OUTPUT ${PROTO_SRC} ${PROTO_HDR}
        COMMAND ${PROTOC_EXECUTABLE}
        ARGS --cpp_out=${PROTO_OUTPUT_DIR}
             -I${CMAKE_SOURCE_DIR}/proto
             ${PROTO_FILE}
        DEPENDS ${PROTO_FILE}
        COMMENT "Generating protobuf files for ${PROTO_FILE}"
        VERBATIM
    )
    
    # Generate gRPC files
    add_custom_command(
        OUTPUT ${GRPC_SRC} ${GRPC_HDR}
        COMMAND ${PROTOC_EXECUTABLE}
        ARGS --grpc_out=${PROTO_OUTPUT_DIR}
             --plugin=protoc-gen-grpc=${gRPC_CPP_PLUGIN_EXECUTABLE}
             -I${CMAKE_SOURCE_DIR}/proto
             ${PROTO_FILE}
        DEPENDS ${PROTO_FILE}
        COMMENT "Generating gRPC files for ${PROTO_FILE}"
        VERBATIM
    )
endforeach()

# Create a target for generated files to ensure they are built before the library
add_custom_target(generate_protobuf_files 
    DEPENDS ${PROTO_SRCS} ${PROTO_HDRS} ${GRPC_SRCS} ${GRPC_HDRS}
    COMMENT "Generating all protobuf and gRPC files"
)

# Include the generated files directory
include_directories(${PROTO_OUTPUT_DIR})

# Include directories
include_directories(include)

# Enable testing
enable_testing()

# Add subdirectories
add_subdirectory(src)
add_subdirectory(tests)

# Export compile commands for clang tooling
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Installation
install(TARGETS dashcam_main
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(DIRECTORY include/
    DESTINATION include
    FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
)

# CPack configuration for packaging
set(CPACK_PACKAGE_NAME "dashcam")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
set(CPACK_PACKAGE_VENDOR "Your Name")
set(CPACK_PACKAGE_CONTACT "your.email@example.com")

if(WIN32)
    set(CPACK_GENERATOR "ZIP")
elseif(APPLE)
    set(CPACK_GENERATOR "DragNDrop")
else()
    set(CPACK_GENERATOR "TGZ")
endif()

include(CPack)
