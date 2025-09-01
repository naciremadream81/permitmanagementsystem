#!/bin/bash

# Simple Database Setup Script for Permit Management System
# Works with existing PostgreSQL installation

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

echo -e "${BLUE}🗄️  Permit Management System - Simple Database Setup${NC}"
echo -e "${BLUE}===================================================${NC}"
echo ""

# Function to check if PostgreSQL is running
check_postgresql() {
    if pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL is running on $DB_HOST:$DB_PORT${NC}"
        return 0
    else
        echo -e "${RED}❌ PostgreSQL is not running on $DB_HOST:$DB_PORT${NC}"
        echo -e "${YELLOW}Please start PostgreSQL first:${NC}"
        echo -e "  ${GREEN}Ubuntu/Debian:${NC} sudo systemctl start postgresql"
        echo -e "  ${GREEN}Arch Linux:${NC} sudo systemctl start postgresql"
        return 1
    fi
}

# Function to create database and user (without sudo)
setup_database() {
    echo -e "${YELLOW}🔧 Setting up database and user...${NC}"
    
    # Try to connect as current user first
    if psql -h "$DB_HOST" -p "$DB_PORT" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Connected to PostgreSQL as current user${NC}"
        
        # Create user if not exists
        psql -h "$DB_HOST" -p "$DB_PORT" -d postgres << EOF
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
        return 0
        
    else
        echo -e "${YELLOW}⚠️  Cannot connect as current user, trying with postgres user...${NC}"
        
        # Try with postgres user (might need password)
        if PGPASSWORD="" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Connected to PostgreSQL as postgres user${NC}"
            
            PGPASSWORD="" psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -d postgres << EOF
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
            return 0
        else
            echo -e "${RED}❌ Cannot connect to PostgreSQL${NC}"
            echo -e "${YELLOW}Please check your PostgreSQL configuration:${NC}"
            echo -e "  1. Make sure PostgreSQL is running"
            echo -e "  2. Check if you have access to the postgres database"
            echo -e "  3. You may need to run: ${GREEN}sudo -u postgres psql${NC}"
            return 1
        fi
    fi
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
    echo -e "3. ${YELLOW}Launch web apps:${NC}"
    echo -e "   ${GREEN}./launch-web-app.sh${NC}"
    echo ""
    echo -e "4. ${YELLOW}Access the web app:${NC}"
    echo -e "   ${GREEN}Open http://localhost:8080 in your browser${NC}"
    echo ""
    echo -e "5. ${YELLOW}View web apps:${NC}"
    echo -e "   ${GREEN}Check extra/web-apps/ directory for HTML files${NC}"
    echo ""
}

# Main execution
main() {
    # Check if PostgreSQL is running
    if ! check_postgresql; then
        exit 1
    fi
    
    echo ""
    
    # Setup database
    if setup_database; then
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
            echo -e "${YELLOW}Please check the database configuration and try again.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Database setup failed${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
