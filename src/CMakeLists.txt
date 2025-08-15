# Dashcam Source Library Configuration
# ===================================
# This CMakeLists.txt defines the main dashcam library and executable targets.
# It demonstrates modern CMake practices with:
# - Target-based configuration instead of global variables
# - Proper dependency management with Conan-provided packages
# - Integration of generated protobuf/gRPC sources
# - Platform-specific library linking

# Main Library Target Definition
# ------------------------------
# The dashcam_lib static library contains all core functionality:
# - Core components: camera, video, and storage management
# - Utility components: logging and configuration parsing  
# - gRPC service implementation for remote communication
# - Generated protobuf/gRPC code for message serialization
add_library(dashcam_lib
    # Core Components - Main application logic
    core/camera_manager.cpp      # Camera device management and configuration
    core/video_recorder.cpp      # Video encoding and file management
    core/storage_manager.cpp     # Storage allocation and cleanup
    
    # Utility Components - Supporting infrastructure
    utils/logger.cpp             # Tiger Style logging with spdlog integration
    utils/config_parser.cpp      # Configuration file parsing and validation
    
    # gRPC Service - Remote communication interface
    grpc/grpc_service.cpp        # gRPC service implementation
    
    # Generated Sources - Automatically created from .proto files
    ${PROTO_SRCS}                # Protobuf message implementations (.pb.cc files)
    ${GRPC_SRCS}                 # gRPC service stubs (.grpc.pb.cc files)
)

# Build Order Dependencies
# -----------------------
# Ensure protobuf/gRPC files are generated before compiling the library.
# This dependency is critical because the library source files include
# the generated headers, which must exist before compilation begins.
add_dependencies(dashcam_lib generate_protobuf_files)

# Include Directory Configuration
# ------------------------------
# Configure header search paths for the library and its consumers.
# PUBLIC means these directories are also available to targets that link to this library.
target_include_directories(dashcam_lib PUBLIC
    ${CMAKE_SOURCE_DIR}/include    # Project headers (public API)
    ${PROTO_OUTPUT_DIR}           # Generated protobuf/gRPC headers
)

# External Dependency Discovery
# -----------------------------
# Find Conan-provided packages. These packages were installed during the
# conan install step and provide CMake targets for linking.
find_package(spdlog REQUIRED)    # High-performance logging
find_package(fmt REQUIRED)       # String formatting (spdlog dependency)
find_package(Protobuf REQUIRED)  # Protocol buffer runtime
find_package(gRPC REQUIRED)      # gRPC runtime and C++ bindings

# Library Linking Configuration
# -----------------------------
# Link external libraries using modern CMake target-based approach.
# This automatically handles include directories, compiler flags, and transitive dependencies.
target_link_libraries(dashcam_lib
    # Logging Infrastructure
    spdlog::spdlog              # Main logging library
    fmt::fmt                    # String formatting used by spdlog
    
    # Protobuf/gRPC Runtime  
    protobuf::protobuf          # Protocol buffer runtime (message serialization)
    gRPC::grpc++                # gRPC C++ runtime (RPC framework)
    gRPC::grpc++_reflection     # gRPC reflection for dynamic service discovery
)

# Platform-Specific Library Dependencies
# --------------------------------------
# Link platform-specific system libraries required for networking and threading.
if(WIN32)
    # Windows: Winsock2 library for network operations
    target_link_libraries(dashcam_lib ws2_32)
elseif(UNIX)
    # Unix/Linux: POSIX threading library
    target_link_libraries(dashcam_lib pthread)
endif()

# Main Executable Target Definition
# ---------------------------------
# The dashcam_main executable provides the application entry point and
# command-line interface. It links to the dashcam_lib library to access
# all functionality while keeping the library reusable for testing.
add_executable(dashcam_main
    main.cpp                     # Application entry point and orchestration
)

# Executable Library Dependencies
# -------------------------------
# Link the main library which provides all functionality.
# The library automatically brings in all its dependencies (protobuf, gRPC, spdlog, etc.)
# through CMake's transitive dependency system.
target_link_libraries(dashcam_main dashcam_lib)
