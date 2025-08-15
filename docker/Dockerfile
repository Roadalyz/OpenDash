# Multi-stage Docker build for dashcam
# Stage 1: Build environment
FROM ubuntu:22.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    python3 \
    python3-pip \
    pkg-config \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

# Install Conan using uv
RUN uv tool install conan
ENV PATH="/root/.local/bin:$PATH"

# Set up Conan profile
RUN conan profile detect --force

# Create working directory
WORKDIR /app

# Copy Python project files for dependency caching
COPY pyproject.toml .
COPY .python-version .

# Copy dependency files first for better caching
COPY conanfile.txt .
COPY CMakeLists.txt .

# Install Python dependencies using uv
RUN uv sync --extra test --extra docs

# Install C++ dependencies
RUN mkdir build && cd build && \
    conan install .. --output-folder=. --build=missing

# Copy source code
COPY src/ src/
COPY include/ include/
COPY tests/ tests/

# Build the application
RUN cd build && \
    cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake -DCMAKE_BUILD_TYPE=Release && \
    cmake --build . --parallel $(nproc)

# Run tests
RUN cd build && ctest --output-on-failure

# Stage 2: Runtime environment
FROM ubuntu:22.04 AS runtime

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create app user for security
RUN useradd -m -s /bin/bash dashcam

# Create directories
RUN mkdir -p /app/logs /app/data && \
    chown -R dashcam:dashcam /app

# Copy built application
COPY --from=builder /app/build/src/dashcam_main /app/
COPY --from=builder /app/build/tests/unit_tests /app/

# Copy system tests
COPY tests/system/ /app/tests/system/
RUN pip3 install -r /app/tests/system/requirements.txt

# Switch to app user
USER dashcam
WORKDIR /app

# Expose any ports if needed (for future web interface)
# EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD pgrep dashcam_main || exit 1

# Default command
CMD ["./dashcam_main"]
