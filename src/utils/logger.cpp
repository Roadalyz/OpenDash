#include "dashcam/utils/logger.h"

#include <iostream>
#include <cassert>
#include <filesystem>

namespace dashcam {

// Static member definitions
bool Logger::initialized_ = false;
std::unordered_map<std::string, std::shared_ptr<Logger>> Logger::loggers_;
std::shared_ptr<Logger> Logger::default_logger_;

bool Logger::initialize(LogLevel default_level) {
    if (initialized_) {
        return true; // Already initialized
    }

    try {
        // Set default spdlog pattern and level
        spdlog::set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%n] [%l] %v");
        spdlog::set_level(to_spdlog_level(default_level));

        // Create default logger with explicit initialization
        LoggerConfig default_config;
        default_config.name = std::string("default");
        default_config.level = default_level;
        default_config.enable_console = true;
        default_config.enable_file = true;
        default_config.file_path = std::string("logs/dashcam.log");
        default_config.max_file_size_bytes = 10 * 1024 * 1024;
        default_config.max_files = 5;
        default_config.pattern = std::string("[%Y-%m-%d %H:%M:%S.%e] [%n] [%l] %v");

        default_logger_ = create_logger(default_config);
        if (!default_logger_) {
            std::cerr << "Failed to create default logger - create_logger returned nullptr\n";
            return false;
        }

        initialized_ = true;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Logger initialization failed: " << e.what() << "\n";
        return false;
    }
}

std::shared_ptr<Logger> Logger::create_logger(const LoggerConfig& config) {
    assert(!config.name.empty()); // Tiger Style: Assert preconditions
    
    // Allow creation during initialization (when creating the default logger)
    // or when already initialized
    if (!initialized_ && config.name != "default") {
        std::cerr << "Logger system not initialized\n";
        return nullptr;
    }

    // Check if logger already exists
    auto it = loggers_.find(config.name);
    if (it != loggers_.end()) {
        return it->second;
    }

    try {
        std::vector<spdlog::sink_ptr> sinks;

        // Add console sink if enabled
        if (config.enable_console) {
            auto console_sink = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
            console_sink->set_level(to_spdlog_level(config.level));
            console_sink->set_pattern(config.pattern);
            sinks.push_back(console_sink);
        }

        // Add file sink if enabled
        if (config.enable_file && !config.file_path.empty()) {
            // Ensure the directory exists
            std::filesystem::path log_path(config.file_path);
            std::filesystem::path log_dir = log_path.parent_path();
            
            if (!log_dir.empty() && !std::filesystem::exists(log_dir)) {
                std::error_code ec;
                std::filesystem::create_directories(log_dir, ec);
                if (ec) {
                    std::cerr << "Failed to create log directory '" << log_dir << "': " << ec.message() << "\n";
                    return nullptr;
                }
            }
            
            auto file_sink = std::make_shared<spdlog::sinks::rotating_file_sink_mt>(
                config.file_path, 
                config.max_file_size_bytes, 
                config.max_files
            );
            file_sink->set_level(to_spdlog_level(config.level));
            file_sink->set_pattern(config.pattern);
            sinks.push_back(file_sink);
        }

        if (sinks.empty()) {
            std::cerr << "No sinks configured for logger: " << config.name << "\n";
            return nullptr;
        }

        // Create the spdlog logger
        auto spdlog_logger = std::make_shared<spdlog::logger>(config.name, sinks.begin(), sinks.end());
        spdlog_logger->set_level(to_spdlog_level(config.level));
        spdlog_logger->flush_on(spdlog::level::info); // Flush on info level and above for immediate writing

        // Register with spdlog
        spdlog::register_logger(spdlog_logger);

        // Create our wrapper
        auto logger = std::shared_ptr<Logger>(new Logger(spdlog_logger));
        loggers_[config.name] = logger;

        return logger;
    } catch (const std::exception& e) {
        std::cerr << "Failed to create logger '" << config.name << "': " << e.what() << "\n";
        return nullptr;
    }
}

std::shared_ptr<Logger> Logger::get_logger(std::string_view name) {
    auto it = loggers_.find(std::string(name));
    if (it != loggers_.end()) {
        return it->second;
    }
    return nullptr;
}

std::shared_ptr<Logger> Logger::get_default() {
    return default_logger_;
}

void Logger::shutdown() {
    if (!initialized_) {
        return;
    }

    // Flush all loggers
    for (auto& [name, logger] : loggers_) {
        if (logger && logger->logger_) {
            logger->logger_->flush();
        }
    }

    // Clear our registry
    loggers_.clear();
    default_logger_.reset();

    // Shutdown spdlog
    spdlog::shutdown();
    
    initialized_ = false;
}

Logger::Logger(std::shared_ptr<spdlog::logger> logger) 
    : logger_(std::move(logger)) {
    assert(logger_);
}

void Logger::trace(std::string_view message) const {
    if (should_log(LogLevel::Trace)) {
        logger_->trace(message);
    }
}

void Logger::debug(std::string_view message) const {
    if (should_log(LogLevel::Debug)) {
        logger_->debug(message);
    }
}

void Logger::info(std::string_view message) const {
    if (should_log(LogLevel::Info)) {
        logger_->info(message);
    }
}

void Logger::warning(std::string_view message) const {
    if (should_log(LogLevel::Warning)) {
        logger_->warn(message);
    }
}

void Logger::error(std::string_view message) const {
    if (should_log(LogLevel::Error)) {
        logger_->error(message);
    }
}

void Logger::critical(std::string_view message) const {
    if (should_log(LogLevel::Critical)) {
        logger_->critical(message);
    }
}

void Logger::flush() const {
    assert(logger_);
    logger_->flush();
}

void Logger::set_level(LogLevel level) {
    assert(logger_);
    logger_->set_level(to_spdlog_level(level));
}

LogLevel Logger::get_level() const {
    assert(logger_);
    return from_spdlog_level(logger_->level());
}

std::string_view Logger::get_name() const {
    assert(logger_);
    return logger_->name();
}

bool Logger::should_log(LogLevel level) const {
    assert(logger_);
    return logger_->should_log(to_spdlog_level(level));
}

spdlog::level::level_enum Logger::to_spdlog_level(LogLevel level) {
    switch (level) {
        case LogLevel::Trace:    return spdlog::level::trace;
        case LogLevel::Debug:    return spdlog::level::debug;
        case LogLevel::Info:     return spdlog::level::info;
        case LogLevel::Warning:  return spdlog::level::warn;
        case LogLevel::Error:    return spdlog::level::err;
        case LogLevel::Critical: return spdlog::level::critical;
        case LogLevel::Off:      return spdlog::level::off;
        default:
            assert(false && "Invalid log level");
            return spdlog::level::info;
    }
}

LogLevel Logger::from_spdlog_level(spdlog::level::level_enum level) {
    switch (level) {
        case spdlog::level::trace:    return LogLevel::Trace;
        case spdlog::level::debug:    return LogLevel::Debug;
        case spdlog::level::info:     return LogLevel::Info;
        case spdlog::level::warn:     return LogLevel::Warning;
        case spdlog::level::err:      return LogLevel::Error;
        case spdlog::level::critical: return LogLevel::Critical;
        case spdlog::level::off:      return LogLevel::Off;
        default:
            assert(false && "Invalid spdlog level");
            return LogLevel::Info;
    }
}

} // namespace dashcam
