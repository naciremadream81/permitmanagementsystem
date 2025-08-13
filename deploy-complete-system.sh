#!/bin/bash
set -e

# Permit Management System - Complete System Deployment
# This script orchestrates the deployment of all components

echo "🚀 Permit Management System - Complete System Deployment"
echo "========================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Display welcome message
display_welcome() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    Permit Management System Deployment                      ║
║                           Complete Production Setup                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo "This script will deploy your complete Permit Management System including:"
    echo "  🏠 Backend Server (API + Database + Web App)"
    echo "  🖥️  Desktop Application (Windows/macOS/Linux)"
    echo "  📱 Android Mobile Application"
    echo "  🌐 Web Application (Admin + User Interface)"
    echo "  🔒 Security Configuration (SSL, Firewall, etc.)"
    echo "  📊 Monitoring & Maintenance Tools"
    echo
    echo "Prerequisites:"
    echo "  • Linux server with Docker support"
    echo "  • Java 17+ for desktop/mobile development"
    echo "  • Internet connection for dependencies"
    echo "  • Sudo privileges for system configuration"
    echo
}

# Get deployment preferences
get_deployment_preferences() {
    print_header "Deployment Configuration"
    
    echo "Select components to deploy:"
    echo
    
    # Backend Server
    echo -n "Deploy Backend Server (API + Database + Web App)? [Y/n]: "
    read DEPLOY_BACKEND
    DEPLOY_BACKEND=${DEPLOY_BACKEND:-Y}
    
    # Desktop App
    echo -n "Build Desktop Application? [Y/n]: "
    read DEPLOY_DESKTOP
    DEPLOY_DESKTOP=${DEPLOY_DESKTOP:-Y}
    
    # Android App
    echo -n "Build Android Application? [Y/n]: "
    read DEPLOY_ANDROID
    DEPLOY_ANDROID=${DEPLOY_ANDROID:-Y}
    
    # Development Environment
    echo -n "Setup Development Environment? [Y/n]: "
    read SETUP_DEV
    SETUP_DEV=${SETUP_DEV:-Y}
    
    echo
    print_status "Deployment configuration:"
    [[ $DEPLOY_BACKEND =~ ^[Yy]$ ]] && print_success "Backend Server: Enabled" || print_warning "Backend Server: Disabled"
    [[ $DEPLOY_DESKTOP =~ ^[Yy]$ ]] && print_success "Desktop App: Enabled" || print_warning "Desktop App: Disabled"
    [[ $DEPLOY_ANDROID =~ ^[Yy]$ ]] && print_success "Android App: Enabled" || print_warning "Android App: Disabled"
    [[ $SETUP_DEV =~ ^[Yy]$ ]] && print_success "Development Setup: Enabled" || print_warning "Development Setup: Disabled"
    echo
    
    echo -n "Continue with this configuration? [Y/n]: "
    read CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]?$ ]]; then
        print_status "Deployment cancelled by user"
        exit 0
    fi
}

