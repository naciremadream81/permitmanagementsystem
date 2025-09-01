#!/bin/bash

# Complete Setup Script for Permit Management System
# Handles database setup, Java version issues, and web app launching

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Permit Management System - Complete Setup${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Function to check Java version
check_java() {
    if command -v java >/dev/null 2>&1; then
        local java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        echo -e "Java version: ${GREEN}$java_version${NC}"
        
        if [ "$java_version" -ge 21 ]; then
            echo -e "${GREEN}✅ Java version is compatible${NC}"
            return 0
        else
            echo -e "${RED}❌ Java version $java_version is too old. Need Java 21 or higher.${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Java is not installed${NC}"
        return 1
    fi
}

# Function to clean and rebuild with current Java version
rebuild_project() {
    echo -e "${YELLOW}🔧 Cleaning and rebuilding project with current Java version...${NC}"
    
    # Clean everything
    ./gradlew clean --no-daemon
    
    # Rebuild shared module
    echo -e "${YELLOW}📦 Building shared module...${NC}"
    ./gradlew :shared:compileKotlinJvm --no-daemon
    
    # Rebuild server module
    echo -e "${YELLOW}📦 Building server module...${NC}"
    ./gradlew :server:compileKotlin --no-daemon
    
    echo -e "${GREEN}✅ Project rebuilt successfully${NC}"
}

# Function to setup database
setup_database() {
    echo -e "${YELLOW}🗄️  Setting up database...${NC}"
    
    if [ -f "./setup-database-simple.sh" ]; then
        ./setup-database-simple.sh
    else
        echo -e "${RED}❌ Database setup script not found${NC}"
        return 1
    fi
}

# Function to start server
start_server() {
    echo -e "${YELLOW}🚀 Starting server...${NC}"
    
    # Kill any existing server processes
    pkill -f "gradle.*server:run" || true
    sleep 2
    
    # Start server in background
    ./gradlew :server:run --no-daemon &
    local server_pid=$!
    
    echo -e "${GREEN}✅ Server started with PID: $server_pid${NC}"
    
    # Wait for server to start
    echo -e "${YELLOW}⏳ Waiting for server to start...${NC}"
    sleep 15
    
    # Test server
    if curl -s http://localhost:8080/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Server is running and responding${NC}"
        return 0
    else
        echo -e "${RED}❌ Server failed to start or is not responding${NC}"
        return 1
    fi
}

# Function to show web app options
show_web_apps() {
    echo ""
    echo -e "${BLUE}🌐 Web Application Options${NC}"
    echo -e "${BLUE}=========================${NC}"
    echo ""
    echo -e "1. ${YELLOW}Server API:${NC}"
    echo -e "   ${GREEN}http://localhost:8080${NC}"
    echo ""
    echo -e "2. ${YELLOW}Static Web Apps:${NC}"
    echo -e "   ${GREEN}./launch-web-app.sh${NC}"
    echo ""
    echo -e "3. ${YELLOW}Available Web Apps:${NC}"
    
    if [ -d "extra/web-apps" ]; then
        local count=0
        for file in extra/web-apps/*.html; do
            if [ -f "$file" ]; then
                local basename=$(basename "$file")
                local name=$(echo "$basename" | sed 's/\.html$//' | sed 's/web-app-//' | sed 's/-/ /g')
                count=$((count + 1))
                echo -e "   ${GREEN}$count.${NC} $name"
            fi
        done
    fi
    echo ""
}

# Function to show API endpoints
show_api_endpoints() {
    echo -e "${BLUE}🔗 API Endpoints${NC}"
    echo -e "${BLUE}===============${NC}"
    echo ""
    echo -e "${GREEN}Health Check:${NC} http://localhost:8080/health"
    echo -e "${GREEN}API Info:${NC}     http://localhost:8080/api"
    echo -e "${GREEN}Counties:${NC}     http://localhost:8080/counties"
    echo -e "${GREEN}Register:${NC}     http://localhost:8080/auth/register"
    echo -e "${GREEN}Login:${NC}        http://localhost:8080/auth/login"
    echo ""
}

# Function to show usage examples
show_usage_examples() {
    echo -e "${BLUE}📖 Usage Examples${NC}"
    echo -e "${BLUE}=================${NC}"
    echo ""
    echo -e "${YELLOW}Test API:${NC}"
    echo -e "  ${GREEN}curl http://localhost:8080/health${NC}"
    echo -e "  ${GREEN}curl http://localhost:8080/counties${NC}"
    echo ""
    echo -e "${YELLOW}Register a user:${NC}"
    echo -e "  ${GREEN}curl -X POST http://localhost:8080/auth/register \\${NC}"
    echo -e "    ${GREEN}-H \"Content-Type: application/json\" \\${NC}"
    echo -e "    ${GREEN}-d '{\"email\":\"test@example.com\",\"password\":\"password123\",\"firstName\":\"Test\",\"lastName\":\"User\"}'${NC}"
    echo ""
    echo -e "${YELLOW}Launch web apps:${NC}"
    echo -e "  ${GREEN}./launch-web-app.sh${NC}"
    echo ""
}

# Function to show troubleshooting
show_troubleshooting() {
    echo -e "${BLUE}🔧 Troubleshooting${NC}"
    echo -e "${BLUE}==================${NC}"
    echo ""
    echo -e "${YELLOW}If server fails to start:${NC}"
    echo -e "  1. Check Java version: ${GREEN}java -version${NC}"
    echo -e "  2. Clean and rebuild: ${GREEN}./gradlew clean :server:compileKotlin${NC}"
    echo -e "  3. Check database: ${GREEN}./setup-database-simple.sh${NC}"
    echo ""
    echo -e "${YELLOW}If database connection fails:${NC}"
    echo -e "  1. Check PostgreSQL: ${GREEN}pg_isready${NC}"
    echo -e "  2. Restart PostgreSQL: ${GREEN}sudo systemctl restart postgresql${NC}"
    echo ""
    echo -e "${YELLOW}If web apps don't load:${NC}"
    echo -e "  1. Check server: ${GREEN}curl http://localhost:8080/health${NC}"
    echo -e "  2. Launch web server: ${GREEN}./launch-web-app.sh${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${YELLOW}🔍 Checking system requirements...${NC}"
    
    # Check Java
    if ! check_java; then
        echo -e "${RED}❌ Java requirements not met${NC}"
        echo -e "${YELLOW}Please install Java 21 or higher and try again.${NC}"
        exit 1
    fi
    
    echo ""
    
    # Setup database
    if setup_database; then
        echo ""
        
        # Rebuild project
        rebuild_project
        echo ""
        
        # Start server
        if start_server; then
            echo ""
            show_web_apps
            show_api_endpoints
            show_usage_examples
            show_troubleshooting
            
            echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
            echo -e "${GREEN}Your Permit Management System is ready to use.${NC}"
            echo ""
            echo -e "${BLUE}🌐 Quick Access:${NC}"
            echo -e "  ${GREEN}Server:${NC} http://localhost:8080"
            echo -e "  ${GREEN}Health:${NC} http://localhost:8080/health"
            echo -e "  ${GREEN}Web Apps:${NC} ./launch-web-app.sh"
        else
            echo -e "${RED}❌ Server failed to start${NC}"
            echo -e "${YELLOW}Please check the logs and try again.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Database setup failed${NC}"
        exit 1
    fi
}

# Check if running from project root
if [ ! -f "build.gradle.kts" ]; then
    echo -e "${RED}❌ Please run this script from the project root directory${NC}"
    exit 1
fi

# Run main function
main "$@"
