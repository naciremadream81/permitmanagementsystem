# API Documentation

## Overview

The Permit Management System provides a RESTful API built with Ktor and Kotlin. The API follows REST principles and provides comprehensive endpoints for managing permits, counties, users, and documents.

## Base URL

```
http://localhost:8080/api/v1
```

## Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

### Getting a Token

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

## Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation completed successfully",
  "error": null
}
```

### Error Response
```json
{
  "success": false,
  "data": null,
  "message": "Error description",
  "error": "Detailed error message",
  "code": "ERROR_CODE",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

## Endpoints

### Health & Status

#### GET /health
Get overall system health status.

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "HEALTHY",
    "timestamp": "2025-01-01T00:00:00Z",
    "uptime": 3600000,
    "version": "1.0.0",
    "environment": "production",
    "components": [
      {
        "name": "database",
        "status": "HEALTHY",
        "message": "Database connection is healthy",
        "responseTime": 15
      }
    ]
  }
}
```

#### GET /health/ready
Kubernetes readiness probe.

#### GET /health/live
Kubernetes liveness probe.

### Authentication

#### POST /auth/register
Register a new user.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "jwt-token-here",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user",
      "createdAt": "2025-01-01T00:00:00Z"
    }
  }
}
```

#### POST /auth/login
Authenticate user and get JWT token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Counties

#### GET /counties
Get list of all counties.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Alachua County",
      "state": "FL",
      "createdAt": "2025-01-01T00:00:00Z",
      "updatedAt": "2025-01-01T00:00:00Z"
    }
  ]
}
```

#### GET /counties/{id}/checklist
Get checklist requirements for a specific county.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "countyId": 1,
      "title": "Building Permit Application",
      "description": "Complete building permit application form",
      "required": true,
      "orderIndex": 1,
      "createdAt": "2025-01-01T00:00:00Z",
      "updatedAt": "2025-01-01T00:00:00Z"
    }
  ]
}
```

### Permit Packages

#### GET /packages
Get user's permit packages (requires authentication).

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "userId": 1,
      "countyId": 1,
      "name": "Residential Construction Permit",
      "description": "New home construction",
      "status": "draft",
      "customerName": "John Doe",
      "customerEmail": "john@example.com",
      "createdAt": "2025-01-01T00:00:00Z",
      "updatedAt": "2025-01-01T00:00:00Z"
    }
  ]
}
```

#### POST /packages
Create a new permit package (requires authentication).

**Request:**
```json
{
  "countyId": 1,
  "name": "Residential Construction Permit",
  "description": "New home construction",
  "customerName": "John Doe",
  "customerEmail": "john@example.com",
  "customerPhone": "555-1234",
  "siteAddress": "123 Main St",
  "siteCity": "Gainesville",
  "siteState": "FL",
  "siteZip": "32601"
}
```

#### GET /packages/{id}
Get specific permit package details.

#### PUT /packages/{id}
Update permit package.

#### DELETE /packages/{id}
Delete permit package.

### Documents

#### POST /documents/upload
Upload document for a permit package.

**Request:** Multipart form data
- `file`: The document file
- `packageId`: Permit package ID
- `checklistItemId`: Checklist item ID

#### GET /documents/{id}
Download document.

#### DELETE /documents/{id}
Delete document.

## Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Input validation failed |
| `AUTHENTICATION_ERROR` | Authentication failed |
| `AUTHORIZATION_ERROR` | Access denied |
| `RESOURCE_NOT_FOUND` | Requested resource not found |
| `BUSINESS_LOGIC_ERROR` | Business rule violation |
| `EXTERNAL_SERVICE_ERROR` | External service failure |
| `INTERNAL_SERVER_ERROR` | Internal server error |

## Rate Limiting

The API implements rate limiting to prevent abuse:

- **Authenticated users**: 1000 requests per hour
- **Unauthenticated users**: 100 requests per hour
- **Burst limit**: 10 requests per second

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Pagination

List endpoints support pagination:

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)
- `sort`: Sort field
- `order`: Sort order (asc/desc)

**Response:**
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "pages": 5
  }
}
```

## Filtering

Many endpoints support filtering:

**Query Parameters:**
- `filter[field]`: Filter by specific field
- `search`: Text search across multiple fields

**Example:**
```
GET /packages?filter[status]=draft&filter[countyId]=1&search=construction
```

## SDKs and Libraries

### JavaScript/TypeScript
```javascript
import { PermitManagementAPI } from '@permit-management/api-client';

const api = new PermitManagementAPI({
  baseURL: 'http://localhost:8080/api/v1',
  token: 'your-jwt-token'
});

const counties = await api.counties.getAll();
```

### Kotlin
```kotlin
import com.regnowsnaes.permitmanagementsystem.api.ApiService

val apiService = ApiService("http://localhost:8080/api/v1")
val counties = apiService.getCounties()
```

## Webhooks

The API supports webhooks for real-time notifications:

### Available Events
- `package.created`
- `package.updated`
- `package.deleted`
- `document.uploaded`
- `document.deleted`

### Webhook Payload
```json
{
  "event": "package.created",
  "data": {
    "id": 1,
    "name": "Residential Construction Permit",
    "status": "draft"
  },
  "timestamp": "2025-01-01T00:00:00Z"
}
```

## Testing

### Postman Collection
Import the Postman collection from `docs/api/postman-collection.json` for easy API testing.

### cURL Examples
```bash
# Get counties
curl -X GET http://localhost:8080/counties

# Create permit package
curl -X POST http://localhost:8080/packages \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"countyId": 1, "name": "Test Permit"}'
```

## Changelog

### Version 1.0.0
- Initial API release
- Authentication and authorization
- County and permit management
- Document upload and management
- Health check endpoints
