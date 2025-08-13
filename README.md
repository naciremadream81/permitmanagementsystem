# Permit Management System

A cross-platform permit package management system with cloud-backed storage and offline capabilities.

## Features

- **Native Apps**: iOS, Android, Windows, and Linux applications
- **Cloud Backend**: AWS-hosted or self-hosted PostgreSQL backend
- **County-Specific Checklists**: Dynamic checklists tied to permit packages
- **Offline-First**: Local storage with sync capabilities
- **File Management**: Secure document upload and storage
- **User Authentication**: JWT-based authentication system

## Architecture

### Backend Stack
- **Kotlin** with **Ktor** framework
- **PostgreSQL** database with **Exposed** ORM
- **JWT** authentication with **bcrypt** password hashing
- **Docker** containerization

### Database Schema
- `users` - User accounts and authentication
- `counties` - County information and jurisdictions
- `checklist_items` - County-specific permit requirements
- `permit_packages` - Permit package metadata
- `permit_documents` - Uploaded documents and files

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Java 17 or higher
- Gradle 8.5 or higher

### Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd permitmanagementsystem
   ```

2. **Start the development environment**
   ```bash
   docker-compose up -d
   ```

3. **Verify the API is running**
   ```bash
   curl http://localhost:8080/
   # Should return: "Permit Management System API is running"
   ```

### Manual Setup (without Docker)

1. **Install PostgreSQL**
   ```bash
   # macOS
   brew install postgresql
   brew services start postgresql
   
   # Ubuntu
   sudo apt-get install postgresql postgresql-contrib
   sudo systemctl start postgresql
   ```

2. **Create database**
   ```bash
   createdb permit_management
   ```

3. **Set environment variables**
   ```bash
   export DATABASE_URL=jdbc:postgresql://localhost:5432/permit_management
   export DB_USER=postgres
   export DB_PASSWORD=password
   export JWT_SECRET=your-secret-key-change-in-production
   ```

4. **Run the server**
   ```bash
   ./gradlew :server:run
   ```

## API Documentation

### Authentication

#### Register User
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

### Counties & Checklists

#### Get All Counties
```http
GET /counties
```

#### Get County Checklist
```http
GET /counties/{id}/checklist
```

### Permit Packages

#### Get User's Packages
```http
GET /packages
Authorization: Bearer <jwt-token>
```

#### Create Package
```http
POST /packages
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "countyId": 1,
  "name": "Residential Addition",
  "description": "Adding a second story to existing home"
}
```

#### Get Package Details
```http
GET /packages/{id}
Authorization: Bearer <jwt-token>
```

#### Update Package Status
```http
PUT /packages/{id}/status
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "status": "in_progress"
}
```

### Document Management

#### Get Package Documents
```http
GET /packages/{id}/documents
Authorization: Bearer <jwt-token>
```

#### Upload Document
```http
POST /packages/{id}/documents
Authorization: Bearer <jwt-token>
Content-Type: multipart/form-data

checklistItemId: 1
file: [binary file data]
```

#### Delete Document
```http
DELETE /packages/{id}/documents/{documentId}
Authorization: Bearer <jwt-token>
```

## Database Seeding

The system automatically seeds initial data including:
- Orange County, CA with 4 checklist items
- Los Angeles County, CA with 3 checklist items

## Development

### Project Structure
```
permitmanagementsystem/
├── server/                 # Backend API
│   ├── src/main/kotlin/
│   │   └── com/regnowsnaes/permitmanagementsystem/
│   │       ├── models/     # Data models
│   │       ├── database/   # Database tables and config
│   │       ├── services/   # Business logic
│   │       └── routes/     # API endpoints
├── shared/                 # Shared code for all platforms
├── composeApp/             # Multiplatform UI
├── docker-compose.yml      # Development environment
└── Dockerfile             # Production container
```

### Adding New Counties

To add a new county with its checklist:

1. **Add county to database**
   ```sql
   INSERT INTO counties (name, state, created_at, updated_at) 
   VALUES ('New County', 'CA', NOW(), NOW());
   ```

2. **Add checklist items**
   ```sql
   INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at)
   VALUES 
   (3, 'Site Plan', 'Upload site plan drawing', true, 1, NOW(), NOW()),
   (3, 'Building Plans', 'Upload architectural drawings', true, 2, NOW(), NOW());
   ```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `jdbc:postgresql://localhost:5432/permit_management` |
| `DB_USER` | Database username | `postgres` |
| `DB_PASSWORD` | Database password | `password` |
| `JWT_SECRET` | JWT signing secret | `your-secret-key-change-in-production` |

## Production Deployment

### AWS Deployment
1. Use AWS RDS for PostgreSQL
2. Deploy server to AWS ECS or EC2
3. Use AWS S3 for file storage
4. Configure AWS Cognito for authentication

### Self-Hosted Deployment
1. Use Docker Compose for production
2. Configure NGINX reverse proxy
3. Set up SSL certificates
4. Use MinIO for S3-compatible storage

## Testing

### API Testing
```bash
# Test registration
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","firstName":"Test","lastName":"User"}'

# Test login
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Test counties endpoint
curl http://localhost:8080/counties
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.