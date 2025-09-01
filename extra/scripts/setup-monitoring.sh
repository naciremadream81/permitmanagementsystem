#!/bin/bash

# Setup Monitoring and Alerting for Permit Management System
# This script sets up comprehensive monitoring for the application

set -e

echo "🔧 Setting up monitoring and alerting for Permit Management System..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if required tools are installed
check_dependencies() {
    print_info "Checking dependencies..."
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed. Installing..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        elif command -v brew &> /dev/null; then
            brew install jq
        else
            print_error "Cannot install jq automatically. Please install it manually."
            exit 1
        fi
    fi
    
    print_status "Dependencies check completed"
}

# Create monitoring directory structure
setup_directories() {
    print_info "Setting up monitoring directories..."
    
    mkdir -p monitoring/{logs,scripts,configs,alerts}
    mkdir -p monitoring/logs/{application,errors,performance}
    mkdir -p monitoring/scripts/{health-checks,alerts,reports}
    mkdir -p monitoring/configs/{prometheus,grafana,alertmanager}
    mkdir -p monitoring/alerts/{email,slack,webhook}
    
    print_status "Monitoring directories created"
}

# Create health check script
create_health_check_script() {
    print_info "Creating health check script..."
    
    cat > monitoring/scripts/health-checks/application-health.sh << 'EOF'
#!/bin/bash

# Application Health Check Script
# This script performs comprehensive health checks on the Permit Management System

set -e

# Configuration
BASE_URL="http://localhost:8080"
LOG_FILE="monitoring/logs/application/health-check-$(date +%Y%m%d).log"
ALERT_EMAIL="admin@example.com"
SLACK_WEBHOOK=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if service is running
check_service_running() {
    log "Checking if service is running..."
    
    if curl -s -f "$BASE_URL/health" > /dev/null; then
        log "✅ Service is running"
        return 0
    else
        log "❌ Service is not running"
        return 1
    fi
}

# Check basic health endpoint
check_basic_health() {
    log "Checking basic health endpoint..."
    
    response=$(curl -s "$BASE_URL/health")
    if echo "$response" | jq -e '.success' > /dev/null; then
        log "✅ Basic health check passed"
        return 0
    else
        log "❌ Basic health check failed"
        return 1
    fi
}

# Check detailed health endpoint
check_detailed_health() {
    log "Checking detailed health endpoint..."
    
    response=$(curl -s "$BASE_URL/health/detailed")
    if echo "$response" | jq -e '.success' > /dev/null; then
        log "✅ Detailed health check passed"
        
        # Check individual components
        components=$(echo "$response" | jq -r '.data.components[] | "\(.name):\(.status)"')
        while IFS=: read -r name status; do
            if [ "$status" = "UNHEALTHY" ]; then
                log "❌ Component $name is unhealthy"
                return 1
            elif [ "$status" = "DEGRADED" ]; then
                log "⚠️  Component $name is degraded"
            else
                log "✅ Component $name is healthy"
            fi
        done <<< "$components"
        
        return 0
    else
        log "❌ Detailed health check failed"
        return 1
    fi
}

# Check database connectivity
check_database() {
    log "Checking database connectivity..."
    
    response=$(curl -s "$BASE_URL/health/detailed")
    db_status=$(echo "$response" | jq -r '.data.components[] | select(.name=="database") | .status')
    
    if [ "$db_status" = "HEALTHY" ]; then
        log "✅ Database is healthy"
        return 0
    else
        log "❌ Database is unhealthy: $db_status"
        return 1
    fi
}

# Check API endpoints
check_api_endpoints() {
    log "Checking API endpoints..."
    
    endpoints=("/api" "/counties" "/health/ready" "/health/live")
    
    for endpoint in "${endpoints[@]}"; do
        if curl -s -f "$BASE_URL$endpoint" > /dev/null; then
            log "✅ Endpoint $endpoint is accessible"
        else
            log "❌ Endpoint $endpoint is not accessible"
            return 1
        fi
    done
    
    return 0
}

# Check system resources
check_system_resources() {
    log "Checking system resources..."
    
    response=$(curl -s "$BASE_URL/health/metrics")
    memory_usage=$(echo "$response" | jq -r '.data.system.memory_usage_mb // "unknown"')
    
    if [ "$memory_usage" != "unknown" ] && [ "$memory_usage" -gt 1000 ]; then
        log "⚠️  High memory usage: ${memory_usage}MB"
    else
        log "✅ Memory usage is normal: ${memory_usage}MB"
    fi
}

# Send alert
send_alert() {
    local message="$1"
    local severity="$2"
    
    log "🚨 ALERT [$severity]: $message"
    
    # Send email alert (if configured)
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Permit Management System Alert [$severity]" "$ALERT_EMAIL" 2>/dev/null || true
    fi
    
    # Send Slack alert (if configured)
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 Permit Management System Alert [$severity]: $message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Main health check
main() {
    log "Starting health check..."
    
    local overall_status=0
    
    # Run all checks
    check_service_running || overall_status=1
    check_basic_health || overall_status=1
    check_detailed_health || overall_status=1
    check_database || overall_status=1
    check_api_endpoints || overall_status=1
    check_system_resources || overall_status=1
    
    if [ $overall_status -eq 0 ]; then
        log "✅ All health checks passed"
    else
        log "❌ Some health checks failed"
        send_alert "Health check failed. Check logs for details." "CRITICAL"
    fi
    
    log "Health check completed"
    exit $overall_status
}

# Run main function
main "$@"
EOF

    chmod +x monitoring/scripts/health-checks/application-health.sh
    print_status "Health check script created"
}

# Create monitoring configuration
create_monitoring_config() {
    print_info "Creating monitoring configuration..."
    
    cat > monitoring/configs/monitoring.conf << 'EOF'
# Permit Management System Monitoring Configuration

# Application settings
APP_NAME="Permit Management System"
APP_VERSION="1.0.0"
BASE_URL="http://localhost:8080"

# Health check settings
HEALTH_CHECK_INTERVAL=60  # seconds
HEALTH_CHECK_TIMEOUT=30   # seconds
HEALTH_CHECK_RETRIES=3

# Alerting settings
ALERT_EMAIL="admin@example.com"
ALERT_SLACK_WEBHOOK=""
ALERT_PAGERDUTY_KEY=""

# Logging settings
LOG_LEVEL="INFO"
LOG_RETENTION_DAYS=30
LOG_ROTATION_SIZE="100MB"

# Performance monitoring
PERFORMANCE_THRESHOLDS=(
    "response_time_ms:1000"
    "memory_usage_mb:1000"
    "error_rate_percent:5"
    "cpu_usage_percent:80"
)

# Database monitoring
DB_CONNECTION_POOL_SIZE=10
DB_CONNECTION_TIMEOUT=30
DB_QUERY_TIMEOUT=60

# External service monitoring
EXTERNAL_SERVICES=(
    "database:postgresql://localhost:5432/permit_management_dev"
    "redis:redis://localhost:6379"
)

# Notification settings
NOTIFICATION_CHANNELS=(
    "email"
    "slack"
    "webhook"
)

# Escalation settings
ESCALATION_LEVELS=(
    "1:5:email"
    "2:10:slack"
    "3:15:webhook"
)
EOF

    print_status "Monitoring configuration created"
}

# Create alerting script
create_alerting_script() {
    print_info "Creating alerting script..."
    
    cat > monitoring/scripts/alerts/send-alert.sh << 'EOF'
#!/bin/bash

# Alert Sending Script
# This script sends alerts through various channels

set -e

# Configuration
ALERT_EMAIL="admin@example.com"
SLACK_WEBHOOK=""
WEBHOOK_URL=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Usage
usage() {
    echo "Usage: $0 -m <message> -s <severity> [-c <channel>]"
    echo "  -m: Alert message"
    echo "  -s: Severity (INFO, WARNING, CRITICAL)"
    echo "  -c: Channel (email, slack, webhook, all)"
    exit 1
}

# Send email alert
send_email() {
    local message="$1"
    local severity="$2"
    
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "Permit Management System Alert [$severity]" "$ALERT_EMAIL"
        echo "✅ Email alert sent to $ALERT_EMAIL"
    else
        echo "⚠️  Email alert not configured"
    fi
}

# Send Slack alert
send_slack() {
    local message="$1"
    local severity="$2"
    
    if [ -n "$SLACK_WEBHOOK" ]; then
        local color
        case "$severity" in
            "INFO") color="good" ;;
            "WARNING") color="warning" ;;
            "CRITICAL") color="danger" ;;
            *) color="good" ;;
        esac
        
        curl -X POST -H 'Content-type: application/json' \
            --data "{
                \"attachments\": [{
                    \"color\": \"$color\",
                    \"title\": \"Permit Management System Alert\",
                    \"text\": \"$message\",
                    \"fields\": [{
                        \"title\": \"Severity\",
                        \"value\": \"$severity\",
                        \"short\": true
                    }, {
                        \"title\": \"Timestamp\",
                        \"value\": \"$(date)\",
                        \"short\": true
                    }]
                }]
            }" \
            "$SLACK_WEBHOOK"
        
        echo "✅ Slack alert sent"
    else
        echo "⚠️  Slack alert not configured"
    fi
}

