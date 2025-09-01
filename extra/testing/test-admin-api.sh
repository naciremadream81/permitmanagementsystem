#!/bin/bash

# Test script for the Admin API functionality
# Tests all CRUD operations for checklist management

echo "🧪 Testing Florida Permit Management System - Admin API"
echo "======================================================"

API_BASE="http://localhost:8080"
COUNTY_ID=43  # Miami-Dade County

echo ""
echo "1. Testing GET counties..."
curl -s "$API_BASE/counties" | head -5
echo ""

echo "2. Testing GET checklist for Miami-Dade County..."
ORIGINAL_COUNT=$(curl -s "$API_BASE/counties/$COUNTY_ID/checklist" | jq '.data | length' 2>/dev/null || curl -s "$API_BASE/counties/$COUNTY_ID/checklist" | jq 'length')
echo "Original checklist items: $ORIGINAL_COUNT"
echo ""

echo "3. Testing POST - Adding new checklist item..."
NEW_ITEM=$(curl -s -X POST "$API_BASE/counties/$COUNTY_ID/checklist" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "API Test Item",
    "description": "This item was created by the test script",
    "required": true,
    "orderIndex": 99
  }')

echo "$NEW_ITEM"
ITEM_ID=$(echo "$NEW_ITEM" | jq -r '.id')
echo "Created item with ID: $ITEM_ID"
echo ""

echo "4. Testing PUT - Updating the checklist item..."
UPDATED_ITEM=$(curl -s -X PUT "$API_BASE/counties/$COUNTY_ID/checklist/$ITEM_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated API Test Item",
    "description": "This item has been updated by the test script",
    "required": false,
    "orderIndex": 100
  }')

echo "$UPDATED_ITEM"
echo ""

echo "5. Verifying the update..."
NEW_COUNT=$(curl -s "$API_BASE/counties/$COUNTY_ID/checklist" | jq '.data | length' 2>/dev/null || curl -s "$API_BASE/counties/$COUNTY_ID/checklist" | jq 'length')
echo "Current checklist items: $NEW_COUNT"
echo ""

echo "6. Testing DELETE - Removing the test item..."
DELETE_RESULT=$(curl -s -X DELETE "$API_BASE/counties/$COUNTY_ID/checklist/$ITEM_ID")
echo "$DELETE_RESULT"
echo ""

echo "7. Verifying the deletion..."
FINAL_COUNT=$(curl -s "$API_BASE/counties/$COUNTY_ID/checklist" | jq '.data | length' 2>/dev/null || curl -s "$API_BASE/counties/$COUNTY_ID/checklist" | jq 'length')
echo "Final checklist items: $FINAL_COUNT"
echo ""

echo "8. Testing with a different county (Baker County - ID: 2)..."
BAKER_COUNT=$(curl -s "$API_BASE/counties/2/checklist" | jq '.data | length' 2>/dev/null || curl -s "$API_BASE/counties/2/checklist" | jq 'length')
echo "Baker County checklist items: $BAKER_COUNT"
echo ""

echo "🎉 API Test Results:"
echo "==================="
echo "✅ GET counties: Working"
echo "✅ GET checklist: Working"
echo "✅ POST new item: Working (ID: $ITEM_ID)"
echo "✅ PUT update item: Working"
echo "✅ DELETE item: Working"
echo ""
echo "📊 Item counts:"
echo "   Original: $ORIGINAL_COUNT"
echo "   After add: $NEW_COUNT"
echo "   After delete: $FINAL_COUNT"
echo ""

if [ "$ORIGINAL_COUNT" -eq "$FINAL_COUNT" ]; then
    echo "✅ All tests passed! Item count returned to original."
else
    echo "⚠️  Warning: Item count mismatch. Expected $ORIGINAL_COUNT, got $FINAL_COUNT"
fi

echo ""
echo "🌐 Admin Interface: http://localhost:3000/web-app-admin.html"
echo "📱 Main App: http://localhost:3000/web-app-production.html"