# Deploy backend server
deploy_backend_server() {
    if [[ ! $DEPLOY_BACKEND =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_header "Deploying Backend Server"
    print_step "Starting home server deployment..."
    
    if [ -f "./deploy-home-server.sh" ]; then
        chmod +x ./deploy-home-server.sh
        ./deploy-home-server.sh
        
        if [ $? -eq 0 ]; then
            print_success "Backend server deployed successfully"
            BACKEND_DEPLOYED=true
        else
            print_error "Backend server deployment failed"
            BACKEND_DEPLOYED=false
        fi
    else
        print_error "Backend deployment script not found"
        BACKEND_DEPLOYED=false
    fi
}

# Build desktop application
build_desktop_application() {
    if [[ ! $DEPLOY_DESKTOP =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_header "Building Desktop Application"
    print_step "Starting desktop app build..."
    
    if [ -f "./deploy-desktop-app.sh" ]; then
        chmod +x ./deploy-desktop-app.sh
        ./deploy-desktop-app.sh
        
        if [ $? -eq 0 ]; then
            print_success "Desktop application built successfully"
            DESKTOP_BUILT=true
        else
            print_error "Desktop application build failed"
            DESKTOP_BUILT=false
        fi
    else
        print_error "Desktop deployment script not found"
        DESKTOP_BUILT=false
    fi
}

# Build Android application
build_android_application() {
    if [[ ! $DEPLOY_ANDROID =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_header "Building Android Application"
    print_step "Starting Android app build..."
    
    if [ -f "./deploy-android-app.sh" ]; then
        chmod +x ./deploy-android-app.sh
        ./deploy-android-app.sh
        
        if [ $? -eq 0 ]; then
            print_success "Android application built successfully"
            ANDROID_BUILT=true
        else
            print_error "Android application build failed"
            ANDROID_BUILT=false
        fi
    else
        print_error "Android deployment script not found"
        ANDROID_BUILT=false
    fi
}

# Setup development environment
setup_development_environment() {
    if [[ ! $SETUP_DEV =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_header "Setting Up Development Environment"
    print_step "Configuring development tools..."
    
    # Create comprehensive development setup script
    cat > setup-complete-development.sh << 'EOF'
#!/bin/bash
set -e

echo "🛠️  Setting up complete development environment..."

# Install IntelliJ IDEA
echo "Installing IntelliJ IDEA..."
case "$OSTYPE" in
    linux-gnu*)
        if command -v snap &> /dev/null; then
            sudo snap install intellij-idea-community --classic
        else
            echo "Please install IntelliJ IDEA manually from https://www.jetbrains.com/idea/download/"
        fi
        ;;
    darwin*)
        if command -v brew &> /dev/null; then
            brew install --cask intellij-idea-ce
        else
            echo "Please install IntelliJ IDEA manually from https://www.jetbrains.com/idea/download/"
        fi
        ;;
    *)
        echo "Please install IntelliJ IDEA manually from https://www.jetbrains.com/idea/download/"
        ;;
esac

# Install Android Studio
echo "Installing Android Studio..."
case "$OSTYPE" in
    linux-gnu*)
        if command -v snap &> /dev/null; then
            sudo snap install android-studio --classic
        else
            echo "Please install Android Studio manually from https://developer.android.com/studio"
        fi
        ;;
    darwin*)
        if command -v brew &> /dev/null; then
            brew install --cask android-studio
        else
            echo "Please install Android Studio manually from https://developer.android.com/studio"
        fi
        ;;
    *)
        echo "Please install Android Studio manually from https://developer.android.com/studio"
        ;;
esac

# Install useful development tools
echo "Installing development tools..."
case "$OSTYPE" in
    linux-gnu*)
        if command -v apt &> /dev/null; then
            sudo apt install -y git curl wget vim nano htop tree
        fi
        ;;
    darwin*)
        if command -v brew &> /dev/null; then
            brew install git curl wget vim nano htop tree
        fi
        ;;
esac

echo "✅ Development environment setup complete!"
echo
echo "Next steps:"
echo "1. Open IntelliJ IDEA and import this project"
echo "2. Open Android Studio and import this project"
echo "3. Configure your server URL in the apps"
echo "4. Start developing!"
EOF
    
    chmod +x setup-complete-development.sh
    ./setup-complete-development.sh
    
    print_success "Development environment configured"
    DEV_SETUP=true
}

