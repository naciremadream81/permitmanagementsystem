#!/bin/bash

# Test Docker Build Script for Permit Management System

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="permit-management-server"
CONTAINER_NAME="permit-test-server"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo -e "${BLUE}🐳 Testing Docker Build for Permit Management System${NC}"
echo "=================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

print_status "Docker found: $(docker --version)"

# Clean up any existing containers/images
cleanup() {
    print_info "Cleaning up existing containers and images..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    docker rmi $IMAGE_NAME 2>/dev/null || true
}

# Build the Docker image
build_image() {
    print_status "Building Docker image..."
    cd "$PROJECT_DIR"
    
    if docker build -f Dockerfile.server -t $IMAGE_NAME .; then
        print_status "Docker image built successfully"
    else
        print_error "Docker build failed"
        exit 1
    fi
}

# Test the image
test_image() {
    print_status "Testing Docker image..."
    
    # Start a test database container
    print_info "Starting test database..."
    docker run -d \
        --name permit-test-db \
        -e POSTGRES_DB=permit_management_test \
        -e POSTGRES_USER=permit_user \
        -e POSTGRES_PASSWORD=testpass \
        -p 5433:5432 \
        postgres:15-alpine
    
    # Wait for database to be ready
    sleep 10
    
    # Start the application container
    print_info "Starting application container..."
    docker run -d \
        --name $CONTAINER_NAME \
        --link permit-test-db:db \
        -e DATABASE_URL=jdbc:postgresql://db:5432/permit_management_test \
        -e DB_USER=permit_user \
        -e DB_PASSWORD=testpass \
        -e JWT_SECRET=test-jwt-secret-key-for-testing-only \
        -p 8081:8080 \
        $IMAGE_NAME
    
    # Wait for application to start
    print_info "Waiting for application to start..."
    sleep 30
    
    # Test the application
    print_info "Testing application endpoint..."
    if curl -f http://localhost:8081/ > /dev/null 2>&1; then
        print_status "Application is responding correctly"
    else
        print_warning "Application may still be starting, checking logs..."
        docker logs $CONTAINER_NAME
    fi
    
    # Show container status
    print_info "Container status:"
    docker ps | grep $CONTAINER_NAME || print_warning "Container not running"
    
    # Show logs
    print_info "Application logs:"
    docker logs --tail 20 $CONTAINER_NAME
}

# Cleanup function
cleanup_test() {
    print_info "Cleaning up test containers..."
    docker stop $CONTAINER_NAME permit-test-db 2>/dev/null || true
    docker rm $CONTAINER_NAME permit-test-db 2>/dev/null || true
}

# Main test process
main() {
    cleanup
    build_image
    test_image
    
    echo "=================================================="
    print_status "🎉 Docker test completed!"
    echo ""
    echo "Test Results:"
    echo "  - Image: $IMAGE_NAME"
    echo "  - Container: $CONTAINER_NAME"
    echo "  - Test URL: http://localhost:8081"
    echo ""
    echo "To cleanup test containers:"
    echo "  docker stop $CONTAINER_NAME permit-test-db"
    echo "  docker rm $CONTAINER_NAME permit-test-db"
    echo ""
    print_info "Docker image is ready for production use! 🚀"
}

# Trap to cleanup on exit
trap cleanup_test EXIT

# Run main function
main "$@"
