#include "dashcam/grpc_service.h"
#include "dashcam/utils/logger.h"
#include "dashcam_service_impl.h"

#include <grpcpp/grpcpp.h>
#include <cassert>

namespace dashcam {

GrpcServer::GrpcServer(std::string_view address) 
    : server_address_(address), running_(false), dashcam_service_(std::make_unique<DashcamServiceImpl>()) {
    assert(!address.empty()); // Tiger Style: assert preconditions
}

GrpcServer::~GrpcServer() {
    if (running_) {
        stop();
    }
}

bool GrpcServer::start() {
    assert(!running_); // Tiger Style: assert preconditions
    
    try {
        grpc::ServerBuilder builder;
        
        // Listen on the given address without any authentication mechanism
        builder.AddListeningPort(server_address_, grpc::InsecureServerCredentials());
        
        // Register services
        builder.RegisterService(dashcam_service_.get());
        
        // Build and start the server
        server_ = builder.BuildAndStart();
        if (!server_) {
            LOG_ERROR("Failed to start gRPC server on {}", server_address_);
            return false;
        }
        
        running_ = true;
        LOG_INFO("gRPC server started on {}", server_address_);
        return true;
        
    } catch (const std::exception& e) {
        LOG_ERROR("Exception starting gRPC server: {}", e.what());
        return false;
    }
}

void GrpcServer::stop() {
    if (server_ && running_) {
        LOG_INFO("Stopping gRPC server...");
        server_->Shutdown();
        running_ = false;
        LOG_INFO("gRPC server stopped");
    }
}

bool GrpcServer::is_running() const {
    return running_;
}

void GrpcServer::wait_for_shutdown() {
    assert(server_); // Tiger Style: assert preconditions
    if (server_) {
        server_->Wait();
    }
}

// GrpcClient implementation
GrpcClient::GrpcClient(std::string_view address) 
    : server_address_(address), connected_(false) {
    assert(!address.empty()); // Tiger Style: assert preconditions
}

bool GrpcClient::connect() {
    assert(!connected_); // Tiger Style: assert preconditions
    
    try {
        // Create a channel to the server
        channel_ = grpc::CreateChannel(server_address_, grpc::InsecureChannelCredentials());
        if (!channel_) {
            LOG_ERROR("Failed to create gRPC channel to {}", server_address_);
            return false;
        }
        
        // Wait for the channel to be ready (with timeout)
        auto deadline = std::chrono::system_clock::now() + std::chrono::seconds(5);
        if (!channel_->WaitForConnected(deadline)) {
            LOG_ERROR("Failed to connect to gRPC server at {} within timeout", server_address_);
            return false;
        }
        
        // Create service stubs (commented out until we implement them)
        // dashcam_stub_ = DashcamService::NewStub(channel_);
        // event_stub_ = DashcamEventService::NewStub(channel_);
        
        connected_ = true;
        LOG_INFO("Connected to gRPC server at {}", server_address_);
        return true;
        
    } catch (const std::exception& e) {
        LOG_ERROR("Exception connecting to gRPC server: {}", e.what());
        return false;
    }
}

bool GrpcClient::is_connected() const {
    return connected_ && channel_ && channel_->GetState(false) == GRPC_CHANNEL_READY;
}

void GrpcClient::disconnect() {
    if (connected_) {
        LOG_INFO("Disconnecting from gRPC server...");
        channel_.reset();
        connected_ = false;
        LOG_INFO("Disconnected from gRPC server");
    }
}

} // namespace dashcam
