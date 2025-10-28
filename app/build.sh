#!/bin/bash

# Build script for IP Display Application
# This script builds and tests the Docker image locally

set -e  # Exit on any error

# Configuration
IMAGE_NAME="ip-display-app"
TAG="latest"
CONTAINER_NAME="ip-display-test"

echo "🚀 Building IP Display Application..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build the Docker image
echo "📦 Building Docker image: ${IMAGE_NAME}:${TAG}"
docker build -t "${IMAGE_NAME}:${TAG}" .

if [ $? -eq 0 ]; then
    echo "✅ Docker image built successfully!"
else
    echo "❌ Docker build failed!"
    exit 1
fi

# Test the image
echo "🧪 Testing the application..."

# Stop and remove existing container if it exists
docker stop "${CONTAINER_NAME}" 2>/dev/null || true
docker rm "${CONTAINER_NAME}" 2>/dev/null || true

# Run the container
echo "🏃 Starting container..."
docker run -d --name "${CONTAINER_NAME}" -p 5000:5000 "${IMAGE_NAME}:${TAG}"

# Wait for the application to start
echo "⏳ Waiting for application to start..."
sleep 5

# Test the health endpoint
echo "🔍 Testing health endpoint..."
if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Health check passed!"
else
    echo "❌ Health check failed!"
    docker logs "${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}"
    docker rm "${CONTAINER_NAME}"
    exit 1
fi

# Test the main endpoint
echo "🔍 Testing main endpoint..."
if curl -f http://localhost:5000/ > /dev/null 2>&1; then
    echo "✅ Main endpoint is working!"
    echo ""
    echo "🌐 Application is running at: http://localhost:5000"
    echo "📊 Health check available at: http://localhost:5000/health"
    echo ""
    echo "To stop the test container, run:"
    echo "  docker stop ${CONTAINER_NAME}"
    echo "  docker rm ${CONTAINER_NAME}"
else
    echo "❌ Main endpoint test failed!"
    docker logs "${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}"
    docker rm "${CONTAINER_NAME}"
    exit 1
fi

echo ""
echo "🎉 Build and test completed successfully!"
echo "📝 Image: ${IMAGE_NAME}:${TAG}"
echo "📦 Container: ${CONTAINER_NAME}"
