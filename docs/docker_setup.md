# Docker Setup and Usage Guide

This guide covers how to use Docker for development, testing, and deployment of the dashcam project.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Development Workflow](#development-workflow)
4. [Production Deployment](#production-deployment)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

### Install Docker

#### Linux (Ubuntu/Debian)
```bash
# Update package index
sudo apt update

# Install Docker
sudo apt install docker.io docker-compose

# Add user to docker group (optional, avoids sudo)
sudo usermod -aG docker $USER

# Log out and back in, or use:
newgrp docker

# Verify installation
docker --version
docker-compose --version
```

#### macOS
```bash
# Install Docker Desktop from https://docker.com/products/docker-desktop
# Or using Homebrew:
brew install --cask docker

# Start Docker Desktop and verify
docker --version
```

#### Windows
1. Install Docker Desktop from https://docker.com/products/docker-desktop
2. Ensure WSL2 is enabled for better performance
3. Verify installation in PowerShell:
```powershell
docker --version
```

## Quick Start

### Build and Run

```bash
# Navigate to project root
cd dashcam

# Build Docker image
./scripts/docker_build.sh

# Run the application
./scripts/docker_run.sh --rm

# Or use Docker Compose
cd docker
docker-compose up
```

## Development Workflow

### 1. Building the Image

#### Basic Build
```bash
./scripts/docker_build.sh
```

#### Custom Build
```bash
# Build with custom tag
./scripts/docker_build.sh -t dashcam:dev

# Build without cache (clean build)
./scripts/docker_build.sh --no-cache

# Build with custom name
./scripts/docker_build.sh -n my-dashcam -t latest
```

#### Manual Docker Build
```bash
# From project root
docker build -f docker/Dockerfile -t dashcam:latest .
```

### 2. Running for Development

#### Interactive Development
```bash
# Run with shell access
docker run --rm -it dashcam:latest /bin/bash

# Mount source code for live editing
docker run --rm -it \
    -v $(pwd)/src:/app/src \
    -v $(pwd)/include:/app/include \
    dashcam:latest /bin/bash

# Inside container, rebuild:
cd /app/build
make -j$(nproc)
```

#### Running Tests in Container
```bash
# Run unit tests
docker run --rm dashcam:latest ./unit_tests

# Run system tests
docker run --rm dashcam:latest python3 -m pytest tests/system/ -v
```

#### Debugging in Container
```bash
# Run with GDB installed
docker run --rm -it \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    dashcam:latest gdb ./dashcam_main
```

### 3. Volume Mounting

#### Persistent Data
```bash
# Create named volumes for data persistence
docker volume create dashcam_data
docker volume create dashcam_logs

# Run with persistent volumes
docker run --rm \
    -v dashcam_data:/app/data \
    -v dashcam_logs:/app/logs \
    dashcam:latest
```

#### Development Mounting
```bash
# Mount entire project for development
docker run --rm -it \
    -v $(pwd):/workspace \
    -w /workspace \
    dashcam:latest /bin/bash

# Mount specific directories
docker run --rm \
    -v $(pwd)/logs:/app/logs \
    -v $(pwd)/data:/app/data \
    dashcam:latest
```

### 4. Multi-Platform Builds

#### Build for Different Architectures
```bash
# Enable Docker buildx (multi-platform builds)
docker buildx create --use

# Build for multiple platforms
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    -f docker/Dockerfile \
    -t dashcam:multi-platform \
    --push .

# Build specifically for Raspberry Pi
docker buildx build \
    --platform linux/arm/v7 \
    -f docker/Dockerfile \
    -t dashcam:raspberry-pi \
    .
```

## Production Deployment

### 1. Using Docker Compose

#### Basic Deployment
```bash
cd docker
docker-compose up -d
```

#### Production Configuration
```yaml
# docker/docker-compose.prod.yml
version: '3.8'

services:
  dashcam:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    container_name: dashcam_production
    restart: always
    volumes:
      - /opt/dashcam/data:/app/data
      - /opt/dashcam/logs:/app/logs
      - /dev/video0:/dev/video0  # Camera device
    devices:
      - /dev/video0:/dev/video0
    environment:
      - LOG_LEVEL=INFO
      - PRODUCTION=true
    networks:
      - dashcam_network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  watchtower:
    image: containrrr/watchtower
    container_name: dashcam_watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_POLL_INTERVAL=3600
    networks:
      - dashcam_network

networks:
  dashcam_network:
    driver: bridge
```

#### Deploy Production
```bash
# Deploy production version
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Update deployment
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

### 2. Raspberry Pi Deployment

#### Cross-compilation Approach
```bash
# Build on development machine for ARM
docker buildx build \
    --platform linux/arm/v7 \
    -f docker/Dockerfile.arm \
    -t dashcam:raspberry-pi \
    --load .

# Save image to tar
docker save dashcam:raspberry-pi | gzip > dashcam-rpi.tar.gz

# Transfer to Raspberry Pi
scp dashcam-rpi.tar.gz pi@raspberry-pi:/tmp/

# On Raspberry Pi: Load and run
ssh pi@raspberry-pi
cd /tmp
gunzip -c dashcam-rpi.tar.gz | docker load
docker run -d --name dashcam_app dashcam:raspberry-pi
```

#### Direct Build on Pi
```bash
# On Raspberry Pi
git clone <repository-url>
cd dashcam
./scripts/docker_build.sh
./scripts/docker_run.sh -d --name dashcam_production
```

### 3. Monitoring and Maintenance

#### Health Checks
```bash
# Check container health
docker ps
docker logs dashcam_app

# Monitor resource usage
docker stats dashcam_app

# Execute commands in running container
docker exec -it dashcam_app /bin/bash
```

#### Backup and Restore
```bash
# Backup data volumes
docker run --rm \
    -v dashcam_data:/data \
    -v $(pwd):/backup \
    alpine tar czf /backup/dashcam_data_backup.tar.gz -C /data .

# Restore data volumes
docker run --rm \
    -v dashcam_data:/data \
    -v $(pwd):/backup \
    alpine tar xzf /backup/dashcam_data_backup.tar.gz -C /data
```

#### Log Management
```bash
# View logs
docker logs dashcam_app

# Follow logs
docker logs -f dashcam_app

# Limit log output
docker logs --tail 100 dashcam_app

# Configure log rotation (in docker-compose.yml)
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## Troubleshooting

### Common Issues

#### 1. Build Failures

```bash
# Clear Docker cache
docker builder prune -a

# Rebuild without cache
./scripts/docker_build.sh --no-cache

# Check Dockerfile syntax
docker run --rm -i hadolint/hadolint < docker/Dockerfile
```

#### 2. Permission Issues

```bash
# Fix file permissions
docker run --rm -v $(pwd):/workspace alpine chown -R $(id -u):$(id -g) /workspace

# Run as specific user
docker run --rm -u $(id -u):$(id -g) dashcam:latest
```

#### 3. Camera Access Issues

```bash
# Check camera device
ls -la /dev/video*

# Add camera device to container
docker run --rm --device /dev/video0:/dev/video0 dashcam:latest

# Check camera permissions
groups $USER
# User should be in 'video' group
```

#### 4. Network Issues

```bash
# Check container networking
docker network ls
docker network inspect bridge

# Test connectivity
docker run --rm alpine ping google.com
```

### Debugging Docker Issues

#### 1. Inspect Container
```bash
# Get container details
docker inspect dashcam_app

# Check container logs
docker logs --details dashcam_app

# Get container stats
docker stats dashcam_app --no-stream
```

#### 2. Debug Build Process
```bash
# Build with verbose output
DOCKER_BUILDKIT=0 docker build --no-cache --progress=plain -f docker/Dockerfile .

# Examine intermediate layers
docker run --rm -it <intermediate_image_id> /bin/bash
```

#### 3. Resource Constraints
```bash
# Check Docker daemon resources
docker system df
docker system info

# Clean up unused resources
docker system prune -a
```

### Performance Optimization

#### 1. Multi-stage Build Optimization
The Dockerfile uses multi-stage builds to minimize final image size:
- Build stage: Contains all build tools and dependencies
- Runtime stage: Only contains runtime requirements

#### 2. Layer Caching
```bash
# Optimize build order in Dockerfile:
# 1. Copy dependency files first
# 2. Install dependencies (cached layer)
# 3. Copy source code
# 4. Build application
```

#### 3. Resource Limits
```yaml
# In docker-compose.yml
services:
  dashcam:
    # ... other config
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### Security Considerations

#### 1. Non-root User
The Dockerfile creates and uses a non-root user for security:
```dockerfile
RUN useradd -m -s /bin/bash dashcam
USER dashcam
```

#### 2. Minimal Attack Surface
- Use minimal base images (Ubuntu vs Alpine)
- Only install required packages
- Use multi-stage builds to exclude build tools

#### 3. Secrets Management
```bash
# Don't include secrets in images
# Use Docker secrets or environment variables
docker run --rm -e API_KEY="$(cat api_key.txt)" dashcam:latest

# Or with Docker Compose secrets
secrets:
  api_key:
    file: ./api_key.txt
```

This completes the Docker setup guide. The configuration provides a solid foundation for both development and production use of the dashcam application.