# Send webhook alert
send_webhook() {
    local message="$1"
    local severity="$2"
    
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{
                \"message\": \"$message\",
                \"severity\": \"$severity\",
                \"timestamp\": \"$(date -Iseconds)\",
                \"service\": \"permit-management-system\"
            }" \
            "$WEBHOOK_URL"
        
        echo "✅ Webhook alert sent"
    else
        echo "⚠️  Webhook alert not configured"
    fi
}

# Main function
main() {
    local message=""
    local severity="INFO"
    local channel="all"
    
    # Parse arguments
    while getopts "m:s:c:" opt; do
        case $opt in
            m) message="$OPTARG" ;;
            s) severity="$OPTARG" ;;
            c) channel="$OPTARG" ;;
            *) usage ;;
        esac
    done
    
    if [ -z "$message" ]; then
        echo "Error: Message is required"
        usage
    fi
    
    echo "Sending alert: $message (Severity: $severity, Channel: $channel)"
    
    case "$channel" in
        "email") send_email "$message" "$severity" ;;
        "slack") send_slack "$message" "$severity" ;;
        "webhook") send_webhook "$message" "$severity" ;;
        "all")
            send_email "$message" "$severity"
            send_slack "$message" "$severity"
            send_webhook "$message" "$severity"
            ;;
        *) echo "Error: Unknown channel $channel"; exit 1 ;;
    esac
}

