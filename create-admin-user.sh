#!/bin/bash

# Script to create the first admin user for the Florida Permit Management System

echo "🔐 Creating Default Admin User for Florida Permit Management System"
echo "=================================================================="

# Database connection details
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="permit_management_prod"
DB_USER="permit_user"
DB_PASSWORD="secure_permit_password_2024"

# Admin user details
ADMIN_EMAIL="admin@florida-permits.gov"
ADMIN_PASSWORD="AdminPass2024!"
ADMIN_FIRST_NAME="System"
ADMIN_LAST_NAME="Administrator"
ADMIN_ROLE="SUPER_ADMIN"

echo "Creating admin user with email: $ADMIN_EMAIL"

# Generate password hash using Python (since bcrypt is available)
HASHED_PASSWORD=$(python3 -c "
import bcrypt
password = '$ADMIN_PASSWORD'.encode('utf-8')
hashed = bcrypt.hashpw(password, bcrypt.gensalt())
print(hashed.decode('utf-8'))
")

if [ $? -ne 0 ]; then
    echo "❌ Error: Python bcrypt not available. Installing..."
    pip3 install bcrypt
    
    HASHED_PASSWORD=$(python3 -c "
import bcrypt
password = '$ADMIN_PASSWORD'.encode('utf-8')
hashed = bcrypt.hashpw(password, bcrypt.gensalt())
print(hashed.decode('utf-8'))
")
fi

# Current timestamp
CURRENT_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

# SQL to insert admin user
SQL_COMMAND="
INSERT INTO admin_users (email, password_hash, first_name, last_name, role, is_active, county_restrictions, last_login, created_at, updated_at)
VALUES (
    '$ADMIN_EMAIL',
    '$HASHED_PASSWORD',
    '$ADMIN_FIRST_NAME',
    '$ADMIN_LAST_NAME',
    '$ADMIN_ROLE',
    true,
    NULL,
    NULL,
    '$CURRENT_TIME',
    '$CURRENT_TIME'
)
ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    updated_at = EXCLUDED.updated_at;
"

# Execute SQL command
echo "Connecting to database and creating user..."

if command -v psql &> /dev/null; then
    # Use psql if available
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$SQL_COMMAND"
    
    if [ $? -eq 0 ]; then
        echo "✅ Admin user created successfully!"
        echo ""
        echo "🔑 Login Credentials:"
        echo "   Email: $ADMIN_EMAIL"
        echo "   Password: $ADMIN_PASSWORD"
        echo "   Role: $ADMIN_ROLE"
        echo ""
        echo "🌐 Access the admin interface at:"
        echo "   http://localhost:3000/web-app-admin-enhanced.html"
        echo ""
        echo "⚠️  IMPORTANT: Change the default password after first login!"
    else
        echo "❌ Failed to create admin user"
        exit 1
    fi
else
    echo "❌ Error: psql command not found. Please install PostgreSQL client tools."
    echo ""
    echo "Alternative: Connect to your database manually and run this SQL:"
    echo "$SQL_COMMAND"
    exit 1
fi

echo ""
echo "🎉 Setup complete! Your Florida Permit Management System is ready with:"
echo "   ✅ 67 Florida counties with comprehensive checklists"
echo "   ✅ Full CRUD API for checklist management"
echo "   ✅ Bulk operations for multi-county management"
echo "   ✅ Template system for standardized checklists"
echo "   ✅ Role-based admin authentication"
echo "   ✅ Document management system"
echo "   ✅ Audit logging for all admin actions"
echo ""
echo "🚀 Ready to manage building permits across the entire state of Florida!"
