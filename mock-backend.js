#!/usr/bin/env node
/**
 * Mock Backend Server for Permit Management System
 * This provides a working API for the frontend to test with
 */

const http = require('http');
const url = require('url');

// Mock data
const MOCK_USERS = {
    "admin@permitpro.com": {
        id: 1,
        email: "admin@permitpro.com",
        firstName: "Admin",
        lastName: "User",
        password: "admin123"
    },
    "test@example.com": {
        id: 2,
        email: "test@example.com", 
        firstName: "Test",
        lastName: "User",
        password: "password123"
    }
};

const MOCK_PACKAGES = [
    {
        id: 1,
        customerName: "John Smith",
        propertyAddress: "123 Main St, Miami, FL 33101",
        county: "Miami-Dade",
        countyId: 1,
        permitType: "Building",
        status: "Submitted",
        createdAt: "2025-01-15T10:30:00Z",
        userId: 1,
        documents: []
    },
    {
        id: 2,
        customerName: "Jane Doe",
        propertyAddress: "456 Oak Ave, Tampa, FL 33602",
        county: "Hillsborough",
        countyId: 2,
        permitType: "Electrical",
        status: "Draft",
        createdAt: "2025-01-14T14:20:00Z",
        userId: 1,
        documents: []
    },
    {
        id: 3,
        customerName: "Bob Johnson",
        propertyAddress: "789 Pine St, Orlando, FL 32801",
        county: "Orange",
        countyId: 3,
        permitType: "Plumbing",
        status: "Completed",
        createdAt: "2025-01-13T09:15:00Z",
        userId: 1,
        documents: []
    }
];

const MOCK_COUNTIES = [
    {id: 1, name: "Miami-Dade", state: "FL"},
    {id: 2, name: "Hillsborough", state: "FL"},
    {id: 3, name: "Orange", state: "FL"},
    {id: 4, name: "Broward", state: "FL"},
    {id: 5, name: "Pinellas", state: "FL"}
];

function getChecklistForPermitType(permitType) {
    const permitTypeConfigs = {
        'Building': [
            { id: 1, name: 'Building Permit Application', required: true, description: 'Complete building permit application form' },
            { id: 2, name: 'Site Plan', required: true, description: 'Detailed site plan showing property boundaries and proposed construction' },
            { id: 3, name: 'Structural Plans', required: true, description: 'Architectural and structural engineering plans' },
            { id: 4, name: 'Electrical Plans', required: true, description: 'Electrical system design and layout plans' },
            { id: 5, name: 'Plumbing Plans', required: true, description: 'Plumbing system design and layout plans' },
            { id: 6, name: 'HVAC Plans', required: false, description: 'Heating, ventilation, and air conditioning plans' },
            { id: 7, name: 'Fire Safety Plans', required: true, description: 'Fire safety and emergency exit plans' },
            { id: 8, name: 'Environmental Impact Assessment', required: false, description: 'Environmental impact study if required' }
        ],
        'Electrical': [
            { id: 1, name: 'Electrical Permit Application', required: true, description: 'Complete electrical permit application form' },
            { id: 2, name: 'Electrical Load Calculation', required: true, description: 'Electrical load calculations and panel schedules' },
            { id: 3, name: 'Electrical Plans', required: true, description: 'Detailed electrical system plans and schematics' },
            { id: 4, name: 'Equipment Specifications', required: true, description: 'Specifications for electrical equipment and fixtures' },
            { id: 5, name: 'Grounding Plan', required: true, description: 'Electrical grounding and bonding plan' }
        ],
        'Plumbing': [
            { id: 1, name: 'Plumbing Permit Application', required: true, description: 'Complete plumbing permit application form' },
            { id: 2, name: 'Plumbing Plans', required: true, description: 'Detailed plumbing system plans and layouts' },
            { id: 3, name: 'Fixture Schedule', required: true, description: 'Schedule of all plumbing fixtures and equipment' },
            { id: 4, name: 'Water Supply Plan', required: true, description: 'Water supply and distribution plan' },
            { id: 5, name: 'Drainage Plan', required: true, description: 'Waste and drainage system plan' }
        ],
        'Demolition': [
            { id: 1, name: 'Demolition Permit Application', required: true, description: 'Complete demolition permit application form' },
            { id: 2, name: 'Asbestos Survey', required: true, description: 'Asbestos inspection and abatement plan' },
            { id: 3, name: 'Demolition Plan', required: true, description: 'Detailed demolition sequence and safety plan' },
            { id: 4, name: 'Environmental Assessment', required: true, description: 'Environmental impact assessment for demolition' },
            { id: 5, name: 'Utility Disconnection Plan', required: true, description: 'Plan for disconnecting utilities' }
        ]
    };

    return permitTypeConfigs[permitType] || permitTypeConfigs['Building'];
}

