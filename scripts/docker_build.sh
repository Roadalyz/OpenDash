#!/bin/bash

# Tiger Style: Always motivate, always say why
# This script builds the Docker image for the dashcam application
# It supports multi-platform builds and proper tagging

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
IMAGE_NAME="dashcam"
TAG="latest"
BUILD_ARGS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --no-cache)
            BUILD_ARGS="$BUILD_ARGS --no-cache"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-t|--tag TAG] [-n|--name NAME] [--no-cache]"
            echo ""
            echo "Arguments:"
            echo "  -t, --tag        Docker image tag (default: latest)"
            echo "  -n, --name       Docker image name (default: dashcam)"
            echo "  --no-cache       Build without using cache"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

FULL_IMAGE_NAME="$IMAGE_NAME:$TAG"

echo "Building Docker image for dashcam..."
echo "Image name: $FULL_IMAGE_NAME"
echo "Project root: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

# Build the Docker image
echo "Building Docker image..."
docker build \
    -f docker/Dockerfile \
    -t "$FULL_IMAGE_NAME" \
    $BUILD_ARGS \
    .

echo ""
echo "✅ Docker image built successfully!"
echo "Image: $FULL_IMAGE_NAME"
echo ""
echo "To run the image:"
echo "  docker run --rm $FULL_IMAGE_NAME"
echo ""
echo "To run with Docker Compose:"
echo "  cd docker && docker-compose up"
echo ""
echo "To inspect the image:"
echo "  docker run --rm -it $FULL_IMAGE_NAME /bin/bash"
