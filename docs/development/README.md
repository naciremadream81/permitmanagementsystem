# Development Guide

## Overview

This guide covers the development setup, coding standards, and best practices for the Permit Management System.

## Development Environment Setup

### Prerequisites

- **Java 21+**: Required for Kotlin compilation
- **Kotlin 2.2.0+**: Multiplatform development
- **PostgreSQL 13+**: Database server
- **IntelliJ IDEA**: Recommended IDE
- **Git**: Version control
- **Docker**: Optional, for containerized development

### IDE Setup

#### IntelliJ IDEA Configuration

1. **Install plugins**
   - Kotlin Multiplatform Mobile
   - Ktor
   - Database Navigator
   - Git Integration

2. **Configure project settings**
   ```
   File → Settings → Build → Compiler → Kotlin
   - Target JVM version: 21
   - Language version: 2.2
   ```

3. **Import project**
   ```
   File → Open → Select project root directory
   ```

#### VS Code Configuration

1. **Install extensions**
   - Kotlin Language
   - REST Client
   - PostgreSQL

2. **Configure settings**
   ```json
   {
     "kotlin.languageServer.enabled": true,
     "kotlin.debugAdapter.enabled": true
   }
   ```

### Project Structure

```
permitmanagementsystem/
├── server/                     # Backend server
│   ├── src/main/kotlin/        # Server source code
│   │   ├── Application.kt      # Main application entry point
│   │   ├── config/             # Configuration classes
│   │   ├── database/           # Database models and setup
│   │   ├── models/             # Data models
│   │   ├── routes/             # API route handlers
│   │   ├── services/           # Business logic
│   │   ├── error/              # Error handling
│   │   ├── health/             # Health checks
│   │   └── logging/            # Logging utilities
│   ├── src/test/kotlin/        # Server tests
│   └── build.gradle.kts        # Server build configuration
├── shared/                     # Shared business logic
│   ├── src/commonMain/kotlin/  # Common code
│   │   ├── models/             # Shared data models
│   │   ├── api/                # API client
│   │   └── database/           # Database interfaces
│   ├── src/jvmMain/kotlin/     # JVM-specific code
│   └── build.gradle.kts        # Shared module configuration
├── composeApp/                 # Mobile and desktop apps
│   ├── src/commonMain/kotlin/  # Shared UI code
│   ├── src/androidMain/kotlin/ # Android-specific code
│   ├── src/iosMain/kotlin/     # iOS-specific code
│   └── build.gradle.kts        # App build configuration
└── docs/                       # Documentation
```

## Coding Standards

### Kotlin Style Guide

Follow the official Kotlin coding conventions:

1. **Naming conventions**
   ```kotlin
   // Classes: PascalCase
   class PermitPackage
   
   // Functions and variables: camelCase
   fun createPermitPackage()
   val permitPackageId: Int
   
   // Constants: UPPER_SNAKE_CASE
   const val MAX_FILE_SIZE = 10_000_000
   
   // Packages: lowercase
   package com.regnowsnaes.permitmanagementsystem.models
   ```

2. **Code formatting**
   ```kotlin
   // Use 4 spaces for indentation
   class Example {
       fun method() {
           if (condition) {
               // Implementation
           }
       }
   }
   
   // Line length: 120 characters
   // Use trailing commas in collections
   val list = listOf(
       "item1",
       "item2",
       "item3",
   )
   ```

3. **Documentation**
   ```kotlin
   /**
    * Creates a new permit package for the specified county.
    *
    * @param countyId The ID of the county
    * @param name The name of the permit package
    * @param description Optional description
    * @return The created permit package
    * @throws ValidationException if the input is invalid
    */
   suspend fun createPermitPackage(
       countyId: Int,
       name: String,
       description: String? = null
   ): PermitPackage {
       // Implementation
   }
   ```

### API Design Standards

1. **RESTful endpoints**
   ```kotlin
   // Use HTTP methods appropriately
   GET    /api/packages          // List packages
   POST   /api/packages          // Create package
   GET    /api/packages/{id}     // Get package
   PUT    /api/packages/{id}     // Update package
   DELETE /api/packages/{id}     // Delete package
   ```

2. **Response format**
   ```kotlin
   @Serializable
   data class ApiResponse<T>(
       val success: Boolean,
       val data: T? = null,
       val message: String? = null,
       val error: String? = null
   )
   ```