# Create comprehensive documentation
create_documentation() {
    print_header "Creating Documentation"
    print_step "Generating deployment documentation..."
    
    # Create deployment summary
    cat > DEPLOYMENT_SUMMARY.md << EOF
# 🎉 Permit Management System - Deployment Summary

## Deployment Status

**Date**: $(date)
**System**: $(uname -a)
**User**: $(whoami)

### Components Deployed

EOF
    
    if [[ $DEPLOY_BACKEND =~ ^[Yy]$ ]]; then
        if [ "$BACKEND_DEPLOYED" = true ]; then
            echo "- ✅ **Backend Server**: Successfully deployed" >> DEPLOYMENT_SUMMARY.md
            echo "  - API Server: http://localhost:8081" >> DEPLOYMENT_SUMMARY.md
            echo "  - Web Application: http://localhost:8081" >> DEPLOYMENT_SUMMARY.md
            echo "  - Admin Panel: http://localhost:8081/admin" >> DEPLOYMENT_SUMMARY.md
            echo "  - Database: PostgreSQL on port 5433" >> DEPLOYMENT_SUMMARY.md
        else
            echo "- ❌ **Backend Server**: Deployment failed" >> DEPLOYMENT_SUMMARY.md
        fi
    else
        echo "- ⏭️ **Backend Server**: Skipped" >> DEPLOYMENT_SUMMARY.md
    fi
    
    if [[ $DEPLOY_DESKTOP =~ ^[Yy]$ ]]; then
        if [ "$DESKTOP_BUILT" = true ]; then
            echo "- ✅ **Desktop Application**: Successfully built" >> DEPLOYMENT_SUMMARY.md
            echo "  - Distribution: dist/desktop/" >> DEPLOYMENT_SUMMARY.md
            echo "  - Executable: Available for current OS" >> DEPLOYMENT_SUMMARY.md
        else
            echo "- ❌ **Desktop Application**: Build failed" >> DEPLOYMENT_SUMMARY.md
        fi
    else
        echo "- ⏭️ **Desktop Application**: Skipped" >> DEPLOYMENT_SUMMARY.md
    fi
    
    if [[ $DEPLOY_ANDROID =~ ^[Yy]$ ]]; then
        if [ "$ANDROID_BUILT" = true ]; then
            echo "- ✅ **Android Application**: Successfully built" >> DEPLOYMENT_SUMMARY.md
            echo "  - Debug APK: dist/android/composeApp-debug.apk" >> DEPLOYMENT_SUMMARY.md
            echo "  - Release APK: dist/android/composeApp-release.apk" >> DEPLOYMENT_SUMMARY.md
        else
            echo "- ❌ **Android Application**: Build failed" >> DEPLOYMENT_SUMMARY.md
        fi
    else
        echo "- ⏭️ **Android Application**: Skipped" >> DEPLOYMENT_SUMMARY.md
    fi
    
    cat >> DEPLOYMENT_SUMMARY.md << 'EOF'

## Quick Start Guide

### 1. Access Your System
- **Web App**: http://localhost:8081
- **Admin Panel**: http://localhost:8081/admin
- **API**: http://localhost:8081/counties

### 2. Management Commands
```bash
# Start system
./start-server.sh

# Stop system
./stop-server.sh

# Check status
./status-server.sh

# Monitor system
./monitor-system.sh

# Backup system
./backup-system.sh
```

### 3. Mobile & Desktop Apps
- **Desktop**: Run `./gradlew :composeApp:run` or use built installer
- **Android**: Install APK from `dist/android/` folder
- **Development**: Use IntelliJ IDEA or Android Studio

### 4. Configuration
- **Environment**: `.env.production`
- **SSL Certificates**: `nginx/ssl/`
- **Database**: PostgreSQL on port 5433
- **Logs**: `docker-compose -f docker-compose.production.yml logs`

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │    │  Desktop App    │    │   Mobile App    │
│   (Port 8081)   │    │   (Compose)     │    │   (Android)     │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Nginx Proxy   │
                    │   (Port 8081)   │
                    └─────────┬───────┘
                              │
                    ┌─────────────────┐
                    │  Kotlin Server  │
                    │   (Port 8080)   │
                    └─────────┬───────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   PostgreSQL    │  │     Redis       │  │   File Storage  │
│   (Port 5433)   │  │    (Cache)      │  │   (Uploads)     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Security Features
- JWT-based authentication
- bcrypt password hashing
- Rate limiting (10 req/s API, 5 req/s auth)
- CORS protection
- Security headers (XSS, CSRF, etc.)
- SSL/HTTPS support
- Input validation and sanitization

## Monitoring & Maintenance
- Health checks for all services
- Automated daily backups
- Log rotation and management
- Resource usage monitoring
- Container restart policies

## Support & Documentation
- **Complete Guide**: COMPLETE_PRODUCTION_DEPLOYMENT_GUIDE.md
- **API Documentation**: Available at `/api-docs` endpoint
- **Database Schema**: DATABASE_SETUP_GUIDE.md
- **Troubleshooting**: Check logs and health status

## Next Steps
1. Test all components thoroughly
2. Configure external access (domain, SSL)
3. Set up monitoring and alerting
4. Plan regular maintenance schedule
5. Consider scaling options as needed

---

**🎉 Congratulations! Your Permit Management System is fully deployed and ready for production use!**
EOF
    
    print_success "Documentation created: DEPLOYMENT_SUMMARY.md"
}

