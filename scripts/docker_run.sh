#!/bin/bash

# Tiger Style: Always motivate, always say why
# This script runs the dashcam application in a Docker container
# It handles volume mounting and proper signal forwarding

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
IMAGE_NAME="dashcam:latest"
CONTAINER_NAME="dashcam_app"
VOLUME_MOUNT=""
EXTRA_ARGS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -n|--name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -v|--volume)
            VOLUME_MOUNT="-v $2"
            shift 2
            ;;
        -d|--detach)
            EXTRA_ARGS="$EXTRA_ARGS -d"
            shift
            ;;
        --rm)
            EXTRA_ARGS="$EXTRA_ARGS --rm"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-i|--image IMAGE] [-n|--name NAME] [-v|--volume MOUNT] [-d|--detach] [--rm]"
            echo ""
            echo "Arguments:"
            echo "  -i, --image      Docker image to run (default: dashcam:latest)"
            echo "  -n, --name       Container name (default: dashcam_app)"
            echo "  -v, --volume     Volume mount (e.g., /host/path:/container/path)"
            echo "  -d, --detach     Run container in background"
            echo "  --rm             Remove container when it stops"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --rm                    # Run and remove when done"
            echo "  $0 -v /tmp/logs:/app/logs  # Mount logs directory"
            echo "  $0 -d                      # Run in background"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo "Running dashcam Docker container..."
echo "Image: $IMAGE_NAME"
echo "Container name: $CONTAINER_NAME"

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Error: Docker image '$IMAGE_NAME' not found"
    echo "Please build the image first with: ./scripts/docker_build.sh"
    exit 1
fi

# Run the container
echo "Starting container..."
docker run \
    --name "$CONTAINER_NAME" \
    $VOLUME_MOUNT \
    $EXTRA_ARGS \
    "$IMAGE_NAME"

echo ""
echo "Container started successfully!"
echo ""
echo "To view logs:"
echo "  docker logs $CONTAINER_NAME"
echo ""
echo "To stop the container:"
echo "  docker stop $CONTAINER_NAME"
echo ""
echo "To remove the container:"
echo "  docker rm $CONTAINER_NAME"
