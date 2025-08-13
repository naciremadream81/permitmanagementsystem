#!/bin/bash
set -e

# Permit Management System - Home Server Deployment Script
# This script automates the complete deployment process for a home server

echo "🏠 Permit Management System - Home Server Deployment"
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check for required commands
check_dependencies() {
    print_header "Checking Dependencies"
    
    local deps=("curl" "wget" "git" "openssl")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Installing missing dependencies..."
        
        if command -v apt &> /dev/null; then
            sudo apt update
            sudo apt install -y "${missing_deps[@]}"
        elif command -v yum &> /dev/null; then
            sudo yum install -y "${missing_deps[@]}"
        else
            print_error "Unable to install dependencies automatically. Please install: ${missing_deps[*]}"
            exit 1
        fi
    fi
    
    print_status "All dependencies satisfied"
}

# Install Docker if not present
install_docker() {
    print_header "Docker Installation"
    
    if command -v docker &> /dev/null; then
        print_status "Docker already installed: $(docker --version)"
    else
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        print_status "Docker installed successfully"
    fi
    
    if command -v docker-compose &> /dev/null; then
        print_status "Docker Compose already installed: $(docker-compose --version)"
    else
        print_status "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        print_status "Docker Compose installed successfully"
    fi
}

# Configure firewall
configure_firewall() {
    print_header "Firewall Configuration"
    
    if command -v ufw &> /dev/null; then
        print_status "Configuring UFW firewall..."
        sudo ufw --force enable
        sudo ufw allow 22/tcp comment 'SSH'
        sudo ufw allow 80/tcp comment 'HTTP'
        sudo ufw allow 443/tcp comment 'HTTPS'
        sudo ufw allow 8081/tcp comment 'Permit Management App'
        print_status "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        print_status "Configuring firewalld..."
        sudo systemctl enable firewalld
        sudo systemctl start firewalld
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo firewall-cmd --permanent --add-port=8081/tcp
        sudo firewall-cmd --reload
        print_status "Firewalld configured"
    else
        print_warning "No supported firewall found. Please configure manually."
    fi
}

# Generate secure passwords
generate_passwords() {
    print_header "Generating Secure Configuration"
    
    # Generate secure passwords
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    JWT_SECRET=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-48)
    
    print_status "Generated secure database password"
    print_status "Generated secure JWT secret"
}

# Configure environment
configure_environment() {
    print_header "Environment Configuration"
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me || echo "localhost")
    
    # Prompt for domain name
    echo -n "Enter your domain name (or press Enter for localhost): "
    read DOMAIN_NAME
    if [ -z "$DOMAIN_NAME" ]; then
        DOMAIN_NAME="localhost"
    fi
    
    # Create production environment file
    cat > .env.production << EOF
# Database Configuration
POSTGRES_DB=permit_management_prod
POSTGRES_USER=permit_user
POSTGRES_PASSWORD=${DB_PASSWORD}

# Application Configuration
JWT_SECRET=${JWT_SECRET}
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production
LOG_LEVEL=INFO

# Upload Configuration
UPLOAD_MAX_SIZE=10485760
UPLOAD_DIR=/app/uploads

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://${DOMAIN_NAME},http://${DOMAIN_NAME}:8081,http://localhost:8081

# Redis Configuration
REDIS_URL=redis://redis:6379

# SSL Configuration
SSL_ENABLED=true
SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
SSL_KEY_PATH=/etc/nginx/ssl/key.pem

# Server Information
SERVER_IP=${SERVER_IP}
DOMAIN_NAME=${DOMAIN_NAME}
EOF
    
    print_status "Environment configuration created"
}

# Generate SSL certificates
generate_ssl_certificates() {
    print_header "SSL Certificate Generation"
    
    mkdir -p nginx/ssl
    
    echo -n "Do you have existing SSL certificates? (y/n): "
    read HAS_SSL
    
    if [[ $HAS_SSL =~ ^[Yy]$ ]]; then
        echo "Please place your SSL certificates in nginx/ssl/"
        echo "- Certificate: nginx/ssl/cert.pem"
        echo "- Private Key: nginx/ssl/key.pem"
        echo -n "Press Enter when certificates are in place..."
        read
    else
        print_status "Generating self-signed SSL certificates..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/key.pem \
            -out nginx/ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME}" \
            2>/dev/null
        
        print_warning "Self-signed certificates generated. For production, consider using Let's Encrypt:"
        print_warning "sudo certbot certonly --standalone -d ${DOMAIN_NAME}"
    fi
    
    # Set proper permissions
    chmod 600 nginx/ssl/key.pem
    chmod 644 nginx/ssl/cert.pem
    
    print_status "SSL certificates configured"
}

# Deploy application
deploy_application() {
    print_header "Application Deployment"
    
    print_status "Building and starting services..."
    
    # Stop any existing services
    docker-compose -f docker-compose.production.yml down 2>/dev/null || true
    
    # Build and start services
    docker-compose -f docker-compose.production.yml up -d --build
    
    print_status "Waiting for services to start..."
    sleep 30
    
    # Check service health
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -sf http://localhost:8081/counties > /dev/null 2>&1; then
            print_status "Application is healthy and responding"
            break
        fi
        
        print_status "Waiting for application to start... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "Application failed to start properly"
        print_error "Check logs with: docker-compose -f docker-compose.production.yml logs"
        exit 1
    fi
}