# Run main function
main "$@"
EOF

    chmod +x monitoring/scripts/alerts/send-alert.sh
    print_status "Alerting script created"
}

# Create cron job for health checks
setup_cron_job() {
    print_info "Setting up cron job for health checks..."
    
    # Create cron job entry
    cron_entry="*/5 * * * * $(pwd)/monitoring/scripts/health-checks/application-health.sh"
    
    # Add to crontab if not already present
    if ! crontab -l 2>/dev/null | grep -q "application-health.sh"; then
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        print_status "Cron job added for health checks (every 5 minutes)"
    else
        print_warning "Cron job already exists"
    fi
}

# Create monitoring dashboard script
create_dashboard_script() {
    print_info "Creating monitoring dashboard script..."
    
    cat > monitoring/scripts/reports/generate-report.sh << 'EOF'
#!/bin/bash

# Monitoring Report Generator
# This script generates comprehensive monitoring reports

set -e

# Configuration
BASE_URL="http://localhost:8080"
REPORT_DIR="monitoring/reports"
LOG_DIR="monitoring/logs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create report directory
mkdir -p "$REPORT_DIR"

# Generate report
generate_report() {
    local report_file="$REPORT_DIR/monitoring-report-$(date +%Y%m%d-%H%M%S).html"
    
    cat > "$report_file" << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Permit Management System - Monitoring Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .status-healthy { color: green; }
        .status-degraded { color: orange; }
        .status-unhealthy { color: red; }
        .metric { display: inline-block; margin: 10px; padding: 10px; border: 1px solid #ccc; border-radius: 5px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Permit Management System - Monitoring Report</h1>
        <p>Generated on: $(date)</p>
    </div>
HTML

    # Add health status
    echo "<div class='section'>" >> "$report_file"
    echo "<h2>System Health Status</h2>" >> "$report_file"
    
    if curl -s -f "$BASE_URL/health" > /dev/null; then
        echo "<p class='status-healthy'>✅ System is healthy</p>" >> "$report_file"
    else
        echo "<p class='status-unhealthy'>❌ System is unhealthy</p>" >> "$report_file"
    fi
    echo "</div>" >> "$report_file"
    
    # Add metrics
    echo "<div class='section'>" >> "$report_file"
    echo "<h2>System Metrics</h2>" >> "$report_file"
    
    local metrics_response=$(curl -s "$BASE_URL/health/metrics" 2>/dev/null || echo '{}')
    if [ "$metrics_response" != "{}" ]; then
        echo "<div class='metric'>" >> "$report_file"
        echo "<strong>Uptime:</strong> $(echo "$metrics_response" | jq -r '.data.system.uptime_seconds // "unknown"') seconds" >> "$report_file"
        echo "</div>" >> "$report_file"
        
        echo "<div class='metric'>" >> "$report_file"
        echo "<strong>Total Requests:</strong> $(echo "$metrics_response" | jq -r '.data.system.total_requests // "unknown"')" >> "$report_file"
        echo "</div>" >> "$report_file"
        
        echo "<div class='metric'>" >> "$report_file"
        echo "<strong>Total Errors:</strong> $(echo "$metrics_response" | jq -r '.data.system.total_errors // "unknown"')" >> "$report_file"
        echo "</div>" >> "$report_file"
        
        echo "<div class='metric'>" >> "$report_file"
        echo "<strong>Memory Usage:</strong> $(echo "$metrics_response" | jq -r '.data.system.memory_usage_mb // "unknown"') MB" >> "$report_file"
        echo "</div>" >> "$report_file"
    fi
    echo "</div>" >> "$report_file"
    
    # Add component status
    echo "<div class='section'>" >> "$report_file"
    echo "<h2>Component Status</h2>" >> "$report_file"
    echo "<table>" >> "$report_file"
    echo "<tr><th>Component</th><th>Status</th><th>Message</th></tr>" >> "$report_file"
    
    local health_response=$(curl -s "$BASE_URL/health/detailed" 2>/dev/null || echo '{}')
    if [ "$health_response" != "{}" ]; then
        echo "$health_response" | jq -r '.data.components[] | "<tr><td>\(.name)</td><td class=\"status-\(.status | ascii_downcase)\">\(.status)</td><td>\(.message // "N/A")</td></tr>"' >> "$report_file"
    fi
    echo "</table>" >> "$report_file"
    echo "</div>" >> "$report_file"
    
    # Close HTML
    echo "</body></html>" >> "$report_file"
    
    echo "✅ Report generated: $report_file"
}

# Main function
main() {
    echo "Generating monitoring report..."
    generate_report
    echo "✅ Monitoring report generation completed"
}

# Run main function
main "$@"
EOF

    chmod +x monitoring/scripts/reports/generate-report.sh
    print_status "Dashboard script created"
}

# Main setup function
main() {
    echo "🚀 Starting monitoring setup..."
    
    check_dependencies
    setup_directories
    create_health_check_script
    create_monitoring_config
    create_alerting_script
    create_dashboard_script
    setup_cron_job
    
    print_status "Monitoring setup completed successfully!"
    
    echo ""
    echo "📋 Next steps:"
    echo "1. Configure alerting settings in monitoring/configs/monitoring.conf"
    echo "2. Test health checks: ./monitoring/scripts/health-checks/application-health.sh"
    echo "3. Test alerting: ./monitoring/scripts/alerts/send-alert.sh -m 'Test alert' -s INFO"
    echo "4. Generate report: ./monitoring/scripts/reports/generate-report.sh"
    echo "5. View health status: curl http://localhost:8080/health"
    echo ""
    echo "📁 Monitoring files created in: $(pwd)/monitoring/"
}

# Run main function
main "$@"
