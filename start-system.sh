#!/bin/bash

echo "🚀 Starting Permit Management System"
echo "====================================="

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -i :$port >/dev/null 2>&1; then
        echo "⚠️  Port $port is already in use"
        return 1
    else
        echo "✅ Port $port is available"
        return 0
    fi
}

# Function to kill processes on a port
kill_port() {
    local port=$1
    echo "🔄 Killing processes on port $port..."
    lsof -ti :$port | xargs kill -9 2>/dev/null || true
    sleep 2
}

# Kill any existing processes on our ports
kill_port 3000
kill_port 8080

echo ""
echo "🌐 Starting Backend Server (Port 8080)..."
node mock-backend.js &
BACKEND_PID=$!

echo "⏳ Waiting for backend to start..."
sleep 3

# Test backend
if curl -s http://localhost:8080/health >/dev/null; then
    echo "✅ Backend server started successfully"
else
    echo "❌ Backend server failed to start"
    exit 1
fi

echo ""
echo "🎨 Starting Frontend Server (Port 3000)..."
npm run dev &
FRONTEND_PID=$!

echo "⏳ Waiting for frontend to start..."
sleep 8

# Test frontend
if curl -s http://localhost:3000 >/dev/null; then
    echo "✅ Frontend server started successfully"
else
    echo "❌ Frontend server failed to start"
    exit 1
fi

echo ""
echo "🎉 System is ready!"
echo "==================="
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend:  http://localhost:8080"
echo ""
echo "🔑 Login Credentials:"
echo "   Email:    admin@permitpro.com"
echo "   Password: admin123"
echo ""
echo "📋 Available Features:"
echo "   ✅ Login/Logout"
echo "   ✅ Dashboard with statistics"
echo "   ✅ Create/Edit permits"
echo "   ✅ Upload documents"
echo "   ✅ Search and filter"
echo "   ✅ County data and checklists"
echo ""
echo "Press Ctrl+C to stop both servers"

# Wait for user to stop
wait
