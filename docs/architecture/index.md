# System Architecture

The Dashcam project follows a layered architecture designed for safety, performance, and maintainability. This document explains the architectural decisions, component relationships, and design patterns used throughout the system.

## 🏗️ High-Level Architecture

```mermaid
graph TB
    subgraph "Application Layer"
        App[Main Application]
        CLI[Command Line Interface]
    end
    
    subgraph "Core Layer"
        CM[Camera Manager]
        VR[Video Recorder] 
        SM[Storage Manager]
        EM[Event Manager]
    end
    
    subgraph "Utility Layer"
        Logger[Logging System]
        Config[Configuration]
        Metrics[Metrics Collection]
        Utils[Utilities]
    end
    
    subgraph "Platform Abstraction Layer"
        FileSystem[File System]
        Threading[Threading]
        Memory[Memory Management]
        IPC[Inter-Process Communication]
    end
    
    subgraph "External Dependencies"
        spdlog[spdlog Library]
        fmt[fmt Library]
        OS[Operating System]
        Hardware[Camera Hardware]
    end
    
    App --> CM
    App --> VR
    App --> SM
    App --> Logger
    
    CM --> Logger
    CM --> Config
    CM --> Hardware
    
    VR --> Logger
    VR --> FileSystem
    VR --> Memory
    
    SM --> Logger
    SM --> FileSystem
    SM --> Threading
    
    Logger --> spdlog
    Logger --> fmt
    Logger --> FileSystem
    
    Config --> FileSystem
    
    FileSystem --> OS
    Threading --> OS
    Memory --> OS
    
    style App fill:#2563eb,stroke:#1e40af,stroke-width:3px,color:#fff
    style Logger fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style Hardware fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
```

## 🎯 Design Principles

### Tiger Style Architecture

The architecture strictly follows Tiger Style principles:

#### 1. Safety First
- **Static Memory Allocation**: All memory allocated at startup
- **Bounded Operations**: Every loop has a maximum iteration count
- **Explicit Error Handling**: No exceptions in critical paths
- **Comprehensive Assertions**: Pre/postconditions for every function

#### 2. Performance Focus
- **Cache-Friendly Design**: Data structures optimized for CPU cache
- **Minimal Dynamic Allocation**: Heap usage avoided in hot paths
- **Batched Operations**: Network, disk, and CPU work batched for efficiency
- **Lock-Free Where Possible**: Atomic operations preferred over mutexes

#### 3. Developer Experience
- **Clear Interfaces**: Each component has a well-defined API
- **Comprehensive Testing**: Every component fully tested
- **Rich Diagnostics**: Extensive logging and debugging support
- **Documentation-Driven**: Code documented before implementation

## 🧩 Component Architecture

### Core Components

```mermaid
classDiagram
    class CameraManager {
        +initialize(settings: CameraSettings): bool
        +start_capture(): bool
        +stop_capture(): bool
        +capture_frame(buffer: FrameBuffer): bool
        +get_camera_info(): CameraInfo
        -camera_device: CameraDevice
        -frame_buffer_pool: FrameBufferPool
        -capture_thread: Thread
    }
    
    class VideoRecorder {
        +initialize(codec: VideoCodec): bool
        +start_recording(output_path: string): bool
        +stop_recording(): bool
        +encode_frame(frame: Frame): bool
        +set_quality(quality: Quality): bool
        -encoder: VideoEncoder
        -output_stream: OutputStream
        -encoding_queue: LockFreeQueue
    }
    
    class StorageManager {
        +initialize(storage_config: StorageConfig): bool
        +allocate_space(size_bytes: size_t): bool
        +write_video_file(data: VideoData): bool
        +cleanup_old_files(): bool
        +get_available_space(): size_t
        -storage_devices: vector~StorageDevice~
        -file_rotation_policy: RotationPolicy
        -cleanup_thread: Thread
    }
    
    CameraManager --> VideoRecorder : provides frames
    VideoRecorder --> StorageManager : writes encoded video
```

### Utility Components

```mermaid
classDiagram
    class Logger {
        <<singleton>>
        +initialize(level: LogLevel): bool
        +create_logger(config: LoggerConfig): shared_ptr~Logger~
        +get_logger(name: string): shared_ptr~Logger~
        +shutdown(): void
        -loggers: unordered_map~string, shared_ptr~Logger~~
        -default_logger: shared_ptr~Logger~
    }
    
    class ConfigParser {
        +load_config(file_path: string): Config
        +save_config(config: Config, file_path: string): bool
        +validate_config(config: Config): ValidationResult
        +get_default_config(): Config
        -config_schema: Schema
        -validators: vector~Validator~
    }
    
    class MetricsCollector {
        +record_metric(name: string, value: double): void
        +start_timer(name: string): TimerHandle
        +stop_timer(handle: TimerHandle): void
        +get_metrics_summary(): MetricsSummary
        -metrics_buffer: CircularBuffer~Metric~
        -timers: unordered_map~string, Timer~
    }
    
    Logger --> ConfigParser : logs configuration events
    Logger --> MetricsCollector : logs performance metrics
```

