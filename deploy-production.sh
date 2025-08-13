#!/bin/bash

set -e

echo "🚀 Deploying Permit Management System to Production"
echo "=================================================="

# Configuration
ENV_FILE=".env.prod.local"
COMPOSE_FILE="docker-compose.simple-prod.yml"
BACKUP_DIR="./backups"
LOG_DIR="./logs"
UPLOAD_DIR="./uploads"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should not be run as root for security reasons"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Environment file $ENV_FILE not found!"
    log_info "Please run ./setup-production-database.sh first to create the environment file."
    exit 1
fi

# Validate environment variables
log_info "Validating environment configuration..."
source "$ENV_FILE"

if [[ -z "$POSTGRES_PASSWORD" || "$POSTGRES_PASSWORD" == "your-very-secure-database-password-here" ]]; then
    log_error "Please set a secure POSTGRES_PASSWORD in $ENV_FILE"
    exit 1
fi

if [[ -z "$JWT_SECRET" || "$JWT_SECRET" == "your-super-secure-jwt-secret-key-that-is-at-least-32-characters-long-for-production" ]]; then
    log_error "Please set a secure JWT_SECRET in $ENV_FILE"
    exit 1
fi

if [[ ${#JWT_SECRET} -lt 32 ]]; then
    log_error "JWT_SECRET must be at least 32 characters long"
    exit 1
fi

# Check if PostgreSQL is running on host
log_info "Checking host PostgreSQL service..."
if ! sudo systemctl is-active --quiet postgresql; then
    log_warn "PostgreSQL is not running on host. Starting it..."
    sudo systemctl start postgresql
fi

# Test database connection
log_info "Testing database connection..."
if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" > /dev/null 2>&1; then
    log_error "Cannot connect to host database. Please check your database setup."
    log_info "Run: ./setup-production-database.sh"
    exit 1
fi

# Create necessary directories (only local ones)
log_info "Creating necessary directories..."
mkdir -p "$BACKUP_DIR" "$LOG_DIR" "$UPLOAD_DIR"

# Set proper permissions
chmod 755 "$BACKUP_DIR" "$LOG_DIR" "$UPLOAD_DIR"

# Stop existing containers
log_info "Stopping existing containers..."
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down || true

# Pull latest images
log_info "Pulling latest images..."
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull redis || true

# Build application
log_info "Building application..."
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build --no-cache server

# Start services
log_info "Starting services..."
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

# Wait for services to be healthy
log_info "Waiting for services to be healthy..."
sleep 30

# Check service health
log_info "Checking service health..."
for i in {1..30}; do
    if docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps | grep -q "Up"; then
        log_info "Services are running!"
        break
    fi
    if [[ $i -eq 30 ]]; then
        log_error "Services failed to start"
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs
        exit 1
    fi
    sleep 10
done

# Test API endpoints
log_info "Testing API endpoints..."
sleep 10

# Test direct server connection first
TEST_URL="http://localhost:8080"
log_info "Testing direct server connection..."

# Test counties endpoint
if curl -f "$TEST_URL/counties" > /dev/null 2>&1; then
    log_info "✅ Counties endpoint is working"
else
    log_error "❌ Counties endpoint failed"
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs server
    exit 1
fi

# Show running containers
log_info "Running containers:"
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps

# Show logs
log_info "Recent logs:"
docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=20

echo ""
log_info "🎉 Production deployment completed successfully!"
echo ""
log_info "📝 Service URLs:"
log_info "   - API: http://localhost:8080"
log_info "   - Database: localhost:5432 (host PostgreSQL)"
echo ""
log_info "🔧 Management commands:"
log_info "   - View logs: docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE logs [service]"
log_info "   - Stop: docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE down"
log_info "   - Restart: docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE restart [service]"
log_info "   - Update: ./deploy-production.sh"
echo ""
log_info "📊 Monitor with:"
log_info "   - docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE ps"
log_info "   - docker stats"
