#!/bin/bash
set -e

# Continue the deployment process after backend success

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

# Backend is already deployed successfully
BACKEND_DEPLOYED=true
print_success "Backend server deployed successfully"

# Build desktop application
print_header "Building Desktop Application"
print_step "Starting desktop app build..."

if [ -f "./deploy-desktop-app.sh" ]; then
    chmod +x ./deploy-desktop-app.sh
    ./deploy-desktop-app.sh
    
    if [ $? -eq 0 ]; then
        print_success "Desktop application built successfully"
        DESKTOP_BUILT=true
    else
        echo -e "${RED}[ERROR]${NC} Desktop application build failed"
        DESKTOP_BUILT=false
    fi
else
    echo -e "${RED}[ERROR]${NC} Desktop deployment script not found"
    DESKTOP_BUILT=false
fi

# Build Android application
print_header "Building Android Application"
print_step "Starting Android app build..."

if [ -f "./deploy-android-app.sh" ]; then
    chmod +x ./deploy-android-app.sh
    ./deploy-android-app.sh
    
    if [ $? -eq 0 ]; then
        print_success "Android application built successfully"
        ANDROID_BUILT=true
    else
        echo -e "${RED}[ERROR]${NC} Android application build failed"
        ANDROID_BUILT=false
    fi
else
    echo -e "${RED}[ERROR]${NC} Android deployment script not found"
    ANDROID_BUILT=false
fi

# Create management tools
print_header "Creating Management Tools"

# Create management dashboard
cat > manage-system.sh << 'EOF'
#!/bin/bash

# Permit Management System - Management Dashboard
# Interactive system management interface

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${CYAN}"
    cat << 'HEADER'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    Permit Management System Dashboard                        ║
║                           System Management Interface                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
HEADER
    echo -e "${NC}"
}

show_status() {
    echo -e "${BLUE}=== System Status ===${NC}"
    
    # Container status
    echo "Container Status:"
    docker-compose -f docker-compose.production.yml ps
    
    echo
    echo "Service Health:"
    
    # Check API
    if curl -sf http://localhost:8081/counties > /dev/null 2>&1; then
        echo -e "✅ API: ${GREEN}Healthy${NC}"
    else
        echo -e "❌ API: ${RED}Failed${NC}"
    fi
    
    # Check database
    if docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U permit_user > /dev/null 2>&1; then
        echo -e "✅ Database: ${GREEN}Healthy${NC}"
    else
        echo -e "❌ Database: ${RED}Failed${NC}"
    fi
    
    # Check Redis
    if docker-compose -f docker-compose.production.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
        echo -e "✅ Redis: ${GREEN}Healthy${NC}"
    else
        echo -e "❌ Redis: ${RED}Failed${NC}"
    fi
    
    echo
    echo "Resource Usage:"
    docker stats --no-stream
    
    echo
    echo "Disk Usage:"
    df -h .
}

show_urls() {
    echo -e "${BLUE}=== Access URLs ===${NC}"
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    
    echo "Local Access:"
    echo "  🌐 Web Application: http://localhost:8081"
    echo "  👨‍💼 Admin Panel: http://localhost:8081/admin"
    echo "  🔌 API Endpoint: http://localhost:8081/counties"
    
    echo
    echo "External Access:"
    echo "  🌐 Web Application: http://$SERVER_IP:8081"
    echo "  👨‍💼 Admin Panel: http://$SERVER_IP:8081/admin"
    echo "  🔌 API Endpoint: http://$SERVER_IP:8081/counties"
    
    echo
    echo "Mobile Apps:"
    if [ -f "dist/android/composeApp-debug.apk" ]; then
        echo "  📱 Android APK: dist/android/composeApp-debug.apk"
    fi
    if [ -d "dist/desktop" ]; then
        echo "  🖥️  Desktop App: dist/desktop/"
    fi
}