# Create management scripts
create_management_scripts() {
    print_header "Creating Management Scripts"
    
    # Create start script
    cat > start-server.sh << 'EOF'
#!/bin/bash
echo "Starting Permit Management System..."
docker-compose -f docker-compose.production.yml up -d
echo "System started. Access at: http://localhost:8081"
EOF
    
    # Create stop script
    cat > stop-server.sh << 'EOF'
#!/bin/bash
echo "Stopping Permit Management System..."
docker-compose -f docker-compose.production.yml down
echo "System stopped."
EOF
    
    # Create status script
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
    
    # Create backup script
    cat > backup-system.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

echo "Creating system backup..."
docker-compose -f docker-compose.production.yml exec -T postgres pg_dump -U permit_user permit_management_prod | gzip > "$BACKUP_DIR/database_$DATE.sql.gz"
tar -czf "$BACKUP_DIR/uploads_$DATE.tar.gz" uploads/ 2>/dev/null || true
echo "Backup created: $BACKUP_DIR/database_$DATE.sql.gz"
EOF
    
    # Make scripts executable
    chmod +x start-server.sh stop-server.sh status-server.sh backup-system.sh
    
    print_status "Management scripts created"
}

# Setup monitoring
setup_monitoring() {
    print_header "Setting Up Monitoring"
    
    # Create monitoring script
    cat > monitor-system.sh << 'EOF'
#!/bin/bash
echo "=== Permit Management System Monitor ==="
echo "Date: $(date)"
echo

# Container status
echo "Container Status:"
docker-compose -f docker-compose.production.yml ps

echo
echo "Resource Usage:"
docker stats --no-stream

echo
echo "Disk Usage:"
df -h .

echo
echo "Service Health:"
if curl -sf http://localhost:8081/counties > /dev/null; then
    echo "✅ API: Healthy"
else
    echo "❌ API: Failed"
fi

if docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U permit_user > /dev/null 2>&1; then
    echo "✅ Database: Healthy"
else
    echo "❌ Database: Failed"
fi

if docker-compose -f docker-compose.production.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis: Healthy"
else
    echo "❌ Redis: Failed"
fi
EOF
    
    chmod +x monitor-system.sh
    
    # Setup daily backup cron job
    (crontab -l 2>/dev/null; echo "0 2 * * * $(pwd)/backup-system.sh") | crontab -
    
    print_status "Monitoring and automated backups configured"
}

# Display final information
display_final_info() {
    print_header "Deployment Complete!"
    
    echo -e "${GREEN}🎉 Your Permit Management System is now running!${NC}"
    echo
    echo "Access URLs:"
    echo "  • Web Application: http://${DOMAIN_NAME}:8081"
    echo "  • Admin Panel: http://${DOMAIN_NAME}:8081/admin"
    echo "  • API Endpoint: http://${DOMAIN_NAME}:8081/counties"
    
    if [ "$DOMAIN_NAME" != "localhost" ]; then
        echo "  • External Access: http://${SERVER_IP}:8081"
    fi
    
    echo
    echo "Management Commands:"
    echo "  • Start system: ./start-server.sh"
    echo "  • Stop system: ./stop-server.sh"
    echo "  • Check status: ./status-server.sh"
    echo "  • Monitor system: ./monitor-system.sh"
    echo "  • Backup system: ./backup-system.sh"
    
    echo
    echo "Configuration Files:"
    echo "  • Environment: .env.production"
    echo "  • SSL Certificates: nginx/ssl/"
    echo "  • Logs: docker-compose -f docker-compose.production.yml logs"
    
    echo
    echo "Next Steps:"
    echo "  1. Test the web application at http://${DOMAIN_NAME}:8081"
    echo "  2. Create admin user via the admin panel"
    echo "  3. Configure your router for external access (port forwarding)"
    echo "  4. Set up Let's Encrypt for production SSL certificates"
    echo "  5. Configure dynamic DNS if using a home connection"
    
    if [ "$DOMAIN_NAME" = "localhost" ]; then
        echo
        print_warning "You're using localhost. For external access:"
        print_warning "1. Configure your domain name"
        print_warning "2. Set up port forwarding on your router (port 8081)"
        print_warning "3. Configure dynamic DNS if needed"
    fi
    
    echo
    print_status "Deployment completed successfully! 🚀"
}

# Main deployment process
main() {
    print_header "Starting Home Server Deployment"
    
    check_dependencies
    install_docker
    configure_firewall
    generate_passwords
    configure_environment
    generate_ssl_certificates
    deploy_application
    create_management_scripts
    setup_monitoring
    display_final_info
    
    echo
    print_status "Home server deployment completed successfully!"
    print_status "Your Permit Management System is ready for use."
}

# Run main function
main "$@"
