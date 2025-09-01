#include "dashcam_service_impl.h"

#include "dashcam/utils/logger.h"

namespace dashcam
{

namespace
{
// Default dashcam configuration constants
constexpr uint32_t DEFAULT_FPS = 30;
constexpr uint32_t DEFAULT_QUALITY_PERCENT = 95;
constexpr uint32_t DEFAULT_MAX_FILE_SIZE_MB = 100;
constexpr uint32_t DEFAULT_RETENTION_DAYS = 7;

// Storage size constants
constexpr uint64_t BYTES_PER_MB = 1024 * 1024;
constexpr uint64_t BYTES_PER_GB = 1024 * BYTES_PER_MB;
constexpr uint64_t DEFAULT_STORAGE_AVAILABLE_BYTES = BYTES_PER_GB;  // 1GB

// Test data constants
constexpr uint32_t TEST_STATUS_UPDATE_COUNT = 3;
constexpr uint32_t TEST_FRAMES_PER_UPDATE = 10;
constexpr uint64_t TEST_STORAGE_INCREMENT_MB = 1;  // 1MB per update
constexpr uint32_t TEST_UPTIME_INCREMENT_SECONDS = 60;  // 1 minute per update
constexpr uint32_t TEST_STATUS_UPDATE_INTERVAL_SECONDS = 300;  // 5 minutes
}  // namespace

grpc::Status DashcamServiceImpl::GetStatus(grpc::ServerContext* context,
                                           const dashcam::GetStatusRequest* request,
                                           dashcam::GetStatusResponse* response)
{
    (void)context;  // Suppress unused parameter warning
    (void)request;  // Suppress unused parameter warning

    LOG_DEBUG("GetStatus called via gRPC");

    // Create a dummy status for testing
    auto* status = response->mutable_status();
    status->set_recording(false);
    status->set_frames_captured(0);
    status->set_storage_used_bytes(0);
    status->set_storage_available_bytes(DEFAULT_STORAGE_AVAILABLE_BYTES);
    status->set_current_fps(DEFAULT_FPS);
    status->set_current_resolution("1920x1080");
    status->set_uptime_seconds(0);

    response->set_success(true);
    response->set_error_message("");

    return grpc::Status::OK;
}

grpc::Status DashcamServiceImpl::GetConfig(grpc::ServerContext* context,
                                           const dashcam::GetConfigRequest* request,
                                           dashcam::GetConfigResponse* response)
{
    (void)context;
    (void)request;

    LOG_DEBUG("GetConfig called via gRPC");

    // Create a dummy config for testing
    auto* config = response->mutable_config();
    config->set_target_fps(DEFAULT_FPS);
    config->set_resolution("1920x1080");
    config->set_quality(DEFAULT_QUALITY_PERCENT);
    config->set_audio_enabled(true);
    config->set_max_file_size_mb(DEFAULT_MAX_FILE_SIZE_MB);
    config->set_retention_days(DEFAULT_RETENTION_DAYS);

    response->set_success(true);
    response->set_error_message("");

    return grpc::Status::OK;
}

grpc::Status DashcamServiceImpl::UpdateConfig(grpc::ServerContext* context,
                                              const dashcam::UpdateConfigRequest* request,
                                              dashcam::UpdateConfigResponse* response)
{
    (void)context;
    (void)request;

    LOG_DEBUG("UpdateConfig called via gRPC");

    // For testing, just accept any config
    response->set_success(true);
    response->set_error_message("");

    return grpc::Status::OK;
}

grpc::Status DashcamServiceImpl::StartRecording(grpc::ServerContext* context,
                                                const dashcam::StartRecordingRequest* request,
                                                dashcam::StartRecordingResponse* response)
{
    (void)context;
    (void)request;

    LOG_DEBUG("StartRecording called via gRPC");

    response->set_success(true);
    response->set_error_message("");

    return grpc::Status::OK;
}

grpc::Status DashcamServiceImpl::StopRecording(grpc::ServerContext* context,
                                               const dashcam::StopRecordingRequest* request,
                                               dashcam::StopRecordingResponse* response)
{
    (void)context;
    (void)request;

    LOG_DEBUG("StopRecording called via gRPC");

    // Create a dummy final status
    auto* status = response->mutable_final_status();
    status->set_recording(false);
    status->set_frames_captured(TEST_FRAMES_PER_UPDATE * TEST_STATUS_UPDATE_COUNT * TEST_STATUS_UPDATE_COUNT);
    status->set_storage_used_bytes(TEST_STORAGE_INCREMENT_MB * BYTES_PER_MB * TEST_STATUS_UPDATE_COUNT * TEST_STATUS_UPDATE_COUNT);
    status->set_storage_available_bytes(DEFAULT_STORAGE_AVAILABLE_BYTES - (TEST_STORAGE_INCREMENT_MB * BYTES_PER_MB * TEST_STATUS_UPDATE_COUNT * TEST_STATUS_UPDATE_COUNT));
    status->set_current_fps(0);
    status->set_current_resolution("");
    status->set_uptime_seconds(TEST_STATUS_UPDATE_INTERVAL_SECONDS);

    response->set_success(true);
    response->set_error_message("");

    return grpc::Status::OK;
}

grpc::Status DashcamServiceImpl::StreamStatus(grpc::ServerContext* context,
                                              const dashcam::GetStatusRequest* request,
                                              grpc::ServerWriter<dashcam::DashcamStatus>* writer)
{
    (void)context;
    (void)request;

    LOG_DEBUG("StreamStatus called via gRPC");

    // For testing, send a few status updates then exit
    for (int i = 0; i < TEST_STATUS_UPDATE_COUNT; ++i)
    {
        dashcam::DashcamStatus status;
        status.set_recording(true);
        status.set_frames_captured(i * TEST_FRAMES_PER_UPDATE);
        status.set_storage_used_bytes(i * TEST_STORAGE_INCREMENT_MB * BYTES_PER_MB);
        status.set_storage_available_bytes(DEFAULT_STORAGE_AVAILABLE_BYTES - (i * TEST_STORAGE_INCREMENT_MB * BYTES_PER_MB));
        status.set_current_fps(DEFAULT_FPS);
        status.set_current_resolution("1920x1080");
        status.set_uptime_seconds(i * TEST_UPTIME_INCREMENT_SECONDS);

        if (!writer->Write(status))
        {
            // Client disconnected
            break;
        }

        // Small delay to simulate real-time updates
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    return grpc::Status::OK;
}

}  // namespace dashcam
