#pragma once

#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/rotating_file_sink.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/spdlog.h>

#include <memory>
#include <string>
#include <string_view>
#include <unordered_map>

namespace dashcam
{

/**
 * @brief Log levels matching spdlog levels
 */
enum class LogLevel : uint8_t
{
    Trace = 0,
    Debug = 1,
    Info = 2,
    Warning = 3,
    Error = 4,
    Critical = 5,
    Off = 6
};

/**
 * @brief Configuration for a logger instance
 */
struct LoggerConfig
{
    // Default configuration constants
    static constexpr size_t DEFAULT_MAX_FILE_SIZE_MB = 10;
    static constexpr size_t BYTES_PER_KB = 1024;
    static constexpr size_t BYTES_PER_MB = BYTES_PER_KB * BYTES_PER_KB;
    static constexpr size_t DEFAULT_MAX_FILES = 5;
    
    std::string name;
    LogLevel level = LogLevel::Info;
    bool enable_console = true;
    bool enable_file = false;
    std::string file_path;
    size_t max_file_size_bytes = DEFAULT_MAX_FILE_SIZE_MB * BYTES_PER_MB;
    size_t max_files = DEFAULT_MAX_FILES;
    std::string pattern = "[%Y-%m-%d %H:%M:%S.%e] [%n] [%l] %v";
};

/**
 * @brief Logger wrapper providing Tiger Style safety and convenience
 */
class Logger
{
  public:
    /**
     * @brief Initialize the global logging system
     *
     * @param default_level Default log level for all loggers
     * @return true if initialization successful, false otherwise
     */
    static bool initialize(LogLevel default_level = LogLevel::Info);

    /**
     * @brief Create or get a logger with the specified configuration
     *
     * @param config Logger configuration
     * @return Shared pointer to the logger, nullptr on failure
     *
     * @pre initialize() must have been called successfully
     * @pre config.name must not be empty
     */
    static std::shared_ptr<Logger> create_logger(const LoggerConfig& config);

    /**
     * @brief Get an existing logger by name
     *
     * @param name Name of the logger
     * @return Shared pointer to the logger, nullptr if not found
     */
    static std::shared_ptr<Logger> get_logger(std::string_view name);

    /**
     * @brief Get the default logger
     *
     * @return Shared pointer to the default logger
     */
    static std::shared_ptr<Logger> get_default();

    /**
     * @brief Shutdown all loggers and flush pending messages
     */
    static void shutdown();

    // Logging methods
    void trace(std::string_view message) const;
    void debug(std::string_view message) const;
    void info(std::string_view message) const;
    void warning(std::string_view message) const;
    void error(std::string_view message) const;
    void critical(std::string_view message) const;

    /**
     * @brief Force flush all pending log messages to sinks
     */
    void flush() const;

    // Template methods for formatted logging
    template <typename... Args>
    void trace(std::string_view format, Args&&... args) const
    {
        if (should_log(LogLevel::Trace))
        {
            logger_->trace(format, std::forward<Args>(args)...);
        }
    }

    template <typename... Args>
    void debug(std::string_view format, Args&&... args) const
    {
        if (should_log(LogLevel::Debug))
        {
            logger_->debug(format, std::forward<Args>(args)...);
        }
    }

    template <typename... Args>
    void info(std::string_view format, Args&&... args) const
    {
        if (should_log(LogLevel::Info))
        {
            logger_->info(format, std::forward<Args>(args)...);
        }
    }

    template <typename... Args>
    void warning(std::string_view format, Args&&... args) const
    {
        if (should_log(LogLevel::Warning))
        {
            logger_->warn(format, std::forward<Args>(args)...);
        }
    }

    template <typename... Args>
    void error(std::string_view format, Args&&... args) const
    {
        if (should_log(LogLevel::Error))
        {
            logger_->error(format, std::forward<Args>(args)...);
        }
    }

    template <typename... Args>
    void critical(std::string_view format, Args&&... args) const
    {
        if (should_log(LogLevel::Critical))
        {
            logger_->critical(format, std::forward<Args>(args)...);
        }
    }

    /**
     * @brief Set the log level for this logger
     *
     * @param level New log level
     */
    void set_level(LogLevel level);

    /**
     * @brief Get the current log level
     *
     * @return Current log level
     */
    LogLevel get_level() const;

    /**
     * @brief Get the logger name
     *
     * @return Logger name
     */
    std::string_view get_name() const;

  private:
    explicit Logger(std::shared_ptr<spdlog::logger> logger);

    bool should_log(LogLevel level) const;
    static spdlog::level::level_enum to_spdlog_level(LogLevel level);
    static LogLevel from_spdlog_level(spdlog::level::level_enum level);

    std::shared_ptr<spdlog::logger> logger_;

    static bool initialized_;
    static std::unordered_map<std::string, std::shared_ptr<Logger>> loggers_;
    static std::shared_ptr<Logger> default_logger_;
};

// Convenience macros for the default logger
// Using immediately invoked lambda expressions (IIFE) instead of do-while loops
// to follow Tiger Style principles while maintaining multi-statement macro safety
#define LOG_TRACE(...)                                \
    [&]()                                             \
    {                                                 \
        auto logger = dashcam::Logger::get_default(); \
        if (logger)                                   \
            logger->trace(__VA_ARGS__);               \
    }()

#define LOG_DEBUG(...)                                \
    [&]()                                             \
    {                                                 \
        auto logger = dashcam::Logger::get_default(); \
        if (logger)                                   \
            logger->debug(__VA_ARGS__);               \
    }()

#define LOG_INFO(...)                                 \
    [&]()                                             \
    {                                                 \
        auto logger = dashcam::Logger::get_default(); \
        if (logger)                                   \
            logger->info(__VA_ARGS__);                \
    }()

#define LOG_WARNING(...)                              \
    [&]()                                             \
    {                                                 \
        auto logger = dashcam::Logger::get_default(); \
        if (logger)                                   \
            logger->warning(__VA_ARGS__);             \
    }()

#define LOG_ERROR(...)                                \
    [&]()                                             \
    {                                                 \
        auto logger = dashcam::Logger::get_default(); \
        if (logger)                                   \
            logger->error(__VA_ARGS__);               \
    }()

#define LOG_CRITICAL(...)                             \
    [&]()                                             \
    {                                                 \
        auto logger = dashcam::Logger::get_default(); \
        if (logger)                                   \
            logger->critical(__VA_ARGS__);            \
    }()

}  // namespace dashcam
