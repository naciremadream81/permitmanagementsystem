#!/bin/bash

# Production Deployment Script for Permit Management System
set -e

echo "🚀 Starting Production Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    print_error ".env.production file not found!"
    print_status "Creating from template..."
    cp .env.production.template .env.production
    print_warning "Please edit .env.production with your production values before continuing."
    exit 1
fi

# Load environment variables
set -a
source .env.production
set +a

# Validate required environment variables
required_vars=("POSTGRES_PASSWORD" "JWT_SECRET")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "Required environment variable $var is not set in .env.production"
        exit 1
    fi
done

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p backups logs uploads nginx/ssl

# Generate self-signed SSL certificate if it doesn't exist
if [ ! -f "nginx/ssl/cert.pem" ] || [ ! -f "nginx/ssl/key.pem" ]; then
    print_status "Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN:-localhost}"
    print_success "SSL certificate generated"
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker compose -f docker-compose.production.yml down --remove-orphans || true

# Remove old images to force rebuild
print_status "Cleaning up old images..."
docker image prune -f
docker compose -f docker-compose.production.yml build --no-cache

# Start the production environment
print_status "Starting production environment..."
docker compose -f docker-compose.production.yml up -d

# Wait for services to be healthy
print_status "Waiting for services to be healthy..."
sleep 30

# Check service health
services=("permit-db-prod" "permit-redis-prod" "permit-server-prod" "permit-nginx-prod")
for service in "${services[@]}"; do
    if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
        print_success "$service is running"
    else
        print_error "$service failed to start"
        docker logs "$service" --tail 50
        exit 1
    fi
done

# Test API endpoints
print_status "Testing API endpoints..."
sleep 10

# Test health endpoint
if curl -f -s http://localhost/health > /dev/null; then
    print_success "Health endpoint is responding"
else
    print_error "Health endpoint is not responding"
    exit 1
fi

# Test counties endpoint
if curl -f -s http://localhost/counties > /dev/null; then
    print_success "Counties API is responding"
else
    print_error "Counties API is not responding"
    docker logs permit-server-prod --tail 50
    exit 1
fi

# Show running containers
print_status "Production deployment status:"
docker compose -f docker-compose.production.yml ps

# Show logs
print_status "Recent logs:"
docker compose -f docker-compose.production.yml logs --tail 20

print_success "🎉 Production deployment completed successfully!"
print_status "Services are available at:"
echo "  - Web App: http://localhost"
echo "  - Admin Panel: http://localhost/admin"
echo "  - API: http://localhost/counties"
echo "  - Database: localhost:5433"

print_status "To monitor logs: docker compose -f docker-compose.production.yml logs -f"
print_status "To stop services: docker compose -f docker-compose.production.yml down"

# Create backup
print_status "Creating initial database backup..."
./backup-production.sh || print_warning "Backup script not found or failed"

print_success "Production deployment is ready! 🚀"