main_menu() {
    while true; do
        print_header
        
        echo -e "${PURPLE}System Management Options:${NC}"
        echo "1. 📊 Show system status"
        echo "2. 🌐 Show access URLs"
        echo "3. ⚙️  Restart services"
        echo "4. 📋 View logs"
        echo "5. 💾 Backup system"
        echo "6. 🔄 Refresh dashboard"
        echo "7. 🚪 Exit"
        echo
        echo -n "Select option [1-7]: "
        read OPTION
        
        case $OPTION in
            1) show_status; echo; read -p "Press Enter to continue..." ;;
            2) show_urls; echo; read -p "Press Enter to continue..." ;;
            3) 
                echo "Restarting services..."
                docker-compose -f docker-compose.production.yml restart
                echo "Services restarted."
                read -p "Press Enter to continue..."
                ;;
            4) 
                echo "Showing recent logs..."
                docker-compose -f docker-compose.production.yml logs --tail=50
                read -p "Press Enter to continue..."
                ;;
            5) 
                echo "Creating backup..."
                BACKUP_DIR="./backups"
                DATE=$(date +%Y%m%d_%H%M%S)
                mkdir -p $BACKUP_DIR
                docker-compose -f docker-compose.production.yml exec -T postgres pg_dump -U permit_user permit_management_prod | gzip > "$BACKUP_DIR/database_$DATE.sql.gz"
                echo "Backup created: $BACKUP_DIR/database_$DATE.sql.gz"
                read -p "Press Enter to continue..."
                ;;
            6) continue ;;
            7) echo "Goodbye!"; exit 0 ;;
            *) echo "Invalid option"; sleep 2 ;;
        esac
    done
}

# Start the dashboard
main_menu
EOF

chmod +x manage-system.sh
print_success "Management dashboard created: ./manage-system.sh"

# Create simple management scripts
cat > start-server.sh << 'EOF'
#!/bin/bash
echo "Starting Permit Management System..."
docker-compose -f docker-compose.production.yml up -d
echo "System started. Access at: http://localhost:8081"
EOF

cat > stop-server.sh << 'EOF'
#!/bin/bash
echo "Stopping Permit Management System..."
docker-compose -f docker-compose.production.yml down
echo "System stopped."
EOF

cat > status-server.sh << 'EOF'
#!/bin/bash
echo "=== Permit Management System Status ==="
docker-compose -f docker-compose.production.yml ps
echo
echo "=== Service Health ==="
if curl -sf http://localhost:8081/counties > /dev/null; then
    echo "✅ API: Healthy"
else
    echo "❌ API: Failed"
fi
EOF

chmod +x start-server.sh stop-server.sh status-server.sh
print_success "Management scripts created"

# Display final summary
print_header "🎉 Deployment Complete!"

echo -e "${GREEN}Congratulations! Your Permit Management System is now running!${NC}"
echo
echo "Access URLs:"
echo "  • Web Application: http://localhost:8081"
echo "  • Admin Panel: http://localhost:8081/admin"
echo "  • API Endpoint: http://localhost:8081/counties"

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
if [ "$SERVER_IP" != "localhost" ]; then
    echo "  • External Access: http://${SERVER_IP}:8081"
fi

echo
echo "Management Commands:"
echo "  • System Dashboard: ./manage-system.sh"
echo "  • Start system: ./start-server.sh"
echo "  • Stop system: ./stop-server.sh"
echo "  • Check status: ./status-server.sh"

echo
echo "Distribution Files:"
if [ "$DESKTOP_BUILT" = true ]; then
    echo "  • Desktop App: dist/desktop/"
fi
if [ "$ANDROID_BUILT" = true ]; then
    echo "  • Android APK: dist/android/composeApp-debug.apk"
fi

echo
echo "Next Steps:"
echo "  1. Test the web application at http://localhost:8081"
echo "  2. Create admin user via the admin panel"
echo "  3. Install mobile/desktop apps from dist/ folder"
echo "  4. Configure external access if needed"

echo
print_success "Deployment completed successfully! 🚀"
print_status "Run './manage-system.sh' to access the management dashboard"
EOF

chmod +x continue-deployment.sh