3. **Error handling**
   ```kotlin
   // Use appropriate HTTP status codes
   HttpStatusCode.BadRequest      // 400 - Client error
   HttpStatusCode.Unauthorized    // 401 - Authentication required
   HttpStatusCode.Forbidden       // 403 - Access denied
   HttpStatusCode.NotFound        // 404 - Resource not found
   HttpStatusCode.InternalServerError // 500 - Server error
   ```

### Database Standards

1. **Table naming**
   ```sql
   -- Use snake_case for table names
   CREATE TABLE permit_packages (
       id SERIAL PRIMARY KEY,
       user_id INTEGER NOT NULL,
       county_id INTEGER NOT NULL,
       name VARCHAR(255) NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```

2. **Column naming**
   ```sql
   -- Use snake_case for column names
   -- Use descriptive names
   -- Include created_at and updated_at for audit trails
   ```

3. **Indexes**
   ```sql
   -- Create indexes for frequently queried columns
   CREATE INDEX idx_permit_packages_user_id ON permit_packages(user_id);
   CREATE INDEX idx_permit_packages_county_id ON permit_packages(county_id);
   ```

## Development Workflow

### Git Workflow

1. **Branch naming**
   ```
   feature/add-user-authentication
   bugfix/fix-login-validation
   hotfix/security-patch
   ```

2. **Commit messages**
   ```
   feat: add user authentication endpoint
   fix: resolve login validation issue
   docs: update API documentation
   test: add unit tests for permit service
   ```

3. **Pull request process**
   - Create feature branch from `main`
   - Implement changes with tests
   - Run full test suite
   - Submit pull request
   - Code review and merge

### Testing Strategy

1. **Unit tests**
   ```kotlin
   @Test
   fun `should create permit package successfully`() = runTest {
       // Given
       val countyId = 1
       val name = "Test Permit"
       
       // When
       val result = permitService.createPermitPackage(countyId, name)
       
       // Then
       assertThat(result.name).isEqualTo(name)
       assertThat(result.countyId).isEqualTo(countyId)
   }
   ```

2. **Integration tests**
   ```kotlin
   @Test
   fun `should handle API request correctly`() = testApplication {
       // Test API endpoints
       val response = client.get("/api/packages")
       assertEquals(HttpStatusCode.OK, response.status)
   }
   ```

3. **Test coverage**
   - Aim for 80%+ code coverage
   - Test all public methods
   - Test error conditions
   - Test edge cases

### Code Review Guidelines

1. **Checklist**
   - [ ] Code follows style guidelines
   - [ ] Tests are included and passing
   - [ ] Documentation is updated
   - [ ] No security vulnerabilities
   - [ ] Performance considerations addressed

2. **Review process**
   - At least one reviewer required
   - All CI checks must pass
   - Address all review comments
   - Squash commits before merge

## Database Development

### Schema Changes

1. **Migration files**
   ```sql
   -- V1__Create_initial_tables.sql
   CREATE TABLE users (
       id SERIAL PRIMARY KEY,
       email VARCHAR(255) UNIQUE NOT NULL,
       password VARCHAR(255) NOT NULL,
       first_name VARCHAR(100) NOT NULL,
       last_name VARCHAR(100) NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```

2. **Data seeding**
   ```sql
   -- Seed data for development
   INSERT INTO counties (name, state) VALUES
   ('Alachua County', 'FL'),
   ('Baker County', 'FL'),
   ('Bay County', 'FL');
   ```

### Database Testing

1. **Test database setup**
   ```kotlin
   @BeforeEach
   fun setup() {
       // Create test database
       Database.connect("jdbc:h2:mem:test", driver = "org.h2.Driver")
       
       // Run migrations
       SchemaUtils.create(Users, Counties, PermitPackages)
   }
   ```

2. **Test data cleanup**
   ```kotlin
   @AfterEach
   fun cleanup() {
       // Clean up test data
       SchemaUtils.drop(Users, Counties, PermitPackages)
   }
   ```

## API Development

### Adding New Endpoints

1. **Create route handler**
   ```kotlin
   // routes/NewFeatureRoutes.kt
   fun Route.configureNewFeatureRoutes() {
       route("/new-feature") {
           get {
               // Implementation
           }
           
           post {
               // Implementation
           }
       }
   }
   ```

