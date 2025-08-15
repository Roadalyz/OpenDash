#include <gtest/gtest.h>

namespace dashcam {
namespace test {

/**
 * @brief Simple test to verify the test infrastructure works
 */
TEST(MainTest, BasicAssertions) {
    // Tiger Style: Test both positive and negative cases
    EXPECT_TRUE(true);
    EXPECT_FALSE(false);
    EXPECT_EQ(2 + 2, 4);
    EXPECT_NE(2 + 2, 5);
}

/**
 * @brief Test that demonstrates proper test structure
 */
TEST(MainTest, ProperTestStructure) {
    // Arrange
    const int expected_value = 42;
    const int actual_value = 42;
    
    // Act & Assert
    EXPECT_EQ(actual_value, expected_value);
}

} // namespace test
} // namespace dashcam
