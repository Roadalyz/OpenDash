# Tiger Style for C++

## The Essence Of Style

> "There are three things extremely hard: steel, a diamond, and to know one's self." — Benjamin Franklin

Our C++ coding style adapts TigerBeetle's philosophy to create safe, performant, and maintainable dashcam software. This document explores how we apply these design goals to C++ development.

## Design Goals

Our design goals are safety, performance, and developer experience. In that order. All three are important. Good style advances these goals.

## Safety

### Memory Management
- **Use RAII (Resource Acquisition Is Initialization)** for all resource management
- **Prefer smart pointers** over raw pointers: `std::unique_ptr`, `std::shared_ptr`
- **Use `std::array` and `std::vector`** instead of C-style arrays
- **Avoid manual memory management** - no naked `new`/`delete`
- **Use const-correctness** everywhere - make everything const that can be const

### Control Flow
- **Use only very simple, explicit control flow** for clarity
- **Do not use recursion** to ensure bounded execution
- **Put a limit on everything** - all loops must have fixed upper bounds
- Use range-based for loops when possible: `for (const auto& item : container)`

### Type Safety
- **Use strongly-typed enums**: `enum class Status : uint8_t { Active, Inactive };`
- **Use explicitly-sized types**: `uint32_t`, `int64_t`, etc.
- **Avoid implicit conversions** - prefer explicit casts
- **Use `constexpr` for compile-time constants**

### Assertions and Error Handling
- **Assert all function preconditions and postconditions**
- **Use exceptions for exceptional cases only** - prefer error codes for expected failures
- **Always handle errors** - use `std::optional`, `std::expected` (C++23), or custom Result types
- **Split compound assertions**: prefer multiple simple assertions over complex ones
- **Assert compile-time relationships** using `static_assert`

```cpp
// Good
static_assert(sizeof(VideoFrame) <= MAX_FRAME_SIZE);
assert(frame_index < frame_buffer.size());
assert(frame_buffer.data() != nullptr);

// Bad
assert(frame_index < frame_buffer.size() && frame_buffer.data() != nullptr);
```

### Function Design
- **Restrict function length to 70 lines maximum**
- **Minimize function parameters** - prefer structs for multiple related parameters
- **Use const references for input parameters**: `const VideoConfig& config`
- **Use output parameters for multiple return values** or structured bindings

```cpp
// Good
struct CameraSettings {
    uint32_t width_pixels;
    uint32_t height_pixels;
    uint32_t fps;
};

bool configure_camera(const CameraSettings& settings);

// Bad
bool configure_camera(uint32_t width, uint32_t height, uint32_t fps, bool auto_focus, int exposure);
```

## Performance

### Memory Layout
- **Prefer contiguous memory layout** - use `std::vector` over `std::list`
- **Pack structs carefully** - be mindful of alignment and padding
- **Use cache-friendly data structures**
- **Minimize dynamic allocations in hot paths**

### Efficient C++ Patterns
- **Use move semantics** where appropriate
- **Prefer pass-by-const-reference** for expensive-to-copy types
- **Use string_view** for read-only string parameters
- **Reserve vector capacity** when size is known in advance

```cpp
// Good
void process_video_data(std::string_view filename, 
                       const std::vector<uint8_t>& frame_data) {
    // Implementation
}

// Bad
void process_video_data(std::string filename, 
                       std::vector<uint8_t> frame_data) {
    // Implementation
}
```

### Batching and Amortization
- **Batch I/O operations** - read/write multiple frames at once
- **Use circular buffers** for streaming data
- **Minimize system calls** through buffering

## Developer Experience

### Naming Conventions
- **Use snake_case** for variables, functions, and file names
- **Use PascalCase** for classes and structs
- **Use SCREAMING_SNAKE_CASE** for constants and macros
- **Use meaningful, descriptive names** - no abbreviations except for well-known cases

```cpp
// Good
class VideoCapture {
public:
    bool initialize_camera(const CameraSettings& settings);
    void start_recording_session();
    
private:
    uint32_t frame_count_total;
    std::chrono::milliseconds recording_duration_ms;
};

const uint32_t MAX_RECORDING_TIME_HOURS = 24;

// Bad
class VC {
public:
    bool init(const CS& s);
    void start();
    
private:
    uint32_t fc;
    std::chrono::milliseconds rd;
};
```

### File Organization
- **One class per header file** (with matching .cpp file)
- **Use include guards or #pragma once**
- **Forward declarations** in headers when possible
- **Minimize header dependencies**