# Create management dashboard
create_management_dashboard() {
    print_header "Creating Management Dashboard"
    print_step "Setting up system management tools..."
    
    # Create comprehensive management script
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

show_logs() {
    echo -e "${BLUE}=== System Logs ===${NC}"
    echo "1. Server logs"
    echo "2. Database logs"
    echo "3. Nginx logs"
    echo "4. All logs"
    echo "5. Back to main menu"
    echo
    echo -n "Select option [1-5]: "
    read LOG_OPTION
    
    case $LOG_OPTION in
        1) docker-compose -f docker-compose.production.yml logs -f server ;;
        2) docker-compose -f docker-compose.production.yml logs -f postgres ;;
        3) docker-compose -f docker-compose.production.yml logs -f nginx ;;
        4) docker-compose -f docker-compose.production.yml logs -f ;;
        5) return ;;
        *) echo "Invalid option" ;;
    esac
}

manage_services() {
    echo -e "${BLUE}=== Service Management ===${NC}"
    echo "1. Start all services"
    echo "2. Stop all services"
    echo "3. Restart all services"
    echo "4. Restart specific service"
    echo "5. Back to main menu"
    echo
    echo -n "Select option [1-5]: "
    read SERVICE_OPTION
    
    case $SERVICE_OPTION in
        1) 
            echo "Starting all services..."
            docker-compose -f docker-compose.production.yml up -d
            ;;
        2) 
            echo "Stopping all services..."
            docker-compose -f docker-compose.production.yml down
            ;;
        3) 
            echo "Restarting all services..."
            docker-compose -f docker-compose.production.yml restart
            ;;
        4) 
            echo "Available services: server, postgres, redis, nginx"
            echo -n "Enter service name: "
            read SERVICE_NAME
            docker-compose -f docker-compose.production.yml restart $SERVICE_NAME
            ;;
        5) return ;;
        *) echo "Invalid option" ;;
    esac
}

backup_system() {
    echo -e "${BLUE}=== System Backup ===${NC}"
    
    BACKUP_DIR="./backups"
    DATE=$(date +%Y%m%d_%H%M%S)
    mkdir -p $BACKUP_DIR
    
    echo "Creating system backup..."
    
    # Database backup
    echo "Backing up database..."
    docker-compose -f docker-compose.production.yml exec -T postgres pg_dump -U permit_user permit_management_prod | gzip > "$BACKUP_DIR/database_$DATE.sql.gz"
    
    # Files backup
    echo "Backing up uploads..."
    tar -czf "$BACKUP_DIR/uploads_$DATE.tar.gz" uploads/ 2>/dev/null || true
    
    # Configuration backup
    echo "Backing up configuration..."
    tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" .env.production nginx/ssl/ docker-compose.production.yml 2>/dev/null || true
    
    echo -e "${GREEN}Backup completed:${NC}"
    echo "  Database: $BACKUP_DIR/database_$DATE.sql.gz"
    echo "  Uploads: $BACKUP_DIR/uploads_$DATE.tar.gz"
    echo "  Config: $BACKUP_DIR/config_$DATE.tar.gz"
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
    echo "  📱 Android APK: dist/android/composeApp-debug.apk"
    echo "  🖥️  Desktop App: dist/desktop/"
}

main_menu() {
    while true; do
        print_header
        
        echo -e "${PURPLE}System Management Options:${NC}"
        echo "1. 📊 Show system status"
        echo "2. 📋 View logs"
        echo "3. ⚙️  Manage services"
        echo "4. 💾 Backup system"
        echo "5. 🌐 Show access URLs"
        echo "6. 🔄 Refresh dashboard"
        echo "7. 🚪 Exit"
        echo
        echo -n "Select option [1-7]: "
        read OPTION
        
        case $OPTION in
            1) show_status; echo; read -p "Press Enter to continue..." ;;
            2) show_logs; echo; read -p "Press Enter to continue..." ;;
            3) manage_services; echo; read -p "Press Enter to continue..." ;;
            4) backup_system; echo; read -p "Press Enter to continue..." ;;
            5) show_urls; echo; read -p "Press Enter to continue..." ;;
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
}

