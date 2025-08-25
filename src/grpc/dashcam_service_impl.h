#pragma once

/**
 * @file dashcam_service_impl.h
 * @brief Implementation of the DashcamService gRPC interface
 * 
 * This file provides concrete implementations of the gRPC services defined
 * in dashcam.proto. These implementations handle the actual business logic
 * for the dashcam system.
 */

#include "dashcam.grpc.pb.h"
#include <grpcpp/grpcpp.h>
#include <thread>
#include <chrono>

namespace dashcam {

/**
 * @brief Implementation of the main DashcamService
 * 
 * This class provides concrete implementations for all RPC methods
 * defined in the DashcamService proto service. Each method handles
 * the corresponding dashcam functionality.
 */
class DashcamServiceImpl final : public DashcamService::Service {
public:
    /**
     * @brief Get current system status
     */
    grpc::Status GetStatus(grpc::ServerContext* context,
                          const GetStatusRequest* request,
                          GetStatusResponse* response) override;
    
    /**
     * @brief Get current configuration
     */
    grpc::Status GetConfig(grpc::ServerContext* context,
                          const GetConfigRequest* request,
                          GetConfigResponse* response) override;
    
    /**
     * @brief Update system configuration
     */
    grpc::Status UpdateConfig(grpc::ServerContext* context,
                             const UpdateConfigRequest* request,
                             UpdateConfigResponse* response) override;
    
    /**
     * @brief Start recording with current or provided config
     */
    grpc::Status StartRecording(grpc::ServerContext* context,
                               const StartRecordingRequest* request,
                               StartRecordingResponse* response) override;
    
    /**
     * @brief Stop recording
     */
    grpc::Status StopRecording(grpc::ServerContext* context,
                              const StopRecordingRequest* request,
                              StopRecordingResponse* response) override;
    
    /**
     * @brief Stream status updates for real-time monitoring
     */
    grpc::Status StreamStatus(grpc::ServerContext* context,
                             const GetStatusRequest* request,
                             grpc::ServerWriter<DashcamStatus>* writer) override;
};

} // namespace dashcam
