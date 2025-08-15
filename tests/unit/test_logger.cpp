#include <gtest/gtest.h>
#include "dashcam/utils/logger.h"
#include <filesystem>
#include <fstream>

namespace dashcam {
namespace test {

class LoggerTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Clean up any existing logs
        if (std::filesystem::exists("logs")) {
            std::filesystem::remove_all("logs");
        }
        
        // Initialize logger system for each test
        ASSERT_TRUE(Logger::initialize(LogLevel::Debug));
    }

    void TearDown() override {
        Logger::shutdown();
        
        // Clean up test logs
        if (std::filesystem::exists("logs")) {
            std::filesystem::remove_all("logs");
        }
    }
};

TEST_F(LoggerTest, InitializeSucceeds) {
    // Logger should be initialized in SetUp
    auto default_logger = Logger::get_default();
    ASSERT_NE(default_logger, nullptr);
    EXPECT_EQ(default_logger->get_name(), "default");
}

TEST_F(LoggerTest, CreateCustomLogger) {
    LoggerConfig config;
    config.name = "test_logger";
    config.level = LogLevel::Warning;
    config.enable_console = true;
    config.enable_file = false;

    auto logger = Logger::create_logger(config);
    ASSERT_NE(logger, nullptr);
    EXPECT_EQ(logger->get_name(), "test_logger");
    EXPECT_EQ(logger->get_level(), LogLevel::Warning);
}

TEST_F(LoggerTest, GetExistingLogger) {
    LoggerConfig config;
    config.name = "existing_logger";
    config.level = LogLevel::Info;

    auto logger1 = Logger::create_logger(config);
    ASSERT_NE(logger1, nullptr);

    auto logger2 = Logger::get_logger("existing_logger");
    ASSERT_NE(logger2, nullptr);
    EXPECT_EQ(logger1, logger2); // Should be the same instance
}

TEST_F(LoggerTest, GetNonExistentLogger) {
    auto logger = Logger::get_logger("non_existent");
    EXPECT_EQ(logger, nullptr);
}

TEST_F(LoggerTest, LoggingMethods) {
    auto logger = Logger::get_default();
    ASSERT_NE(logger, nullptr);

    // These should not crash
    logger->trace("Trace message");
    logger->debug("Debug message");
    logger->info("Info message");
    logger->warning("Warning message");
    logger->error("Error message");
    logger->critical("Critical message");
}

TEST_F(LoggerTest, FormattedLogging) {
    auto logger = Logger::get_default();
    ASSERT_NE(logger, nullptr);

    // These should not crash
    logger->info("Formatted message with number: {}", 42);
    logger->debug("Multiple args: {} and {}", "hello", 3.14);
}

TEST_F(LoggerTest, LogLevelFiltering) {
    LoggerConfig config;
    config.name = "level_test";
    config.level = LogLevel::Warning; // Only warning and above
    config.enable_console = false;   // Disable console for cleaner test
    config.enable_file = true;
    config.file_path = "logs/level_test.log";

    auto logger = Logger::create_logger(config);
    ASSERT_NE(logger, nullptr);

    // Log at different levels
    logger->debug("This should not appear");
    logger->info("This should not appear");
    logger->warning("This should appear");
    logger->error("This should appear");

    // Flush to ensure file is written
    Logger::shutdown();
    Logger::initialize(LogLevel::Debug);

    // Check that file exists and contains expected messages
    ASSERT_TRUE(std::filesystem::exists("logs/level_test.log"));
    
    std::ifstream file("logs/level_test.log");
    std::string content((std::istreambuf_iterator<char>(file)),
                        std::istreambuf_iterator<char>());
    
    EXPECT_EQ(content.find("This should not appear"), std::string::npos);
    EXPECT_NE(content.find("This should appear"), std::string::npos);
}

TEST_F(LoggerTest, MacroLogging) {
    // These should not crash
    LOG_TRACE("Trace via macro");
    LOG_DEBUG("Debug via macro");
    LOG_INFO("Info via macro");
    LOG_WARNING("Warning via macro");
    LOG_ERROR("Error via macro");
    LOG_CRITICAL("Critical via macro");
}

TEST_F(LoggerTest, CreateLoggerWithoutInitialization) {
    Logger::shutdown(); // Shutdown the logger system
    
    LoggerConfig config;
    config.name = "test";
    config.level = LogLevel::Info;

    // This should fail because system is not initialized
    auto logger = Logger::create_logger(config);
    EXPECT_EQ(logger, nullptr);
}

} // namespace test
} // namespace dashcam