## 🔄 Data Flow Architecture

### Frame Processing Pipeline

```mermaid
sequenceDiagram
    participant App as Main Application
    participant CM as Camera Manager
    participant VR as Video Recorder
    participant SM as Storage Manager
    participant FS as File System
    
    App->>CM: initialize_camera(settings)
    CM->>CM: allocate_frame_buffers()
    CM-->>App: success
    
    App->>CM: start_capture()
    CM->>CM: start_capture_thread()
    
    loop Frame Capture Loop
        CM->>CM: capture_frame_from_hardware()
        CM->>VR: encode_frame(raw_frame)
        VR->>VR: compress_frame()
        VR->>SM: write_encoded_frame(compressed_data)
        SM->>FS: write_to_disk(data)
        
        Note over CM,SM: All operations bounded<br/>Max 100ms per frame
    end
    
    App->>CM: stop_capture()
    CM->>VR: flush_encoder()
    VR->>SM: finalize_video_file()
    SM-->>App: recording_complete
```

### Error Handling Flow

```mermaid
flowchart TD
    Operation[Component Operation] --> Check{Preconditions<br/>Valid?}
    Check -->|No| Assert[Assert Failure]
    Check -->|Yes| Execute[Execute Operation]
    
    Execute --> Result{Operation<br/>Success?}
    Result -->|Success| PostCheck{Postconditions<br/>Valid?}
    Result -->|Failure| LogError[Log Error]
    
    PostCheck -->|Yes| Return[Return Success]
    PostCheck -->|No| Assert2[Assert Failure]
    
    LogError --> Recovery{Recovery<br/>Possible?}
    Recovery -->|Yes| Recover[Attempt Recovery]
    Recovery -->|No| Propagate[Propagate Error]
    
    Recover --> RetryCheck{Retry<br/>Successful?}
    RetryCheck -->|Yes| Return
    RetryCheck -->|No| Propagate
    
    Assert --> Crash[Crash with Core Dump]
    Assert2 --> Crash
    
    style Assert fill:#ef4444,stroke:#dc2626,stroke-width:2px,color:#fff
    style Crash fill:#991b1b,stroke:#7f1d1d,stroke-width:2px,color:#fff
    style Return fill:#22c55e,stroke:#16a34a,stroke-width:2px,color:#fff
```

## 🧵 Threading Architecture

### Thread Model

The application uses a carefully designed threading model to maximize performance while maintaining safety:

```mermaid
graph TB
    subgraph "Main Thread"
        MainLoop[Main Event Loop]
        UI[User Interface]
        Control[Control Logic]
    end
    
    subgraph "Capture Thread"
        CameraCapture[Camera Frame Capture]
        FrameQueue[Frame Queue<br/>Bounded Size: 30]
    end
    
    subgraph "Encoding Thread"
        VideoEncoding[Video Encoding]
        EncodingQueue[Encoding Queue<br/>Bounded Size: 10]
    end
    
    subgraph "Storage Thread"
        FileWriting[File Writing]
        StorageQueue[Storage Queue<br/>Bounded Size: 5]
    end
    
    subgraph "Utility Threads"
        LoggingThread[Async Logging]
        MetricsThread[Metrics Collection]
        CleanupThread[File Cleanup]
    end
    
    MainLoop --> CameraCapture
    CameraCapture --> FrameQueue
    FrameQueue --> VideoEncoding
    VideoEncoding --> EncodingQueue
    EncodingQueue --> FileWriting
    FileWriting --> StorageQueue
    
    Control --> LoggingThread
    Control --> MetricsThread
    Control --> CleanupThread
    
    style MainLoop fill:#2563eb,stroke:#1e40af,stroke-width:2px,color:#fff
    style FrameQueue fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style EncodingQueue fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style StorageQueue fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
```

### Synchronization Strategy

#### Design Decision: Lock-Free Queues vs. Mutexes

**Decision**: Use lock-free circular buffers for high-frequency data (frames) and mutexes for low-frequency control operations.

**Rationale**:
- Frame processing is the critical path requiring predictable latency
- Control operations (start/stop recording) happen infrequently
- Lock-free structures eliminate priority inversion and deadlock risks
- Simpler to reason about than complex lock hierarchies

**Trade-offs**:
- Lock-free code is harder to implement correctly
- Memory ordering requirements are complex
- Limited scalability to many producers/consumers

