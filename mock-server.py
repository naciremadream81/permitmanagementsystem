#!/usr/bin/env python3
"""
Mock API Server for Permit Management System
Provides mock data for web applications when the main server is not available
"""

import json
import http.server
import socketserver
from urllib.parse import urlparse, parse_qs
import os
from datetime import datetime

class MockAPIHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="extra/web-apps", **kwargs)
    
    def do_GET(self):
        if self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            super().do_GET()
    
    def do_POST(self):
        if self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            super().do_POST()
    
    def handle_api_request(self):
        """Handle API requests with mock data"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # Set CORS headers
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
        
        # Mock data responses
        if path == '/api/health':
            response = {
                "status": "healthy",
                "timestamp": datetime.now().isoformat(),
                "version": "1.0.0",
                "environment": "development"
            }
        elif path == '/api/counties':
            response = {
                "success": True,
                "data": [
                    {
                        "id": 1,
                        "name": "Miami-Dade County",
                        "code": "MDC",
                        "state": "FL",
                        "population": 2700000,
                        "permitRequirements": [
                            "Building Permit",
                            "Electrical Permit",
                            "Plumbing Permit"
                        ]
                    },
                    {
                        "id": 2,
                        "name": "Broward County",
                        "code": "BWC",
                        "state": "FL",
                        "population": 1950000,
                        "permitRequirements": [
                            "Building Permit",
                            "Electrical Permit",
                            "Plumbing Permit",
                            "Mechanical Permit"
                        ]
                    },
                    {
                        "id": 3,
                        "name": "Palm Beach County",
                        "code": "PBC",
                        "state": "FL",
                        "population": 1500000,
                        "permitRequirements": [
                            "Building Permit",
                            "Electrical Permit",
                            "Plumbing Permit"
                        ]
                    }
                ],
                "message": "Counties retrieved successfully"
            }
        elif path == '/api/permits':
            response = {
                "success": True,
                "data": [
                    {
                        "id": 1,
                        "title": "Residential Construction Permit",
                        "county": "Miami-Dade County",
                        "status": "pending",
                        "submittedDate": "2025-01-01",
                        "estimatedCompletion": "2025-02-01"
                    },
                    {
                        "id": 2,
                        "title": "Commercial Renovation Permit",
                        "county": "Broward County",
                        "status": "approved",
                        "submittedDate": "2024-12-15",
                        "estimatedCompletion": "2025-01-15"
                    }
                ],
                "message": "Permits retrieved successfully"
            }
        elif path == '/api/auth/me':
            response = {
                "success": True,
                "data": {
                    "id": 1,
                    "email": "demo@example.com",
                    "firstName": "Demo",
                    "lastName": "User",
                    "role": "user",
                    "createdAt": "2025-01-01T00:00:00Z"
                },
                "message": "User profile retrieved successfully"
            }
        else:
            response = {
                "success": False,
                "error": "Endpoint not found",
                "message": f"API endpoint {path} not implemented in mock server",
                "availableEndpoints": [
                    "/api/health",
                    "/api/counties",
                    "/api/permits",
                    "/api/auth/me"
                ]
            }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

def main():
    PORT = 3001
    
    print(f"🌐 Starting Mock API Server...")
    print(f"📁 Serving web apps from: extra/web-apps/")
    print(f"🔗 Web apps available at: http://localhost:{PORT}")
    print(f"🔗 Mock API available at: http://localhost:{PORT}/api/")
    print(f"📋 Available endpoints:")
    print(f"   - GET  /api/health")
    print(f"   - GET  /api/counties")
    print(f"   - GET  /api/permits")
    print(f"   - GET  /api/auth/me")
    print(f"")
    print(f"🎯 Quick Access:")
    print(f"   - Main App: http://localhost:{PORT}/web-app.html")
    print(f"   - Production: http://localhost:{PORT}/web-app-production.html")
    print(f"   - Admin: http://localhost:{PORT}/web-app-admin.html")
    print(f"")
    print(f"Press Ctrl+C to stop the server")
    print(f"=" * 50)
    
    with socketserver.TCPServer(("", PORT), MockAPIHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print(f"\n🛑 Server stopped")

if __name__ == "__main__":
    main()
