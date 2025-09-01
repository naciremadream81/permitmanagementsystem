# 🔧 Production Values Guide

## 🚀 **Quick Setup (Recommended)**

### **Option 1: Interactive Setup Script**
```bash
# Run the interactive setup script
./setup-production-env.sh

# This will:
# 1. Generate secure JWT secret automatically
# 2. Ask you to choose database option
# 3. Create .env file with secure permissions
# 4. Guide you through all required values
```

### **Option 2: Manual Quick Setup**
```bash
# Copy template and edit
cp .env.production .env

# Edit the file with your values
nano .env  # or vim .env or code .env
```

## 📋 **Production Values by Scenario**

### **Scenario 1: Docker Development/Testing**
```bash
# Perfect for local testing and development
DATABASE_URL=jdbc:postgresql://db:5432/permit_management_prod
DB_USER=permit_user
DB_PASSWORD=secure_test_password_123
JWT_SECRET=test-jwt-secret-key-for-development-only-32chars
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production
```

### **Scenario 2: Cloud Database (AWS RDS)**
```bash
# For AWS RDS PostgreSQL
DATABASE_URL=jdbc:postgresql://your-rds-endpoint.amazonaws.com:5432/permit_management
DB_USER=your_rds_username
DB_PASSWORD=your_rds_password
JWT_SECRET=your-secure-jwt-secret-generated-with-openssl
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production
```

### **Scenario 3: Self-Hosted Server**
```bash
# For your own PostgreSQL server
DATABASE_URL=jdbc:postgresql://192.168.1.100:5432/permit_management_prod
DB_USER=permit_admin
DB_PASSWORD=your_secure_database_password
JWT_SECRET=your-very-secure-jwt-secret-key-at-least-32-characters
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production
```

## 🔐 **How to Generate Secure Values**

### **JWT Secret (CRITICAL)**
```bash
# Method 1: Using OpenSSL (recommended)
openssl rand -base64 32

# Method 2: Using /dev/urandom
head -c 32 /dev/urandom | base64

# Method 3: Online generator (use with caution)
# Visit: https://generate-secret.vercel.app/32

# Example output:
JWT_SECRET=K7gNU3sdo+OL0wNhqoVWhr3g6s1xYv72ol/pe/Unols=
```

### **Database Password**
```bash
# Generate secure database password
openssl rand -base64 16

# Example output:
DB_PASSWORD=xvz8K9mN2pQ7wR5t
```

## 🌐 **Database Setup Options**

### **Option 1: Docker PostgreSQL (Easiest)**
```bash
# No setup needed - Docker Compose handles it
# Just set these values:
DATABASE_URL=jdbc:postgresql://db:5432/permit_management_prod
DB_USER=permit_user
DB_PASSWORD=your_chosen_password
```

### **Option 2: Install PostgreSQL Locally**
```bash
# macOS
brew install postgresql
brew services start postgresql

# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql

# Create database and user
sudo -u postgres psql
CREATE DATABASE permit_management_prod;
CREATE USER permit_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE permit_management_prod TO permit_user;
\q

# Then use:
DATABASE_URL=jdbc:postgresql://localhost:5432/permit_management_prod
DB_USER=permit_user
DB_PASSWORD=your_password
```

### **Option 3: Cloud Database**

#### **AWS RDS**
1. Create RDS PostgreSQL instance in AWS Console
2. Note the endpoint, username, and password
3. Configure security groups to allow connections
4. Use values like:
```bash
DATABASE_URL=jdbc:postgresql://mydb.123456789012.us-east-1.rds.amazonaws.com:5432/permit_management
DB_USER=postgres
DB_PASSWORD=your_rds_password
```

#### **Google Cloud SQL**
1. Create Cloud SQL PostgreSQL instance
2. Create database and user
3. Configure authorized networks
4. Use connection string from Cloud Console

#### **DigitalOcean Managed Database**
1. Create managed PostgreSQL database
2. Get connection details from control panel
3. Use provided connection string

## 🔧 **Complete .env Example**

```bash
# Permit Management System - Production Environment

# Database Configuration
DATABASE_URL=jdbc:postgresql://db:5432/permit_management_prod
DB_USER=permit_user
DB_PASSWORD=K7gNU3sdo+OL0wNhqoVWhr3g6s1xYv72ol

# JWT Configuration (32+ characters, base64 encoded)
JWT_SECRET=xvz8K9mN2pQ7wR5tK7gNU3sdo+OL0wNhqoVWhr3g6s1xYv72ol/pe/Unols=

# Server Configuration
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production

# File Upload Configuration
UPLOAD_MAX_SIZE=10485760
UPLOAD_DIR=./uploads

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=./logs/server.log

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# Optional: SSL Configuration
SSL_ENABLED=false
SSL_KEYSTORE_PATH=
SSL_KEYSTORE_PASSWORD=

# Optional: Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@yourdomain.com
```

## ⚡ **Quick Start Commands**

### **1. Generate Production Environment**
```bash
# Interactive setup (recommended)
./setup-production-env.sh

# Manual setup
cp .env.production .env
# Edit .env with your values
```

### **2. Deploy with Docker**
```bash
# Deploy with Docker Compose
docker-compose -f docker-compose.simple.yml up -d

# Check status
docker-compose -f docker-compose.simple.yml ps
curl http://localhost:8080/
```

### **3. Deploy Directly**
```bash
# Deploy server directly
./deploy-server.sh production

# Check status
curl http://localhost:8080/
```

## 🔒 **Security Best Practices**

### **Environment File Security**
```bash
# Set secure permissions (owner read/write only)
chmod 600 .env

# Never commit .env to version control
echo ".env" >> .gitignore

# Use different secrets for different environments
# development, staging, production should all have different JWT secrets
```

### **Database Security**
```bash
# Use strong passwords (16+ characters)
# Include uppercase, lowercase, numbers, symbols
# Example: K7gNU3s$do+OL0wNh@qoVWhr3g6s1xYv72ol

# Restrict database access
# Only allow connections from application server IP
# Use SSL/TLS for database connections in production
```

### **JWT Secret Security**
```bash
# Must be at least 32 characters
# Should be base64 encoded random data
# Never reuse across environments
# Rotate periodically in production
```

## 🎯 **Ready-to-Use Examples**

### **For Local Testing**
```bash
# Create .env with these values for local testing
cat > .env << 'EOF'
DATABASE_URL=jdbc:postgresql://db:5432/permit_management_prod
DB_USER=permit_user
DB_PASSWORD=local_test_password_123
JWT_SECRET=local-test-jwt-secret-key-for-development-only-32-characters
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production
EOF

chmod 600 .env
```

### **For Production Server**
```bash
# Use the interactive script for production
./setup-production-env.sh

# Or generate manually with secure values
JWT_SECRET=$(openssl rand -base64 32)
DB_PASSWORD=$(openssl rand -base64 16)

cat > .env << EOF
DATABASE_URL=jdbc:postgresql://your-db-host:5432/permit_management_prod
DB_USER=permit_user
DB_PASSWORD=$DB_PASSWORD
JWT_SECRET=$JWT_SECRET
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
ENVIRONMENT=production
EOF

chmod 600 .env
```

## 🚀 **You're Ready!**

Once you have your `.env` file configured, you can:

1. **Deploy with Docker**: `docker-compose -f docker-compose.simple.yml up -d`
2. **Deploy directly**: `./deploy-server.sh production`
3. **Test the API**: `curl http://localhost:8080/`

Your production environment is ready to go! 🎉