```mermaid
graph LR
    Producer[Frame Producer] -->|Push| CircularBuffer[Lock-Free<br/>Circular Buffer]
    CircularBuffer -->|Pop| Consumer[Frame Consumer]
    
    Producer -.->|Backpressure| DropFrame[Drop Frame<br/>if Buffer Full]
    
    subgraph "Memory Ordering"
        Acquire[Acquire Semantics<br/>for Read Index]
        Release[Release Semantics<br/>for Write Index]
    end
    
    style CircularBuffer fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style DropFrame fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
```

## 💾 Memory Architecture

### Memory Layout Strategy

```mermaid
graph TB
    subgraph "Static Memory (Allocated at Startup)"
        FrameBuffers[Frame Buffer Pool<br/>30 x 1920x1080x3 bytes]
        EncodingBuffers[Encoding Buffer Pool<br/>10 x 512KB]
        LogBuffers[Log Buffer Ring<br/>4 x 64KB]
        ConfigData[Configuration Data<br/>~1KB]
    end
    
    subgraph "Stack Memory (Per Thread)"
        MainStack[Main Thread Stack<br/>8MB]
        CaptureStack[Capture Thread Stack<br/>1MB]
        EncodingStack[Encoding Thread Stack<br/>2MB]
        StorageStack[Storage Thread Stack<br/>1MB]
    end
    
    subgraph "Minimal Heap Usage"
        LoggerInstances[Logger Instances<br/>~10KB total]
        ConfigObjects[Config Objects<br/>~5KB total]
        ErrorStrings[Error Messages<br/>~1KB]
    end
    
    style FrameBuffers fill:#3b82f6,stroke:#2563eb,stroke-width:2px,color:#fff
    style LoggerInstances fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
```

### Buffer Management

#### Design Decision: Pre-allocated Buffer Pools

**Decision**: Allocate all frame and encoding buffers at startup in pools.

**Rationale**:
- Eliminates allocation/deallocation overhead in critical paths
- Prevents memory fragmentation during long-running operation
- Enables deterministic memory usage for embedded deployment
- Simplifies memory leak detection and debugging

**Implementation Pattern**:
```cpp
class FrameBufferPool {
    static constexpr size_t BUFFER_COUNT = 30;
    static constexpr size_t BUFFER_SIZE = 1920 * 1080 * 3; // RGB
    
    std::array<std::array<uint8_t, BUFFER_SIZE>, BUFFER_COUNT> buffers_;
    std::atomic<uint32_t> next_available_{0};
    
public:
    FrameBuffer* acquire_buffer() {
        // Lock-free buffer acquisition
        uint32_t index = next_available_.fetch_add(1) % BUFFER_COUNT;
        return &buffers_[index];
    }
    
    void release_buffer(FrameBuffer* buffer) {
        // Buffer automatically available for reuse
        // No explicit release needed with circular allocation
    }
};
```

## 🔧 Configuration Architecture

### Configuration Hierarchy

```mermaid
graph TD
    CompileTime[Compile-Time Constants] --> Runtime[Runtime Configuration]
    Runtime --> Environment[Environment Variables]
    Environment --> CommandLine[Command Line Arguments]
    CommandLine --> ConfigFile[Configuration File]
    ConfigFile --> Defaults[Built-in Defaults]
    
    subgraph "Configuration Sources (Priority Order)"
        CommandLine
        Environment
        ConfigFile
        Defaults
    end
    
    subgraph "Configuration Categories"
        Camera[Camera Settings]
        Video[Video Encoding]
        Storage[Storage Policy]
        Logging[Logging Configuration]
        Performance[Performance Tuning]
    end
    
    Runtime --> Camera
    Runtime --> Video
    Runtime --> Storage
    Runtime --> Logging
    Runtime --> Performance
    
    style CommandLine fill:#ef4444,stroke:#dc2626,stroke-width:2px,color:#fff
    style Defaults fill:#22c55e,stroke:#16a34a,stroke-width:2px,color:#fff
```

## 🚦 State Management

### Application State Machine

```mermaid
stateDiagram-v2
    [*] --> Initializing
    Initializing --> Ready : All components initialized
    Initializing --> Error : Initialization failed
    
    Ready --> Recording : Start recording command
    Ready --> Configuring : Configuration change
    Ready --> Shutdown : Shutdown command
    
    Recording --> Ready : Stop recording command
    Recording --> Error : Critical error occurred
    Recording --> Paused : Pause recording command
    
    Paused --> Recording : Resume recording command
    Paused --> Ready : Stop recording command
    
    Configuring --> Ready : Configuration applied
    Configuring --> Error : Invalid configuration
    
    Error --> Ready : Error resolved
    Error --> Shutdown : Unrecoverable error
    
    Shutdown --> [*]
    
    note right of Recording
        All operations bounded
        Max recording time: 24 hours
        Max file size: 2GB
    end note
```

