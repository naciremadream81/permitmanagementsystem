#!/bin/bash

# Universal Database Setup Script for Permit Management System
# Supports Ubuntu, Arch Linux, and other Linux distributions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="permit_management_dev"
DB_USER="permit_user"
DB_PASSWORD="permit_password_2025"
DB_HOST="localhost"
DB_PORT="5432"

echo -e "${BLUE}🗄️  Permit Management System - Database Setup${NC}"
echo -e "${BLUE}==============================================${NC}"
echo ""

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install PostgreSQL
install_postgresql() {
    local distro=$1
    
    echo -e "${YELLOW}📦 Installing PostgreSQL...${NC}"
    
    case $distro in
        "ubuntu"|"debian")
            sudo apt update
            sudo apt install -y postgresql postgresql-contrib
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm postgresql
            ;;
        "fedora"|"rhel"|"centos")
            sudo dnf install -y postgresql-server postgresql-contrib
            sudo postgresql-setup --initdb
            ;;
        *)
            echo -e "${RED}❌ Unsupported distribution: $distro${NC}"
            echo "Please install PostgreSQL manually and run this script again."
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✅ PostgreSQL installed successfully${NC}"
}

# Function to start PostgreSQL service
start_postgresql() {
    local distro=$1
    
    echo -e "${YELLOW}🚀 Starting PostgreSQL service...${NC}"
    
    case $distro in
        "ubuntu"|"debian"|"fedora"|"rhel"|"centos")
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        "arch"|"manjaro")
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
    esac
    
    echo -e "${GREEN}✅ PostgreSQL service started${NC}"
}

# Function to create database and user
setup_database() {
    echo -e "${YELLOW}🔧 Setting up database and user...${NC}"
    
    # Switch to postgres user and create database/user
    sudo -u postgres psql << EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
        CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
    END IF;
END
\$\$;

-- Create database if not exists
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;

\q
EOF
    
    echo -e "${GREEN}✅ Database and user created successfully${NC}"
}

# Function to test database connection
test_connection() {
    echo -e "${YELLOW}🔍 Testing database connection...${NC}"
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Database connection successful${NC}"
        return 0
    else
        echo -e "${RED}❌ Database connection failed${NC}"
        return 1
    fi
}

# Function to create environment file
create_env_file() {
    echo -e "${YELLOW}📝 Creating environment configuration...${NC}"
    
    cat > .env << EOF
# Database Configuration
DATABASE_URL=jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# Server Configuration
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
ENVIRONMENT=development

# Security
JWT_SECRET=your-super-secure-jwt-secret-key-for-development-only-$(date +%s)
BCRYPT_ROUNDS=12

# CORS
CORS_ORIGINS=http://localhost:8080,http://127.0.0.1:8080

# Logging
LOG_LEVEL=INFO
EOF
    
    echo -e "${GREEN}✅ Environment file created: .env${NC}"
}

# Function to show connection info
show_connection_info() {
    echo ""
    echo -e "${BLUE}📋 Database Connection Information${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo -e "Host: ${GREEN}$DB_HOST${NC}"
    echo -e "Port: ${GREEN}$DB_PORT${NC}"
    echo -e "Database: ${GREEN}$DB_NAME${NC}"
    echo -e "Username: ${GREEN}$DB_USER${NC}"
    echo -e "Password: ${GREEN}$DB_PASSWORD${NC}"
    echo ""
    echo -e "${BLUE}🔗 Connection String${NC}"
    echo -e "jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME"
    echo ""
    echo -e "${BLUE}📝 psql Command${NC}"
    echo -e "PGPASSWORD='$DB_PASSWORD' psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
    echo ""
}

# Function to show next steps
show_next_steps() {
    echo -e "${BLUE}🚀 Next Steps${NC}"
    echo -e "${BLUE}=============${NC}"
    echo ""
    echo -e "1. ${YELLOW}Start the server:${NC}"
    echo -e "   ${GREEN}./gradlew :server:run${NC}"
    echo ""
    echo -e "2. ${YELLOW}Test the API:${NC}"
    echo -e "   ${GREEN}curl http://localhost:8080/health${NC}"
    echo ""
    echo -e "3. ${YELLOW}Access the web app:${NC}"
    echo -e "   ${GREEN}Open http://localhost:8080 in your browser${NC}"
    echo ""
    echo -e "4. ${YELLOW}View web apps:${NC}"
    echo -e "   ${GREEN}Check extra/web-apps/ directory for HTML files${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${YELLOW}🔍 Detecting Linux distribution...${NC}"
    DISTRO=$(detect_distro)
    echo -e "Detected: ${GREEN}$DISTRO${NC}"
    echo ""
    
    # Check if PostgreSQL is installed
    if ! command_exists psql; then
        echo -e "${YELLOW}PostgreSQL not found. Installing...${NC}"
        install_postgresql "$DISTRO"
        start_postgresql "$DISTRO"
    else
        echo -e "${GREEN}✅ PostgreSQL is already installed${NC}"
        
        # Check if service is running
        if ! systemctl is-active --quiet postgresql; then
            echo -e "${YELLOW}PostgreSQL service not running. Starting...${NC}"
            start_postgresql "$DISTRO"
        else
            echo -e "${GREEN}✅ PostgreSQL service is running${NC}"
        fi
    fi
    
    echo ""
    
    # Setup database
    setup_database
    
    echo ""
    
    # Test connection
    if test_connection; then
        echo ""
        create_env_file
        echo ""
        show_connection_info
        show_next_steps
        
        echo -e "${GREEN}🎉 Database setup completed successfully!${NC}"
        echo -e "${GREEN}Your Permit Management System is ready to run.${NC}"
    else
        echo -e "${RED}❌ Database setup failed${NC}"
        echo -e "${YELLOW}Please check the PostgreSQL installation and try again.${NC}"
        exit 1
    fi
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please do not run this script as root${NC}"
    echo -e "${YELLOW}The script will use sudo when needed.${NC}"
    exit 1
fi

# Check if sudo is available
if ! command_exists sudo; then
    echo -e "${RED}❌ sudo is required but not installed${NC}"
    echo -e "${YELLOW}Please install sudo and try again.${NC}"
    exit 1
fi

# Run main function
main "$@"
