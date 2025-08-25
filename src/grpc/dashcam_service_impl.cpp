#include "dashcam_service_impl.h"
#include "dashcam/utils/logger.h"

namespace dashcam {

grpc::Status DashcamServiceImpl::GetStatus(grpc::ServerContext* context,
                                          const dashcam::GetStatusRequest* request,
                                          dashcam::GetStatusResponse* response) {
    (void)context;  // Suppress unused parameter warning
    (void)request;  // Suppress unused parameter warning
    
    LOG_DEBUG("GetStatus called via gRPC");
    
    // Create a dummy status for testing
    auto* status = response->mutable_status();
    status->set_recording(false);
    status->set_frames_captured(0);
    status->set_storage_used_bytes(0);
    status->set_storage_available_bytes(1000000000); // 1GB
    status->set_current_fps(30);
    status->set_current_resolution("1920x1080");
    status->set_uptime_seconds(0);
    
    response->set_success(true);
    response->set_error_message("");
    
    return grpc::Status::OK;
}

grpc::Status DashcamServiceImpl::GetConfig(grpc::ServerContext* context,
                                          const dashcam::GetConfigRequest* request,
                                          dashcam::GetConfigResponse* response) {
    (void)context;
    (void)request;
    
    LOG_DEBUG("GetConfig called via gRPC");
    
    // Create a dummy config for testing
    auto* config = response->mutable_config();
    config->set_target_fps(30);
    config->set_resolution("1920x1080");
    config->set_quality(95);
    config->set_audio_enabled(true);
    config->set_max_file_size_mb(100);
    config->set_retention_days(7);
    
    response->set_success(true);
    response->set_error_message("");
    
    return grpc::Status::OK;
}

grpc::Status DashcamServiceImpl::UpdateConfig(grpc::ServerContext* context,
                                             const dashcam::UpdateConfigRequest* request,
                                             dashcam::UpdateConfigResponse* response) {
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
                                               dashcam::StartRecordingResponse* response) {
    (void)context;
    (void)request;
    
    LOG_DEBUG("StartRecording called via gRPC");
    
    response->set_success(true);
    response->set_error_message("");
    
    return grpc::Status::OK;
}

grpc::Status DashcamServiceImpl::StopRecording(grpc::ServerContext* context,
                                              const dashcam::StopRecordingRequest* request,
                                              dashcam::StopRecordingResponse* response) {
    (void)context;
    (void)request;
    
    LOG_DEBUG("StopRecording called via gRPC");
    
    // Create a dummy final status
    auto* status = response->mutable_final_status();
    status->set_recording(false);
    status->set_frames_captured(100);
    status->set_storage_used_bytes(50000000); // 50MB
    status->set_storage_available_bytes(950000000); // 950MB
    status->set_current_fps(0);
    status->set_current_resolution("");
    status->set_uptime_seconds(300); // 5 minutes
    
    response->set_success(true);
    response->set_error_message("");
    
    return grpc::Status::OK;
}

grpc::Status DashcamServiceImpl::StreamStatus(grpc::ServerContext* context,
                                             const dashcam::GetStatusRequest* request,
                                             grpc::ServerWriter<dashcam::DashcamStatus>* writer) {
    (void)context;
    (void)request;
    
    LOG_DEBUG("StreamStatus called via gRPC");
    
    // For testing, send a few status updates then exit
    for (int i = 0; i < 3; ++i) {
        dashcam::DashcamStatus status;
        status.set_recording(true);
        status.set_frames_captured(i * 10);
        status.set_storage_used_bytes(i * 1000000);
        status.set_storage_available_bytes(1000000000 - (i * 1000000));
        status.set_current_fps(30);
        status.set_current_resolution("1920x1080");
        status.set_uptime_seconds(i * 60);
        
        if (!writer->Write(status)) {
            // Client disconnected
            break;
        }
        
        // Small delay to simulate real-time updates
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    return grpc::Status::OK;
}

} // namespace dashcam
