#!/bin/bash

# Florida Permit Management System - Production Web Deployment Script
# This script deploys the full production environment with Nginx web server

set -e

echo "🚀 Florida Permit Management System - Production Web Deployment"
echo "=============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.full-prod.yml"
ENV_FILE=".env.prod.local"

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

# Check if required files exist
check_requirements() {
    print_status "Checking requirements..."
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "Docker Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    if [ ! -f "$ENV_FILE" ]; then
        print_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
    
    if [ ! -f "web-app-production.html" ]; then
        print_error "Production web app file not found: web-app-production.html"
        exit 1
    fi
    
    if [ ! -f "nginx/nginx-web.conf" ]; then
        print_error "Nginx configuration not found: nginx/nginx-web.conf"
        exit 1
    fi
    
    print_success "All required files found"
}

# Function to stop existing containers
stop_containers() {
    print_status "Stopping existing containers..."
    
    # Stop any running containers
    if docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps -q | grep -q .; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down
        print_success "Existing containers stopped"
    else
        print_status "No existing containers to stop"
    fi
}

# Function to start containers
start_containers() {
    print_status "Starting production containers..."
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --build
    
    print_success "Containers started"
}

# Function to wait for services to be healthy
wait_for_services() {
    print_status "Waiting for services to be healthy..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps | grep -q "healthy"; then
            local healthy_count=$(docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps | grep -c "healthy" || true)
            local total_services=4  # postgres, server, redis, nginx
            
            if [ "$healthy_count" -ge 3 ]; then  # Allow nginx to still be starting
                print_success "Services are healthy"
                return 0
            fi
        fi
        
        print_status "Attempt $attempt/$max_attempts - Waiting for services..."
        sleep 5
        ((attempt++))
    done
    
    print_warning "Services may still be starting up"
}

# Function to test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Test web app
    if curl -s -f http://localhost/ > /dev/null; then
        print_success "✅ Web app is accessible"
    else
        print_error "❌ Web app is not accessible"
        return 1
    fi
    
    # Test API direct access
    if curl -s -f http://localhost/counties > /dev/null; then
        print_success "✅ Direct API access working"
    else
        print_error "❌ Direct API access failed"
        return 1
    fi
    
    # Test API proxy
    if curl -s -f http://localhost/api/counties > /dev/null; then
        print_success "✅ API proxy working"
    else
        print_error "❌ API proxy failed"
        return 1
    fi
    
    # Test health endpoint
    if curl -s -f http://localhost/health > /dev/null; then
        print_success "✅ Health check working"
    else
        print_error "❌ Health check failed"
        return 1
    fi
    
    print_success "All tests passed!"
}

# Function to show deployment info
show_deployment_info() {
    echo ""
    echo "🎉 Production Web Deployment Complete!"
    echo "======================================"
    echo ""
    echo "📱 Web Application:"
    echo "   URL: http://localhost/"
    echo "   Features: Live county data, API testing, responsive design"
    echo ""
    echo "🔧 API Endpoints:"
    echo "   Direct API: http://localhost/counties"
    echo "   Proxy API:  http://localhost/api/counties"
    echo "   Health:     http://localhost/health"
    echo ""
    echo "🐳 Docker Services:"
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
    echo ""
    echo "📊 Service Status:"
    echo "   Database: PostgreSQL on port 5433"
    echo "   API Server: Kotlin/Ktor backend"
    echo "   Cache: Redis"
    echo "   Web Server: Nginx on port 80"
    echo ""
    echo "🔍 Monitoring Commands:"
    echo "   View logs: docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE logs -f"
    echo "   Stop all:  docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE down"
    echo "   Restart:   ./deploy-web-production.sh"
    echo ""
}

# Main deployment process
main() {
    check_requirements
    stop_containers
    start_containers
    wait_for_services
    
    if test_deployment; then
        show_deployment_info
    else
        print_error "Deployment tests failed. Check the logs for details."
        echo "Debug commands:"
        echo "  docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE logs"
        echo "  docker-compose -f $COMPOSE_FILE --env-file $ENV_FILE ps"
        exit 1
    fi
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "stop")
        print_status "Stopping production deployment..."
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down
        print_success "Production deployment stopped"
        ;;
    "status")
        print_status "Production deployment status:"
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
        ;;
    "logs")
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f
        ;;
    "test")
        test_deployment
        ;;
    *)
        echo "Usage: $0 [deploy|stop|status|logs|test]"
        echo "  deploy - Deploy the production environment (default)"
        echo "  stop   - Stop all containers"
        echo "  status - Show container status"
        echo "  logs   - Show and follow logs"
        echo "  test   - Test the deployment"
        exit 1
        ;;
esac
