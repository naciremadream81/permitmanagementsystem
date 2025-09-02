#!/usr/bin/env python3
"""
Mock Backend Server for Permit Management System
This provides a working API for the frontend to test with
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import json
import time
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Mock data
MOCK_USERS = {
    "admin@permitpro.com": {
        "id": 1,
        "email": "admin@permitpro.com",
        "firstName": "Admin",
        "lastName": "User",
        "password": "admin123"
    },
    "test@example.com": {
        "id": 2,
        "email": "test@example.com", 
        "firstName": "Test",
        "lastName": "User",
        "password": "password123"
    }
}

MOCK_PACKAGES = [
    {
        "id": 1,
        "customerName": "John Smith",
        "propertyAddress": "123 Main St, Miami, FL 33101",
        "county": "Miami-Dade",
        "status": "Submitted",
        "createdAt": "2025-01-15T10:30:00Z",
        "userId": 1
    },
    {
        "id": 2,
        "customerName": "Jane Doe",
        "propertyAddress": "456 Oak Ave, Tampa, FL 33602",
        "county": "Hillsborough",
        "status": "Draft",
        "createdAt": "2025-01-14T14:20:00Z",
        "userId": 1
    },
    {
        "id": 3,
        "customerName": "Bob Johnson",
        "propertyAddress": "789 Pine St, Orlando, FL 32801",
        "county": "Orange",
        "status": "Completed",
        "createdAt": "2025-01-13T09:15:00Z",
        "userId": 1
    }
]

MOCK_COUNTIES = [
    {"id": 1, "name": "Miami-Dade", "state": "FL"},
    {"id": 2, "name": "Hillsborough", "state": "FL"},
    {"id": 3, "name": "Orange", "state": "FL"},
    {"id": 4, "name": "Broward", "state": "FL"},
    {"id": 5, "name": "Pinellas", "state": "FL"}
]

def generate_token(user_id):
    """Generate a simple mock JWT token"""
    return f"mock_jwt_token_{user_id}_{int(time.time())}"

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "Permit Management Mock API"
    })

@app.route('/auth/login', methods=['POST'])
def login():
    """Login endpoint"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Login attempt for: {email}")
        
        if email in MOCK_USERS and MOCK_USERS[email]['password'] == password:
            user = MOCK_USERS[email].copy()
            del user['password']  # Don't send password back
            
            token = generate_token(user['id'])
            
            return jsonify({
                "success": True,
                "data": {
                    "token": token,
                    "user": user
                },
                "message": "Login successful"
            }), 200
        else:
            return jsonify({
                "success": False,
                "error": "Invalid credentials",
                "message": "Invalid email or password"
            }), 401
            
    except Exception as e:
        return jsonify({
            "success": False,
            "error": "Internal server error",
            "message": str(e)
        }), 500

@app.route('/packages', methods=['GET'])
def get_packages():
    """Get permit packages"""
    try:
        # In a real app, you'd validate the JWT token here
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({
                "success": False,
                "error": "Missing or invalid authorization header"
            }), 401
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Fetching packages")
        
        return jsonify({
            "success": True,
            "data": MOCK_PACKAGES,
            "message": "Packages retrieved successfully"
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": "Internal server error",
            "message": str(e)
        }), 500

@app.route('/packages', methods=['POST'])
def create_package():
    """Create a new permit package"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['customerName', 'propertyAddress', 'county']
        for field in required_fields:
            if not data.get(field):
                return jsonify({
                    "success": False,
                    "error": f"Missing required field: {field}"
                }), 400
        
        # Create new package
        new_package = {
            "id": len(MOCK_PACKAGES) + 1,
            "customerName": data['customerName'],
            "propertyAddress": data['propertyAddress'],
            "county": data['county'],
            "status": "Draft",
            "createdAt": datetime.now().isoformat(),
            "userId": 1
        }
        
        MOCK_PACKAGES.append(new_package)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Created package: {new_package['customerName']}")
        
        return jsonify({
            "success": True,
            "data": new_package,
            "message": "Package created successfully"
        }), 201
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": "Internal server error",
            "message": str(e)
        }), 500

@app.route('/counties', methods=['GET'])
def get_counties():
    """Get all counties"""
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Fetching counties")
        
        return jsonify({
            "success": True,
            "data": MOCK_COUNTIES,
            "message": "Counties retrieved successfully"
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": "Internal server error",
            "message": str(e)
        }), 500

@app.route('/checklists/<int:county_id>', methods=['GET'])
def get_checklist(county_id):
    """Get checklist for a county"""
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Fetching checklist for county {county_id}")
        
        # Mock checklist items
        checklist_items = [
            {"id": 1, "name": "Building Permit Application", "required": True},
            {"id": 2, "name": "Site Plan", "required": True},
            {"id": 3, "name": "Structural Plans", "required": True},
            {"id": 4, "name": "Electrical Plans", "required": False},
            {"id": 5, "name": "Plumbing Plans", "required": False}
        ]
        
        return jsonify({
            "success": True,
            "data": checklist_items,
            "message": f"Checklist retrieved for county {county_id}"
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": "Internal server error",
            "message": str(e)
        }), 500

if __name__ == '__main__':
    print("🌐 Starting Permit Management Mock API Server...")
    print("📋 Available endpoints:")
    print("   - POST /auth/login")
    print("   - GET  /packages")
    print("   - POST /packages")
    print("   - GET  /counties")
    print("   - GET  /checklists/{county_id}")
    print("   - GET  /health")
    print("🔗 Server will run on: http://localhost:8080")
    print("🎯 Test login with: admin@permitpro.com / admin123")
    print("==================================================")
    
    app.run(host='0.0.0.0', port=8080, debug=True)
