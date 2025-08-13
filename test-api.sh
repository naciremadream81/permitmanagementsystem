#!/bin/bash

# Test script for Permit Management System API
# Make sure the server is running on localhost:8080

BASE_URL="http://localhost:8080"

echo "🧪 Testing Permit Management System API"
echo "======================================"

# Test health check
echo "1. Testing health check..."
curl -s "$BASE_URL/" || echo "❌ Health check failed"

# Test counties endpoint
echo -e "\n2. Testing counties endpoint..."
curl -s "$BASE_URL/counties" | jq '.' || echo "❌ Counties endpoint failed"

# Test registration
echo -e "\n3. Testing user registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
  }')

echo "$REGISTER_RESPONSE" | jq '.'

# Extract token from registration response
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.data.token')

if [ "$TOKEN" = "null" ] || [ "$TOKEN" = "" ]; then
    echo "❌ Failed to get token from registration"
    exit 1
fi

echo -e "\n4. Testing login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }')

echo "$LOGIN_RESPONSE" | jq '.'

# Test authenticated endpoints
echo -e "\n5. Testing authenticated endpoints..."

# Get user's packages
echo "   - Getting user packages..."
curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/packages" | jq '.'

# Create a new package
echo -e "\n   - Creating a new package..."
CREATE_PACKAGE_RESPONSE=$(curl -s -X POST "$BASE_URL/packages" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "countyId": 1,
    "name": "Test Residential Project",
    "description": "A test permit package"
  }')

echo "$CREATE_PACKAGE_RESPONSE" | jq '.'

# Extract package ID
PACKAGE_ID=$(echo "$CREATE_PACKAGE_RESPONSE" | jq -r '.data.id')

if [ "$PACKAGE_ID" != "null" ] && [ "$PACKAGE_ID" != "" ]; then
    echo -e "\n   - Getting package details..."
    curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/packages/$PACKAGE_ID" | jq '.'
    
    echo -e "\n   - Getting package documents..."
    curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/packages/$PACKAGE_ID/documents" | jq '.'
    
    echo -e "\n   - Updating package status..."
    curl -s -X PUT "$BASE_URL/packages/$PACKAGE_ID/status" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"status": "in_progress"}' | jq '.'
fi

echo -e "\n✅ API tests completed!" 