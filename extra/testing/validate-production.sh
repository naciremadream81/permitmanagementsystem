#!/bin/bash

# Permit Management System - Production Validation Script
# This script validates that the system is ready for production deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Permit Management System - Production Readiness Validation${NC}"
echo "=================================================================="

VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((VALIDATION_WARNINGS++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((VALIDATION_ERRORS++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check Java installation
check_java() {
    print_info "Checking Java installation..."
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        JAVA_MAJOR=$(echo $JAVA_VERSION | cut -d'.' -f1)
        if [ "$JAVA_MAJOR" -ge 17 ]; then
            print_success "Java $JAVA_VERSION found (required: 17+)"
        else
            print_error "Java $JAVA_VERSION found, but Java 17+ is required"
        fi
    else
        print_error "Java not found. Please install Java 17 or higher"
    fi
}

# Check environment variables
check_environment_variables() {
    print_info "Checking environment variables..."
    
    # Required variables
    local required_vars=("DATABASE_URL" "DB_USER" "DB_PASSWORD" "JWT_SECRET")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_error "$var is not set"
        else
            case $var in
                "JWT_SECRET")
                    if [ ${#JWT_SECRET} -lt 32 ]; then
                        print_error "JWT_SECRET must be at least 32 characters long (current: ${#JWT_SECRET})"
                    else
                        print_success "$var is set and secure"
                    fi
                    ;;
                "DB_PASSWORD")
                    if [ ${#DB_PASSWORD} -lt 8 ]; then
                        print_warning "DB_PASSWORD should be at least 8 characters long"
                    else
                        print_success "$var is set"
                    fi
                    ;;
                *)
                    print_success "$var is set"
                    ;;
            esac
        fi
    done
    
    # Check for default values
    if [ "$JWT_SECRET" = "your-secret-key-change-in-production" ]; then
        print_error "JWT_SECRET is using default value - SECURITY RISK!"
    fi
    
    if [ "$DB_PASSWORD" = "password" ] || [ "$DB_PASSWORD" = "changeme" ]; then
        print_error "DB_PASSWORD is using a weak default value"
    fi
}

# Check database connectivity
check_database() {
    print_info "Checking database connectivity..."
    
    if [ -z "$DATABASE_URL" ]; then
        print_error "DATABASE_URL not set, skipping database check"
        return
    fi
    
    # Extract database details from URL
    DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\).*/\1/p')
    DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')
    
    if command -v psql &> /dev/null; then
        if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" &> /dev/null; then
            print_success "Database connection successful"
        else
            print_error "Cannot connect to database"
        fi
    else
        print_warning "psql not found, cannot test database connection"
    fi
}

# Check file permissions and directories
check_filesystem() {
    print_info "Checking filesystem permissions..."
    
    # Check if we can create required directories
    local dirs=("logs" "uploads" "data")
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            if mkdir -p "$dir" 2>/dev/null; then
                print_success "Created directory: $dir"
            else
                print_error "Cannot create directory: $dir"
            fi
        else
            if [ -w "$dir" ]; then
                print_success "Directory $dir is writable"
            else
                print_error "Directory $dir is not writable"
            fi
        fi
    done
}

# Check Docker setup (if using Docker)
check_docker() {
    print_info "Checking Docker setup..."
    
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            print_success "Docker is running"
            
            if command -v docker-compose &> /dev/null; then
                print_success "Docker Compose is available"
            else
                print_warning "Docker Compose not found"
            fi
        else
            print_warning "Docker is installed but not running"
        fi
    else
        print_info "Docker not found (not required for direct deployment)"
    fi
}

# Check network connectivity
check_network() {
    print_info "Checking network connectivity..."
    
    local port=${SERVER_PORT:-8080}
    
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep ":$port " &> /dev/null; then
            print_warning "Port $port is already in use"
        else
            print_success "Port $port is available"
        fi
    else
        print_info "netstat not found, cannot check port availability"
    fi
}

# Check security configuration
check_security() {
    print_info "Checking security configuration..."
    
    # Check CORS configuration
    if [ -n "$CORS_ALLOWED_ORIGINS" ]; then
        print_success "CORS origins configured"
    else
        print_warning "CORS_ALLOWED_ORIGINS not set (will allow all origins in development)"
    fi
    
    # Check SSL configuration
    if [ "$SSL_ENABLED" = "true" ]; then
        if [ -n "$SSL_KEYSTORE_PATH" ] && [ -f "$SSL_KEYSTORE_PATH" ]; then
            print_success "SSL keystore found"
        else
            print_error "SSL enabled but keystore not found"
        fi
    else
        print_warning "SSL not enabled (recommended for production)"
    fi
    
    # Check environment
    local env=${ENVIRONMENT:-development}
    if [ "$env" = "production" ]; then
        print_success "Environment set to production"
    else
        print_warning "Environment is set to '$env' (should be 'production' for production deployment)"
    fi
}

# Check build configuration
check_build() {
    print_info "Checking build configuration..."
    
    if [ -f "gradlew" ]; then
        print_success "Gradle wrapper found"
        
        if [ -x "gradlew" ]; then
            print_success "Gradle wrapper is executable"
        else
            print_error "Gradle wrapper is not executable (run: chmod +x gradlew)"
        fi
    else
        print_error "Gradle wrapper not found"
    fi
    
    if [ -f "build.gradle.kts" ]; then
        print_success "Build configuration found"
    else
        print_error "build.gradle.kts not found"
    fi
}

# Check deployment scripts
check_deployment_scripts() {
    print_info "Checking deployment scripts..."
    
    local scripts=("deploy-server.sh" "stop-server.sh")
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                print_success "$script is executable"
            else
                print_warning "$script found but not executable (run: chmod +x $script)"
            fi
        else
            print_error "$script not found"
        fi
    done
}

# Check system resources
check_system_resources() {
    print_info "Checking system resources..."
    
    # Check available memory
    if command -v free &> /dev/null; then
        AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
        if [ "$AVAILABLE_MEM" -gt 2048 ]; then
            print_success "Available memory: ${AVAILABLE_MEM}MB (recommended: 2GB+)"
        elif [ "$AVAILABLE_MEM" -gt 1024 ]; then
            print_warning "Available memory: ${AVAILABLE_MEM}MB (recommended: 2GB+)"
        else
            print_error "Available memory: ${AVAILABLE_MEM}MB (minimum: 1GB)"
        fi
    fi
    
    # Check disk space
    AVAILABLE_DISK=$(df . | awk 'NR==2 {print $4}')
    AVAILABLE_DISK_GB=$((AVAILABLE_DISK / 1024 / 1024))
    
    if [ "$AVAILABLE_DISK_GB" -gt 10 ]; then
        print_success "Available disk space: ${AVAILABLE_DISK_GB}GB (recommended: 10GB+)"
    elif [ "$AVAILABLE_DISK_GB" -gt 5 ]; then
        print_warning "Available disk space: ${AVAILABLE_DISK_GB}GB (recommended: 10GB+)"
    else
        print_error "Available disk space: ${AVAILABLE_DISK_GB}GB (minimum: 5GB)"
    fi
}

# Run all checks
main() {
    check_java
    check_environment_variables
    check_database
    check_filesystem
    check_docker
    check_network
    check_security
    check_build
    check_deployment_scripts
    check_system_resources
    
    echo ""
    echo "=================================================================="
    echo -e "${BLUE}📊 Validation Summary${NC}"
    echo "=================================================================="
    
    if [ $VALIDATION_ERRORS -eq 0 ] && [ $VALIDATION_WARNINGS -eq 0 ]; then
        print_success "All checks passed! System is ready for production deployment."
        echo ""
        echo "Next steps:"
        echo "1. Run: ./deploy-server.sh production"
        echo "2. Test the deployment: curl http://localhost:8080/health"
        echo "3. Monitor logs: tail -f logs/server.log"
        exit 0
    elif [ $VALIDATION_ERRORS -eq 0 ]; then
        print_warning "$VALIDATION_WARNINGS warning(s) found. System can be deployed but should be reviewed."
        echo ""
        echo "Consider addressing the warnings above before production deployment."
        exit 0
    else
        print_error "$VALIDATION_ERRORS error(s) and $VALIDATION_WARNINGS warning(s) found."
        echo ""
        echo "Please fix the errors above before attempting production deployment."
        exit 1
    fi
}

# Run the validation
main "$@"