### Documentation
- **Use Doxygen-style comments** for public APIs
- **Explain the 'why' not just the 'what'**
- **Document preconditions and postconditions**

```cpp
/**
 * @brief Captures a single frame from the camera
 * 
 * @param output_buffer Pre-allocated buffer to store frame data
 * @param buffer_size Size of the output buffer in bytes
 * @return true if frame captured successfully, false otherwise
 * 
 * @pre Camera must be initialized and started
 * @pre output_buffer must not be nullptr
 * @pre buffer_size must be >= expected_frame_size()
 * @post If successful, output_buffer contains valid frame data
 */
bool capture_frame(uint8_t* output_buffer, size_t buffer_size);
```

### Modern C++ Features
- **Use auto judiciously** - prefer explicit types for clarity when type isn't obvious
- **Use lambdas for short, local functions**
- **Use structured bindings** (C++17) for multiple return values
- **Use if-init statements** (C++17) to minimize scope

```cpp
// Good - clear what type we expect
auto frame_count = static_cast<uint32_t>(frames.size());
const std::string& filename = get_output_filename();

// Good - using modern C++ features
if (auto result = try_capture_frame(); result.has_value()) {
    process_frame(result.value());
}
```

### Error Handling Patterns
```cpp
// Result-style error handling
template<typename T>
class Result {
public:
    static Result success(T&& value) { return Result(std::move(value)); }
    static Result error(std::string_view message) { return Result(message); }
    
    bool is_success() const { return has_value_; }
    const T& value() const { 
        assert(is_success()); 
        return value_; 
    }
    std::string_view error_message() const { 
        assert(!is_success()); 
        return error_message_; 
    }

private:
    Result(T&& value) : value_(std::move(value)), has_value_(true) {}
    Result(std::string_view message) : error_message_(message), has_value_(false) {}
    
    T value_;
    std::string error_message_;
    bool has_value_;
};
```

### Style By The Numbers
- **Use clang-format** with consistent configuration
- **4 spaces indentation** (no tabs)
- **100 character line limit** maximum
- **Always use braces** for control structures, even single statements
- **One declaration per line**

```cpp
// Good
if (camera_status == CameraStatus::Ready) {
    start_recording();
}

// Bad
if (camera_status == CameraStatus::Ready) start_recording();
```

### Dependencies and Tools
- **Minimize external dependencies** - each dependency must justify its inclusion
- **Use Conan for package management** - maintain conanfile.txt/conanfile.py
- **Standardize on CMake** for build system
- **Use static analysis tools**: clang-tidy, cppcheck
- **Use sanitizers** in debug builds: AddressSanitizer, UndefinedBehaviorSanitizer

## Testing
- **Write tests first** when fixing bugs
- **Use GoogleTest framework** for unit tests
- **Test both positive and negative cases**
- **Mock external dependencies** for unit tests
- **Use property-based testing** where applicable

```cpp
TEST(VideoCapture, InitializeWithValidSettings) {
    VideoCapture capture;
    CameraSettings settings{
        .width_pixels = 1920,
        .height_pixels = 1080,
        .fps = 30
    };
    
    EXPECT_TRUE(capture.initialize_camera(settings));
    EXPECT_EQ(capture.get_frame_width(), 1920);
    EXPECT_EQ(capture.get_frame_height(), 1080);
}

TEST(VideoCapture, InitializeWithInvalidSettings) {
    VideoCapture capture;
    CameraSettings invalid_settings{
        .width_pixels = 0,  // Invalid
        .height_pixels = 1080,
        .fps = 30
    };
    
    EXPECT_FALSE(capture.initialize_camera(invalid_settings));
}
```

## Platform Considerations
- **Use standard library** over platform-specific APIs when possible
- **Abstract platform differences** behind interfaces
- **Test on all target platforms** regularly
- **Use CMake's platform detection** for conditional compilation

```cpp
#ifdef _WIN32
    #include <windows.h>
#elif __linux__
    #include <sys/stat.h>
#elif __APPLE__
    #include <sys/stat.h>
#endif

// Better - abstract the differences
class FileSystem {
public:
    virtual ~FileSystem() = default;
    virtual bool create_directory(std::string_view path) = 0;
    virtual bool file_exists(std::string_view path) = 0;
};
```

Remember: Code is read more often than it is written. Write code that your future self and your teammates will thank you for.
