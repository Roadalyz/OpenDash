#include <gtest/gtest.h>
#include "dashcam/grpc_service.h"
#include "dashcam/utils/logger.h"

// Include the generated protobuf headers
// Note: These will be available after the first build
// #include "dashcam.pb.h"
// #include "dashcam.grpc.pb.h"

/**
 * @brief Tiger Style tests for gRPC integration
 * 
 * These tests verify that protobuf and gRPC are properly integrated
 * and that our service classes work correctly.
 */
class GrpcIntegrationTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Initialize logger for tests
        dashcam::Logger::initialize(dashcam::LogLevel::Debug);
    }

    void TearDown() override {
        dashcam::Logger::shutdown();
    }
};

TEST_F(GrpcIntegrationTest, GrpcServerConstruction) {
    // Tiger Style: Test construction with valid parameters
    dashcam::GrpcServer server("localhost:50051");
    
    // Server should not be running initially
    EXPECT_FALSE(server.is_running());
}

TEST_F(GrpcIntegrationTest, GrpcClientConstruction) {
    // Tiger Style: Test construction with valid parameters
    dashcam::GrpcClient client("localhost:50051");
    
    // Client should not be connected initially
    EXPECT_FALSE(client.is_connected());
}

TEST_F(GrpcIntegrationTest, ServerStartStop) {
    dashcam::GrpcServer server("localhost:50052"); // Different port to avoid conflicts
    
    // Server should start successfully
    EXPECT_TRUE(server.start());
    EXPECT_TRUE(server.is_running());
    
    // Server should stop cleanly
    server.stop();
    EXPECT_FALSE(server.is_running());
}

// Note: Commented out until protobuf files are generated
/*
TEST_F(GrpcIntegrationTest, ProtobufMessageCreation) {
    // Test that we can create and manipulate protobuf messages
    dashcam::DashcamStatus status;
    status.set_recording(true);
    status.set_frames_captured(1000);
    status.set_current_fps(30);
    status.set_current_resolution("1920x1080");
    
    EXPECT_TRUE(status.recording());
    EXPECT_EQ(status.frames_captured(), 1000);
    EXPECT_EQ(status.current_fps(), 30);
    EXPECT_EQ(status.current_resolution(), "1920x1080");
}

TEST_F(GrpcIntegrationTest, ProtobufSerialization) {
    // Test protobuf serialization/deserialization
    dashcam::DashcamConfig config;
    config.set_target_fps(60);
    config.set_resolution("4K");
    config.set_quality(95);
    config.set_audio_enabled(true);
    
    // Serialize to string
    std::string serialized;
    EXPECT_TRUE(config.SerializeToString(&serialized));
    EXPECT_FALSE(serialized.empty());
    
    // Deserialize from string
    dashcam::DashcamConfig deserialized;
    EXPECT_TRUE(deserialized.ParseFromString(serialized));
    
    // Verify data integrity
    EXPECT_EQ(deserialized.target_fps(), 60);
    EXPECT_EQ(deserialized.resolution(), "4K");
    EXPECT_EQ(deserialized.quality(), 95);
    EXPECT_TRUE(deserialized.audio_enabled());
}
*/