## 🔍 Monitoring and Observability

### Metrics Collection Architecture

```mermaid
graph LR
    subgraph "Component Metrics"
        CameraMetrics[Camera Metrics<br/>- FPS<br/>- Dropped Frames<br/>- Error Rate]
        EncodingMetrics[Encoding Metrics<br/>- Compression Ratio<br/>- Encoding Time<br/>- Queue Depth]
        StorageMetrics[Storage Metrics<br/>- Write Speed<br/>- Disk Usage<br/>- I/O Errors]
    end
    
    subgraph "System Metrics"
        CPUMetrics[CPU Usage<br/>Memory Usage<br/>Temperature]
        NetworkMetrics[Network I/O<br/>Bandwidth Usage]
    end
    
    CameraMetrics --> MetricsCollector[Metrics Collector]
    EncodingMetrics --> MetricsCollector
    StorageMetrics --> MetricsCollector
    CPUMetrics --> MetricsCollector
    NetworkMetrics --> MetricsCollector
    
    MetricsCollector --> LogOutput[Log Output]
    MetricsCollector --> Dashboard[Web Dashboard]
    MetricsCollector --> Alerts[Alert System]
    
    style MetricsCollector fill:#8b5cf6,stroke:#7c3aed,stroke-width:2px,color:#fff
```

## 🧪 Testing Architecture

### Testing Pyramid

```mermaid
graph TB
    subgraph "Testing Levels"
        UnitTests[Unit Tests<br/>GoogleTest<br/>~100 tests]
        IntegrationTests[Integration Tests<br/>Component Interaction<br/>~30 tests]
        SystemTests[System Tests<br/>pytest<br/>~20 tests]
        PerformanceTests[Performance Tests<br/>Benchmarking<br/>~10 tests]
    end
    
    UnitTests --> Components[Individual Components]
    IntegrationTests --> Interfaces[Component Interfaces]
    SystemTests --> Application[Full Application]
    PerformanceTests --> RealWorld[Real-world Scenarios]
    
    style UnitTests fill:#22c55e,stroke:#16a34a,stroke-width:3px,color:#fff
    style SystemTests fill:#3b82f6,stroke:#2563eb,stroke-width:2px,color:#fff
```

### Test Strategy by Component

| Component | Unit Tests | Integration Tests | System Tests |
|-----------|------------|-------------------|--------------|
| **Logger** | ✅ All log levels<br/>✅ File output<br/>✅ Thread safety | ✅ Multiple loggers<br/>✅ Configuration reload | ✅ Log rotation<br/>✅ Performance under load |
| **Camera Manager** | ✅ Mock camera<br/>✅ Buffer management<br/>✅ Error handling | ✅ Real camera<br/>✅ Format conversion | ✅ Long-term stability<br/>✅ Hardware failure recovery |
| **Video Recorder** | ✅ Codec selection<br/>✅ Quality settings<br/>✅ Frame queuing | ✅ End-to-end encoding<br/>✅ File format validation | ✅ Continuous recording<br/>✅ Storage limits |

## 📋 Architecture Decision Records

### ADR-001: Choose C++17 over C++20

**Status**: Accepted

**Context**: Need to choose C++ standard version for maximum compatibility while having modern features.

**Decision**: Use C++17 as the target standard.

**Consequences**:
- ✅ Wide compiler support (GCC 7+, Clang 5+, MSVC 2017+)
- ✅ Stable feature set with good tooling support
- ✅ Includes essential modern features (auto, lambdas, smart pointers)
- ❌ Missing some newer features like concepts, ranges, coroutines

### ADR-002: Static Memory Allocation Strategy

**Status**: Accepted

**Context**: Embedded deployment requires predictable memory usage.

**Decision**: Allocate all major data structures at startup, avoid dynamic allocation in steady state.

**Consequences**:
- ✅ Predictable memory usage and performance
- ✅ No memory fragmentation issues
- ✅ Easier to debug memory problems
- ❌ Higher startup memory usage
- ❌ Less flexibility for varying workloads

### ADR-003: Comprehensive Logging Strategy

**Status**: Accepted

**Context**: Need excellent debugging and monitoring capabilities.

**Decision**: Implement multi-level, multi-output logging system with performance optimization.

**Consequences**:
- ✅ Excellent debugging and troubleshooting capabilities
- ✅ Production monitoring and alerting
- ✅ Performance tuning through metrics
- ❌ Additional complexity and binary size
- ❌ Need to manage log file rotation and cleanup

---

*This architecture documentation is maintained alongside the codebase. When making architectural changes, update this document and create new ADRs as needed.*