2. **Register routes**
   ```kotlin
   // Application.kt
   routing {
       configureNewFeatureRoutes()
   }
   ```

3. **Add tests**
   ```kotlin
   @Test
   fun `should handle new feature endpoint`() = testApplication {
       val response = client.get("/new-feature")
       assertEquals(HttpStatusCode.OK, response.status)
   }
   ```

### Error Handling

1. **Custom exceptions**
   ```kotlin
   class ValidationException(message: String, val field: String? = null) : Exception(message)
   class BusinessLogicException(message: String) : Exception(message)
   ```

2. **Error responses**
   ```kotlin
   exception<ValidationException> { call, cause ->
       call.respond(
           HttpStatusCode.BadRequest,
           ErrorResponse(
               error = "Validation failed",
               message = cause.message,
               field = cause.field
           )
       )
   }
   ```

## Frontend Development

### Compose Multiplatform

1. **Shared UI components**
   ```kotlin
   @Composable
   fun PermitPackageCard(
       package: PermitPackage,
       onEdit: () -> Unit,
       onDelete: () -> Unit
   ) {
       Card(
           modifier = Modifier.fillMaxWidth(),
           elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
       ) {
           Column(
               modifier = Modifier.padding(16.dp)
           ) {
               Text(
                   text = package.name,
                   style = MaterialTheme.typography.h6
               )
               Text(
                   text = package.description ?: "",
                   style = MaterialTheme.typography.body2
               )
           }
       }
   }
   ```

2. **Platform-specific implementations**
   ```kotlin
   // commonMain
   expect class Platform() {
       val name: String
   }
   
   // androidMain
   actual class Platform actual constructor() {
       actual val name: String = UIDevice.currentDevice.systemName() + " " + UIDevice.currentDevice.systemVersion
   }
   
   // iosMain
   actual class Platform actual constructor() {
       actual val name: String = UIDevice.currentDevice.systemName() + " " + UIDevice.currentDevice.systemVersion
   }
   ```

### Web Development

1. **HTML structure**
   ```html
   <!DOCTYPE html>
   <html lang="en">
   <head>
       <meta charset="UTF-8">
       <meta name="viewport" content="width=device-width, initial-scale=1.0">
       <title>Permit Management System</title>
   </head>
   <body>
       <div id="app"></div>
       <script src="app.js"></script>
   </body>
   </html>
   ```

2. **JavaScript modules**
   ```javascript
   // api.js
   export class PermitAPI {
       constructor(baseURL) {
           this.baseURL = baseURL;
       }
       
       async getPackages() {
           const response = await fetch(`${this.baseURL}/api/packages`);
           return response.json();
       }
   }
   ```

## Performance Optimization

### Backend Optimization

1. **Database queries**
   ```kotlin
   // Use proper indexing
   // Avoid N+1 queries
   // Use pagination for large datasets
   val packages = transaction {
       PermitPackages
           .select { PermitPackages.userId eq userId }
           .limit(20)
           .offset(page * 20)
           .map { it.toPermitPackage() }
   }
   ```

2. **Caching**
   ```kotlin
   // Cache frequently accessed data
   @Singleton
   class CountyService {
       private val countiesCache = mutableMapOf<Int, County>()
       
       suspend fun getCounty(id: Int): County? {
           return countiesCache[id] ?: loadCounty(id)?.also { 
               countiesCache[id] = it 
           }
       }
   }
   ```

### Frontend Optimization

1. **Lazy loading**
   ```kotlin
   @Composable
   fun PackageList(packages: List<PermitPackage>) {
       LazyColumn {
           items(packages) { package ->
               PermitPackageCard(package = package)
           }
       }
   }
   ```

2. **Image optimization**
   ```kotlin
   @Composable
   fun OptimizedImage(
       url: String,
       contentDescription: String
   ) {
       AsyncImage(
           model = ImageRequest.Builder(LocalContext.current)
               .data(url)
               .crossfade(true)
               .build(),
           contentDescription = contentDescription,
           modifier = Modifier.size(100.dp)
       )
   }
   ```

## Debugging

### Backend Debugging

