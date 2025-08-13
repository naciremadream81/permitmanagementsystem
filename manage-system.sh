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