# Display final deployment summary
display_final_summary() {
    print_header "🎉 Complete System Deployment Summary"
    
    echo -e "${GREEN}Congratulations! Your Permit Management System deployment is complete!${NC}"
    echo
    
    # Deployment status
    echo -e "${CYAN}📊 Deployment Status:${NC}"
    if [[ $DEPLOY_BACKEND =~ ^[Yy]$ ]]; then
        if [ "$BACKEND_DEPLOYED" = true ]; then
            echo -e "  ✅ Backend Server: ${GREEN}Successfully deployed${NC}"
        else
            echo -e "  ❌ Backend Server: ${RED}Deployment failed${NC}"
        fi
    fi
    
    if [[ $DEPLOY_DESKTOP =~ ^[Yy]$ ]]; then
        if [ "$DESKTOP_BUILT" = true ]; then
            echo -e "  ✅ Desktop App: ${GREEN}Successfully built${NC}"
        else
            echo -e "  ❌ Desktop App: ${RED}Build failed${NC}"
        fi
    fi
    
    if [[ $DEPLOY_ANDROID =~ ^[Yy]$ ]]; then
        if [ "$ANDROID_BUILT" = true ]; then
            echo -e "  ✅ Android App: ${GREEN}Successfully built${NC}"
        else
            echo -e "  ❌ Android App: ${RED}Build failed${NC}"
        fi
    fi
    
    echo
    
    # Access information
    if [ "$BACKEND_DEPLOYED" = true ]; then
        echo -e "${CYAN}🌐 Access Your System:${NC}"
        echo "  • Web Application: http://localhost:8081"
        echo "  • Admin Panel: http://localhost:8081/admin"
        echo "  • API Endpoint: http://localhost:8081/counties"
        echo
    fi
    
    # Management commands
    echo -e "${CYAN}🛠️  Management Commands:${NC}"
    echo "  • System Dashboard: ./manage-system.sh"
    echo "  • Start System: ./start-server.sh"
    echo "  • Stop System: ./stop-server.sh"
    echo "  • Check Status: ./status-server.sh"
    echo "  • Monitor System: ./monitor-system.sh"
    echo "  • Backup System: ./backup-system.sh"
    echo
    
    # Distribution files
    echo -e "${CYAN}📦 Distribution Files:${NC}"
    if [ "$DESKTOP_BUILT" = true ]; then
        echo "  • Desktop App: dist/desktop/"
    fi
    if [ "$ANDROID_BUILT" = true ]; then
        echo "  • Android APK: dist/android/composeApp-debug.apk"
    fi
    echo "  • Documentation: DEPLOYMENT_SUMMARY.md"
    echo
    
    # Next steps
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo "  1. Test your system: http://localhost:8081"
    echo "  2. Create admin user via admin panel"
    echo "  3. Install mobile/desktop apps"
    echo "  4. Configure external access (domain, SSL)"
    echo "  5. Set up monitoring and backups"
    echo
    
    # Support information
    echo -e "${CYAN}📚 Documentation & Support:${NC}"
    echo "  • Complete Guide: COMPLETE_PRODUCTION_DEPLOYMENT_GUIDE.md"
    echo "  • Deployment Summary: DEPLOYMENT_SUMMARY.md"
    echo "  • System Dashboard: ./manage-system.sh"
    echo
    
    echo -e "${GREEN}🎉 Your Permit Management System is ready for production use!${NC}"
    echo -e "${YELLOW}💡 Run './manage-system.sh' to access the management dashboard${NC}"
}

# Main deployment orchestration
main() {
    # Initialize variables
    BACKEND_DEPLOYED=false
    DESKTOP_BUILT=false
    ANDROID_BUILT=false
    DEV_SETUP=false
    
    display_welcome
    get_deployment_preferences
    
    print_header "Starting Complete System Deployment"
    
    # Deploy components based on user preferences
    deploy_backend_server
    build_desktop_application
    build_android_application
    setup_development_environment
    
    # Create management tools and documentation
    create_documentation
    create_management_dashboard
    
    # Display final summary
    display_final_summary
    
    echo
    print_status "Complete system deployment finished!"
    print_status "Run './manage-system.sh' to access the management dashboard"
}

# Run main function
main "$@"
