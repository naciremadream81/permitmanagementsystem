#!/bin/bash

# Florida Permit Management System - Production Web Monitoring Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

COMPOSE_FILE="docker-compose.full-prod.yml"
ENV_FILE=".env.prod.local"

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} Production Web App Monitoring${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

check_service_health() {
    local service_name=$1
    local url=$2
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "✅ ${GREEN}$service_name${NC} - Healthy"
        return 0
    else
        echo -e "❌ ${RED}$service_name${NC} - Unhealthy"
        return 1
    fi
}

show_container_status() {
    echo -e "${BLUE}Container Status:${NC}"
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
    echo ""
}

show_service_health() {
    echo -e "${BLUE}Service Health Checks:${NC}"
    
    local all_healthy=true
    
    check_service_health "Web Application" "http://localhost/" || all_healthy=false
    check_service_health "API Direct" "http://localhost/counties" || all_healthy=false
    check_service_health "API Proxy" "http://localhost/api/counties" || all_healthy=false
    check_service_health "Health Endpoint" "http://localhost/health" || all_healthy=false
    
    echo ""
    
    if [ "$all_healthy" = true ]; then
        echo -e "${GREEN}🎉 All services are healthy!${NC}"
    else
        echo -e "${RED}⚠️  Some services are unhealthy${NC}"
    fi
    echo ""
}

show_resource_usage() {
    echo -e "${BLUE}Resource Usage:${NC}"
    
    # Get container stats
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
        permit-nginx-prod permit-server-prod permit-db-prod permit-redis-prod 2>/dev/null || \
        echo "Unable to get container stats"
    echo ""
}

show_recent_logs() {
    echo -e "${BLUE}Recent Nginx Access Logs (last 5):${NC}"
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=5 nginx 2>/dev/null | \
        grep -E "GET|POST|PUT|DELETE" || echo "No recent access logs"
    echo ""
}

show_api_stats() {
    echo -e "${BLUE}API Statistics:${NC}"
    
    # Get county count
    local county_count=$(curl -s http://localhost/counties 2>/dev/null | jq length 2>/dev/null || echo "N/A")
    echo "Counties available: $county_count"
    
    # Test response time
    local start_time=$(date +%s%N)
    curl -s http://localhost/counties > /dev/null 2>&1
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 ))
    echo "API response time: ${response_time}ms"
    
    echo ""
}

show_urls() {
    echo -e "${BLUE}Access URLs:${NC}"
    echo "🌐 Web Application: http://localhost/"
    echo "🔧 API Direct:     http://localhost/counties"
    echo "🔧 API Proxy:      http://localhost/api/counties"
    echo "❤️  Health Check:   http://localhost/health"
    echo "📊 Demo Page:      http://localhost/demo.html"
    echo ""
}

continuous_monitor() {
    while true; do
        clear
        print_header
        show_container_status
        show_service_health
        show_resource_usage
        show_api_stats
        show_recent_logs
        show_urls
        
        echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}"
        echo "Refreshing in 30 seconds..."
        sleep 30
    done
}

# Handle script arguments
case "${1:-status}" in
    "status")
        print_header
        show_container_status
        show_service_health
        show_urls
        ;;
    "health")
        print_header
        show_service_health
        ;;
    "stats")
        print_header
        show_resource_usage
        show_api_stats
        ;;
    "logs")
        print_header
        show_recent_logs
        ;;
    "watch"|"continuous")
        continuous_monitor
        ;;
    *)
        echo "Usage: $0 [status|health|stats|logs|watch]"
        echo "  status - Show overall status (default)"
        echo "  health - Check service health"
        echo "  stats  - Show resource usage and API stats"
        echo "  logs   - Show recent logs"
        echo "  watch  - Continuous monitoring (refresh every 30s)"
        exit 1
        ;;
esac
