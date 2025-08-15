#pragma once

/**
 * @file grpc_service.h
 * @brief Tiger Style gRPC service integration for dashcam
 * 
 * This header provides a clean interface for gRPC services in the dashcam application.
 * It follows Tiger Style principles of safety, performance, and developer experience.
 */

#include <memory>
#include <string>
#include <grpcpp/grpcpp.h>

// Forward declare the generated protobuf classes
namespace dashcam {
    class DashcamService;
    class DashcamEventService;
}

namespace dashcam {

/**
 * @brief Main gRPC server for dashcam services
 * 
 * Tiger Style: This class encapsulates all gRPC functionality with clear ownership
 * and safe resource management through RAII.
 */
class GrpcServer {
public:
    /**
     * @brief Construct a new gRPC server
     * 
     * @param address Server address (e.g., "0.0.0.0:50051")
     */
    explicit GrpcServer(std::string_view address);
    
    /**
     * @brief Destructor ensures clean shutdown
     */
    ~GrpcServer();
    
    // Tiger Style: No copy/move for simplicity and safety
    GrpcServer(const GrpcServer&) = delete;
    GrpcServer& operator=(const GrpcServer&) = delete;
    GrpcServer(GrpcServer&&) = delete;
    GrpcServer& operator=(GrpcServer&&) = delete;
    
    /**
     * @brief Start the gRPC server
     * 
     * @return true if server started successfully
     * @pre Server must not already be running
     * @post If successful, server is running and ready to accept connections
     */
    bool start();
    
    /**
     * @brief Stop the gRPC server gracefully
     * 
     * @post Server is stopped and all connections are closed
     */
    void stop();
    
    /**
     * @brief Check if server is currently running
     * 
     * @return true if server is running
     */
    bool is_running() const;
    
    /**
     * @brief Wait for the server to shutdown (blocking)
     * 
     * This is typically called from the main thread after start().
     */
    void wait_for_shutdown();

private:
    std::string server_address_;
    std::unique_ptr<grpc::Server> server_;
    bool running_;
    
    // Service implementations (to be implemented)
    // std::unique_ptr<DashcamServiceImpl> dashcam_service_;
    // std::unique_ptr<DashcamEventServiceImpl> event_service_;
};

/**
 * @brief gRPC client for connecting to dashcam services
 * 
 * Tiger Style: Provides a safe, easy-to-use interface for gRPC clients
 */
class GrpcClient {
public:
    /**
     * @brief Construct a new gRPC client
     * 
     * @param address Server address to connect to
     */
    explicit GrpcClient(std::string_view address);
    
    /**
     * @brief Destructor ensures clean disconnection
     */
    ~GrpcClient() = default;
    
    // Tiger Style: Allow move but not copy
    GrpcClient(const GrpcClient&) = delete;
    GrpcClient& operator=(const GrpcClient&) = delete;
    GrpcClient(GrpcClient&&) = default;
    GrpcClient& operator=(GrpcClient&&) = default;
    
    /**
     * @brief Connect to the gRPC server
     * 
     * @return true if connection successful
     */
    bool connect();
    
    /**
     * @brief Check if client is connected
     * 
     * @return true if connected to server
     */
    bool is_connected() const;
    
    /**
     * @brief Disconnect from the server
     */
    void disconnect();

private:
    std::string server_address_;
    std::shared_ptr<grpc::Channel> channel_;
    bool connected_;
    
    // Service stubs (to be implemented)
    // std::unique_ptr<DashcamService::Stub> dashcam_stub_;
    // std::unique_ptr<DashcamEventService::Stub> event_stub_;
};

} // namespace dashcam