function generateToken(userId) {
    return `mock_jwt_token_${userId}_${Date.now()}`;
}

function parseBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => {
            body += chunk.toString();
        });
        req.on('end', () => {
            try {
                resolve(JSON.parse(body));
            } catch (e) {
                resolve({});
            }
        });
    });
}

function sendResponse(res, statusCode, data) {
    res.writeHead(statusCode, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    });
    res.end(JSON.stringify(data));
}

function handleRequest(req, res) {
    const parsedUrl = url.parse(req.url, true);
    const path = parsedUrl.pathname;
    const method = req.method;

    console.log(`[${new Date().toISOString()}] ${method} ${path}`);

    // Handle CORS preflight
    if (method === 'OPTIONS') {
        sendResponse(res, 200, {});
        return;
    }

    // Health check
    if (path === '/health' && method === 'GET') {
        sendResponse(res, 200, {
            status: "healthy",
            timestamp: new Date().toISOString(),
            service: "Permit Management Mock API"
        });
        return;
    }

    // Login endpoint
    if (path === '/auth/login' && method === 'POST') {
        parseBody(req).then(data => {
            const email = data.email;
            const password = data.password;

            if (MOCK_USERS[email] && MOCK_USERS[email].password === password) {
                const user = {...MOCK_USERS[email]};
                delete user.password;

                const token = generateToken(user.id);

                sendResponse(res, 200, {
                    success: true,
                    data: {
                        token: token,
                        user: user
                    },
                    message: "Login successful"
                });
            } else {
                sendResponse(res, 401, {
                    success: false,
                    error: "Invalid credentials",
                    message: "Invalid email or password"
                });
            }
        });
        return;
    }

    // Get packages
    if (path === '/packages' && method === 'GET') {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            sendResponse(res, 401, {
                success: false,
                error: "Missing or invalid authorization header"
            });
            return;
        }

        sendResponse(res, 200, {
            success: true,
            data: MOCK_PACKAGES,
            message: "Packages retrieved successfully"
        });
        return;
    }

    // Create package
    if (path === '/packages' && method === 'POST') {
        parseBody(req).then(data => {
            const requiredFields = ['customerName', 'propertyAddress', 'county'];
            for (const field of requiredFields) {
                if (!data[field]) {
                    sendResponse(res, 400, {
                        success: false,
                        error: `Missing required field: ${field}`
                    });
                    return;
                }
            }

            const newPackage = {
                id: MOCK_PACKAGES.length + 1,
                customerName: data.customerName,
                propertyAddress: data.propertyAddress,
                county: data.county,
                status: "Draft",
                createdAt: new Date().toISOString(),
                userId: 1
            };

            MOCK_PACKAGES.push(newPackage);

            sendResponse(res, 201, {
                success: true,
                data: newPackage,
                message: "Package created successfully"
            });
        });
        return;
    }

    // Get counties
    if (path === '/counties' && method === 'GET') {
        sendResponse(res, 200, {
            success: true,
            data: MOCK_COUNTIES,
            message: "Counties retrieved successfully"
        });
        return;
    }

    // Get checklist
    if (path.startsWith('/checklists/') && method === 'GET') {
        const countyId = path.split('/')[2];
        const query = parsedUrl.query;
        const permitType = query.permitType || 'Building';
        
        const checklistItems = getChecklistForPermitType(permitType);

        sendResponse(res, 200, {
            success: true,
            data: checklistItems,
            message: `Checklist retrieved for county ${countyId} - ${permitType} permit`
        });
        return;
    }

    // Upload document
    if (path.startsWith('/packages/') && path.endsWith('/documents') && method === 'POST') {
        parseBody(req).then(data => {
            console.log(`[${new Date().toISOString()}] Document upload attempted for package ${path.split('/')[2]}`);
            
            // Mock successful document upload
            const mockDocument = {
                id: Date.now(),
                filename: data.filename || 'document.pdf',
                size: data.size || 1024,
                uploadedAt: new Date().toISOString(),
                packageId: parseInt(path.split('/')[2])
            };

            sendResponse(res, 201, {
                success: true,
                data: mockDocument,
                message: "Document uploaded successfully"
            });
        });
        return;
    }

    // Upload checklist document
    if (path.startsWith('/packages/') && path.endsWith('/checklist-documents') && method === 'POST') {
        parseBody(req).then(data => {
            const packageId = parseInt(path.split('/')[2]);
            console.log(`[${new Date().toISOString()}] Checklist document upload for package ${packageId}, item: ${data.checklistItemName}`);
            
            const mockDocument = {
                id: Date.now(),
                name: data.name || data.filename || 'document.pdf',
                filename: data.filename || 'document.pdf',
                size: data.size || 1024,
                uploadedAt: data.uploadedAt || new Date().toISOString(),
                packageId: packageId,
                checklistItemId: data.checklistItemId,
                checklistItemName: data.checklistItemName
            };

            sendResponse(res, 201, {
                success: true,
                data: mockDocument,
                message: `Document uploaded successfully for ${data.checklistItemName}`
            });
        });
        return;
    }

    // Update package status
    if (path.startsWith('/packages/') && path.endsWith('/status') && method === 'PATCH') {
        parseBody(req).then(data => {
            const packageId = parseInt(path.split('/')[2]);
            const newStatus = data.status;
            
            console.log(`[${new Date().toISOString()}] Updating package ${packageId} status to ${newStatus}`);
            
            // Find and update the package
            const packageIndex = MOCK_PACKAGES.findIndex(pkg => pkg.id === packageId);
            if (packageIndex !== -1) {
                MOCK_PACKAGES[packageIndex].status = newStatus;
                
                sendResponse(res, 200, {
                    success: true,
                    data: MOCK_PACKAGES[packageIndex],
                    message: "Package status updated successfully"
                });
            } else {
                sendResponse(res, 404, {
                    success: false,
                    error: "Package not found"
                });
            }
        });
        return;
    }

    // 404 for unknown routes
    sendResponse(res, 404, {
        error: "Endpoint not found",
        message: "The requested endpoint does not exist",
        code: "NOT_FOUND",
        timestamp: new Date().toISOString(),
        path: path,
        method: method
    });
}

const server = http.createServer(handleRequest);

server.listen(8080, '0.0.0.0', () => {
    console.log('🌐 Starting Permit Management Mock API Server...');
    console.log('📋 Available endpoints:');
    console.log('   - POST /auth/login');
    console.log('   - GET  /packages');
    console.log('   - POST /packages');
    console.log('   - GET  /counties');
    console.log('   - GET  /checklists/{county_id}');
    console.log('   - GET  /health');
    console.log('🔗 Server running on: http://localhost:8080');
    console.log('🎯 Test login with: admin@permitpro.com / admin123');
    console.log('==================================================');
});