1. **Logging**
   ```kotlin
   import org.slf4j.LoggerFactory
   
   class PermitService {
       private val logger = LoggerFactory.getLogger(PermitService::class.java)
       
       suspend fun createPackage(package: PermitPackage) {
           logger.info("Creating permit package: ${package.name}")
           try {
               // Implementation
               logger.info("Permit package created successfully")
           } catch (e: Exception) {
               logger.error("Failed to create permit package", e)
               throw e
           }
       }
   }
   ```

2. **Debug endpoints**
   ```kotlin
   // Development only
   if (environment == "development") {
       get("/debug/info") {
           call.respond(mapOf(
               "version" to "1.0.0",
               "environment" to environment,
               "database" to "connected"
           ))
       }
   }
   ```

### Frontend Debugging

1. **Console logging**
   ```javascript
   // Web debugging
   console.log('API Response:', response);
   console.error('API Error:', error);
   ```

2. **Network inspection**
   ```kotlin
   // Ktor client logging
   val client = HttpClient {
       install(Logging) {
           level = LogLevel.INFO
       }
   }
   ```

## Security Considerations

### Input Validation

1. **Server-side validation**
   ```kotlin
   data class CreatePackageRequest(
       val countyId: Int,
       val name: String,
       val description: String?
   ) {
       init {
           require(countyId > 0) { "County ID must be positive" }
           require(name.isNotBlank()) { "Name cannot be blank" }
           require(name.length <= 255) { "Name too long" }
       }
   }
   ```

2. **SQL injection prevention**
   ```kotlin
   // Use parameterized queries
   val packages = transaction {
       PermitPackages
           .select { PermitPackages.name like "%$searchTerm%" }
           .map { it.toPermitPackage() }
   }
   ```

### Authentication

1. **JWT token validation**
   ```kotlin
   fun validateToken(token: String): User? {
       return try {
           val decoded = JWT.decode(token)
           val userId = decoded.getClaim("userId").asInt()
           userService.getUserById(userId)
       } catch (e: Exception) {
           null
       }
   }
   ```

2. **Password hashing**
   ```kotlin
   fun hashPassword(password: String): String {
       return BCrypt.hashpw(password, BCrypt.gensalt(12))
   }
   
   fun verifyPassword(password: String, hash: String): Boolean {
       return BCrypt.checkpw(password, hash)
   }
   ```

## Documentation

### Code Documentation

1. **KDoc comments**
   ```kotlin
   /**
    * Service for managing permit packages.
    * 
    * This service handles all operations related to permit packages,
    * including creation, updates, and retrieval.
    */
   class PermitService {
       /**
        * Creates a new permit package.
        * 
        * @param request The package creation request
        * @return The created permit package
        * @throws ValidationException if the request is invalid
        */
       suspend fun createPackage(request: CreatePackageRequest): PermitPackage
   }
   ```

2. **API documentation**
   ```kotlin
   /**
    * Creates a new permit package.
    * 
    * @param request The package creation request
    * @return The created permit package
    * @response 201 Created - Package created successfully
    * @response 400 Bad Request - Invalid request data
    * @response 401 Unauthorized - Authentication required
    */
   post("/packages") {
       // Implementation
   }
   ```

### README Updates

Keep documentation updated:
- Update README.md for new features
- Document API changes
- Update setup instructions
- Add troubleshooting guides

## Continuous Integration

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 21
      uses: actions/setup-java@v3
      with:
        java-version: '21'
        distribution: 'temurin'
    
    - name: Cache Gradle packages
      uses: actions/cache@v3
      with:
        path: |
          ~/.gradle/caches
          ~/.gradle/wrappers
        key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
    
    - name: Run tests
      run: ./gradlew test
    
    - name: Build application
      run: ./gradlew build
```

### Quality Gates

1. **Code coverage**
   ```kotlin
   // build.gradle.kts
   jacoco {
       toolVersion = "0.8.8"
   }
   
   tasks.jacocoTestReport {
       reports {
           xml.required.set(true)
           html.required.set(true)
       }
   }
   ```

2. **Static analysis**
   ```kotlin
   // Add detekt for code analysis
   plugins {
       id("io.gitlab.arturbosch.detekt")
   }
   ```

This development guide provides a comprehensive foundation for contributing to the Permit Management System. Follow these standards and practices to ensure code quality, maintainability, and team collaboration.
