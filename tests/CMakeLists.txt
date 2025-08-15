find_package(GTest REQUIRED)

# Unit tests
add_executable(unit_tests
    unit/test_logger.cpp
    unit/test_main.cpp
    unit/test_grpc_integration.cpp
)

target_include_directories(unit_tests PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(unit_tests
    dashcam_lib
    GTest::gtest
    GTest::gtest_main
)

# Enable GoogleTest discovery
include(GoogleTest)
gtest_discover_tests(unit_tests)

# System tests will be run via Python/pytest
# Create a custom target for system tests
add_custom_target(system_tests
    COMMAND python -m pytest ${CMAKE_SOURCE_DIR}/tests/system -v
    DEPENDS dashcam_main
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running system tests with pytest"
)
