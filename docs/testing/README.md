# Testing Guide

## Overview

This guide covers the testing strategy, tools, and best practices for the Permit Management System. The system includes comprehensive testing at multiple levels to ensure reliability and quality.

## Testing Strategy

### Testing Pyramid

```
                    ┌─────────────────┐
                    │   E2E Tests     │  ← Few, High-level
                    │   (End-to-End)  │
                    └─────────┬───────┘
                              │
                    ┌─────────┴───────┐
                    │ Integration     │  ← Some, Medium-level
                    │ Tests           │
                    └─────────┬───────┘
                              │
                    ┌─────────┴───────┐
                    │   Unit Tests    │  ← Many, Low-level
                    │                 │
                    └─────────────────┘
```

### Test Categories

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test component interactions
3. **API Tests**: Test API endpoints and contracts
4. **End-to-End Tests**: Test complete user workflows
5. **Performance Tests**: Test system performance under load

## Test Structure

### Project Test Organization

```
server/src/test/kotlin/
├── SerializationTest.kt          # Data serialization tests
├── ApiEndpointTest.kt            # API endpoint tests
├── IntegrationTest.kt            # Integration tests
├── PerformanceTest.kt            # Performance tests
└── fixtures/                     # Test data fixtures
    ├── TestData.kt
    └── MockData.kt

shared/src/commonTest/kotlin/
├── ModelsTest.kt                 # Shared model tests
└── ApiClientTest.kt              # API client tests

composeApp/src/commonTest/kotlin/
├── ViewModelsTest.kt             # ViewModel tests
└── RepositoryTest.kt             # Repository tests
```

## Unit Testing

### Backend Unit Tests

#### Serialization Tests
```kotlin
class SerializationTest {
    
    private val json = Json {
        prettyPrint = true
        isLenient = true
        ignoreUnknownKeys = true
    }
    
    @Test
    fun `ApiResponse serialization should work correctly`() {
        // Test successful response
        val successResponse = ApiResponse(
            success = true,
            data = "test data",
            message = "Operation successful"
        )
        
        val serialized = json.encodeToString(successResponse)
        assertTrue(serialized.contains("success"))
        assertTrue(serialized.contains("test data"))
        assertTrue(serialized.contains("Operation successful"))
    }
    
    @Test
    fun `County serialization should work correctly`() {
        val county = County(
            id = 1,
            name = "Alachua County",
            state = "FL",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z"
        )
        
        val serialized = json.encodeToString(county)
        assertTrue(serialized.contains("Alachua County"))
        assertTrue(serialized.contains("FL"))
    }
}
```

#### Service Tests
```kotlin
class PermitServiceTest {
    
    private lateinit var permitService: PermitService
    private lateinit var mockDatabase: Database
    
    @BeforeEach
    fun setup() {
        mockDatabase = Database.connect("jdbc:h2:mem:test", driver = "org.h2.Driver")
        SchemaUtils.create(PermitPackages, Counties, Users)
        permitService = PermitService()
    }
    
    @AfterEach
    fun cleanup() {
        SchemaUtils.drop(PermitPackages, Counties, Users)
    }
    
    @Test
    fun `should create permit package successfully`() = runTest {
        // Given
        val countyId = 1
        val name = "Test Permit"
        val description = "Test Description"
        
        // When
        val result = permitService.createPermitPackage(countyId, name, description)
        
        // Then
        assertThat(result.name).isEqualTo(name)
        assertThat(result.countyId).isEqualTo(countyId)
        assertThat(result.description).isEqualTo(description)
    }
    
    @Test
    fun `should throw exception for invalid county ID`() = runTest {
        // Given
        val invalidCountyId = 999
        val name = "Test Permit"
        
        // When & Then
        assertThrows<ValidationException> {
            permitService.createPermitPackage(invalidCountyId, name)
        }
    }
}
```

### Frontend Unit Tests

#### ViewModel Tests
```kotlin
class PermitPackageViewModelTest {
    
    private lateinit var viewModel: PermitPackageViewModel
    private lateinit var mockRepository: PermitRepository
    
    @BeforeEach
    fun setup() {
        mockRepository = mockk<PermitRepository>()
        viewModel = PermitPackageViewModel(mockRepository)
    }
    
    @Test
    fun `should load permit packages on init`() = runTest {
        // Given
        val packages = listOf(
            PermitPackage(id = 1, name = "Package 1"),
            PermitPackage(id = 2, name = "Package 2")
        )
        coEvery { mockRepository.getPackages() } returns packages
        
        // When
        viewModel.loadPackages()
        
        // Then
        assertThat(viewModel.packages.value).isEqualTo(packages)
        assertThat(viewModel.isLoading.value).isFalse()
    }
    
    @Test
    fun `should handle error when loading packages fails`() = runTest {
        // Given
        val error = Exception("Network error")
        coEvery { mockRepository.getPackages() } throws error
        
        // When
        viewModel.loadPackages()
        
        // Then
        assertThat(viewModel.error.value).isEqualTo("Network error")
        assertThat(viewModel.isLoading.value).isFalse()
    }
}
```

## Integration Testing

### API Integration Tests
```kotlin
class ApiEndpointTest {
    
    private val json = Json {
        prettyPrint = true
        isLenient = true
        ignoreUnknownKeys = true
    }
    
    @Test
    fun `API health check should return success`() = testApplication {
        val response = client.get("/api")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val responseText = response.bodyAsText()
        assertTrue(responseText.contains("success"))
        assertTrue(responseText.contains("Permit Management System API"))
    }
    
    @Test
    fun `Counties endpoint should return valid JSON`() = testApplication {
        val response = client.get("/counties")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val responseText = response.bodyAsText()
        assertTrue(responseText.contains("success"))
        assertTrue(responseText.contains("data"))
        
        // Try to parse as ApiResponse<List<County>>
        val apiResponse = json.decodeFromString<ApiResponse<List<County>>>(responseText)
        assertTrue(apiResponse.success)
        assertNotNull(apiResponse.data)
    }
    
    @Test
    fun `Auth register endpoint should accept valid data`() = testApplication {
        val registerRequest = RegisterRequest(
            email = "test@example.com",
            password = "password123",
            firstName = "Test",
            lastName = "User"
        )
        
        val response = client.post("/auth/register") {
            contentType(ContentType.Application.Json)
            setBody(json.encodeToString(registerRequest))
        }
        
        // Should either succeed (201) or fail with validation error (400)
        assertTrue(response.status == HttpStatusCode.Created || response.status == HttpStatusCode.BadRequest)
    }
}
```

### Database Integration Tests
```kotlin
class DatabaseIntegrationTest {
    
    private lateinit var database: Database
    
    @BeforeEach
    fun setup() {
        database = Database.connect("jdbc:h2:mem:test", driver = "org.h2.Driver")
        SchemaUtils.create(Users, Counties, PermitPackages)
    }
    
    @AfterEach
    fun cleanup() {
        SchemaUtils.drop(Users, Counties, PermitPackages)
    }
    
    @Test
    fun `should create and retrieve user`() {
        transaction {
            // Create user
            val userId = Users.insert {
                it[email] = "test@example.com"
                it[password] = "hashed_password"
                it[firstName] = "Test"
                it[lastName] = "User"
                it[role] = "user"
            } get Users.id
            
            // Retrieve user
            val user = Users.select { Users.id eq userId }.single()
            
            assertThat(user[Users.email]).isEqualTo("test@example.com")
            assertThat(user[Users.firstName]).isEqualTo("Test")
            assertThat(user[Users.lastName]).isEqualTo("User")
        }
    }
    
    @Test
    fun `should create permit package with county relationship`() {
        transaction {
            // Create county
            val countyId = Counties.insert {
                it[name] = "Test County"
                it[state] = "FL"
            } get Counties.id
            
            // Create user
            val userId = Users.insert {
                it[email] = "test@example.com"
                it[password] = "hashed_password"
                it[firstName] = "Test"
                it[lastName] = "User"
                it[role] = "user"
            } get Users.id
            
            // Create permit package
            val packageId = PermitPackages.insert {
                it[PermitPackages.userId] = userId
                it[PermitPackages.countyId] = countyId
                it[name] = "Test Permit"
                it[description] = "Test Description"
                it[status] = "draft"
            } get PermitPackages.id
            
            // Verify relationship
            val package = PermitPackages
                .join(Counties, JoinType.INNER, PermitPackages.countyId, Counties.id)
                .select { PermitPackages.id eq packageId }
                .single()
            
            assertThat(package[PermitPackages.name]).isEqualTo("Test Permit")
            assertThat(package[Counties.name]).isEqualTo("Test County")
        }
    }
}
```

## End-to-End Testing

### Web Application E2E Tests
```kotlin
class WebApplicationE2ETest {
    
    @Test
    fun `should complete permit package creation workflow`() = testApplication {
        // Start the application
        val response = client.get("/")
        assertEquals(HttpStatusCode.OK, response.status)
        
        // Test user registration
        val registerResponse = client.post("/auth/register") {
            contentType(ContentType.Application.Json)
            setBody("""
                {
                    "email": "e2e@example.com",
                    "password": "password123",
                    "firstName": "E2E",
                    "lastName": "Test"
                }
            """.trimIndent())
        }
        
        assertTrue(registerResponse.status == HttpStatusCode.Created)
        
        // Extract token from response
        val token = extractTokenFromResponse(registerResponse)
        
        // Test permit package creation
        val packageResponse = client.post("/packages") {
            header("Authorization", "Bearer $token")
            contentType(ContentType.Application.Json)
            setBody("""
                {
                    "countyId": 1,
                    "name": "E2E Test Permit",
                    "description": "End-to-end test permit"
                }
            """.trimIndent())
        }
        
        assertEquals(HttpStatusCode.Created, packageResponse.status)
        
        // Verify package was created
        val packagesResponse = client.get("/packages") {
            header("Authorization", "Bearer $token")
        }
        
        assertEquals(HttpStatusCode.OK, packagesResponse.status)
        val packages = json.decodeFromString<ApiResponse<List<PermitPackage>>>(packagesResponse.bodyAsText())
        assertTrue(packages.data?.any { it.name == "E2E Test Permit" } == true)
    }
}
```

## Performance Testing

### Load Testing
```kotlin
class PerformanceTest {
    
    @Test
    fun `should handle concurrent requests`() = testApplication {
        val numberOfRequests = 100
        val concurrentRequests = 10
        
        val responses = (1..numberOfRequests).map { requestId ->
            async {
                client.get("/counties") {
                    header("X-Request-ID", requestId.toString())
                }
            }
        }.map { it.await() }
        
        // All requests should succeed
        responses.forEach { response ->
            assertEquals(HttpStatusCode.OK, response.status)
        }
        
        // Check response times
        val responseTimes = responses.map { response ->
            response.headers["X-Response-Time"]?.toLongOrNull() ?: 0L
        }
        
        val averageResponseTime = responseTimes.average()
        assertThat(averageResponseTime).isLessThan(1000.0) // Less than 1 second
    }
    
    @Test
    fun `should handle large dataset queries`() = testApplication {
        val startTime = System.currentTimeMillis()
        
        val response = client.get("/counties")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val endTime = System.currentTimeMillis()
        val responseTime = endTime - startTime
        
        // Should respond within 2 seconds even with large dataset
        assertThat(responseTime).isLessThan(2000)
    }
}
```

## Test Data Management

### Test Fixtures
```kotlin
object TestFixtures {
    
    fun createTestUser(): User {
        return User(
            id = 1,
            email = "test@example.com",
            firstName = "Test",
            lastName = "User",
            role = "user",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z"
        )
    }
    
    fun createTestCounty(): County {
        return County(
            id = 1,
            name = "Test County",
            state = "FL",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z"
        )
    }
    
    fun createTestPermitPackage(): PermitPackage {
        return PermitPackage(
            id = 1,
            userId = 1,
            countyId = 1,
            name = "Test Permit",
            description = "Test Description",
            status = "draft",
            customerName = "Test Customer",
            customerEmail = "customer@example.com",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z"
        )
    }
}
```

### Mock Data
```kotlin
object MockData {
    
    val mockCounties = listOf(
        County(id = 1, name = "Alachua County", state = "FL"),
        County(id = 2, name = "Baker County", state = "FL"),
        County(id = 3, name = "Bay County", state = "FL")
    )
    
    val mockUsers = listOf(
        User(id = 1, email = "user1@example.com", firstName = "John", lastName = "Doe"),
        User(id = 2, email = "user2@example.com", firstName = "Jane", lastName = "Smith")
    )
    
    val mockPermitPackages = listOf(
        PermitPackage(id = 1, userId = 1, countyId = 1, name = "Residential Permit"),
        PermitPackage(id = 2, userId = 2, countyId = 2, name = "Commercial Permit")
    )
}
```

## Test Configuration

### Test Environment Setup
```kotlin
// TestApplication.kt
fun Application.testModule() {
    install(ContentNegotiation) {
        json(Json {
            prettyPrint = true
            isLenient = true
            ignoreUnknownKeys = true
        })
    }
    
    // Use test database
    Database.connect("jdbc:h2:mem:test", driver = "org.h2.Driver")
    
    // Install test routes
    routing {
        configureTestRoutes()
    }
}
```

### Test Database Configuration
```kotlin
// TestDatabase.kt
object TestDatabase {
    
    fun setup() {
        Database.connect("jdbc:h2:mem:test", driver = "org.h2.Driver")
        transaction {
            SchemaUtils.create(Users, Counties, PermitPackages, ChecklistItems)
        }
    }
    
    fun cleanup() {
        transaction {
            SchemaUtils.drop(Users, Counties, PermitPackages, ChecklistItems)
        }
    }
    
    fun seedTestData() {
        transaction {
            // Insert test data
            TestFixtures.createTestUser().let { user ->
                Users.insert {
                    it[email] = user.email
                    it[password] = "hashed_password"
                    it[firstName] = user.firstName
                    it[lastName] = user.lastName
                    it[role] = user.role
                }
            }
        }
    }
}
```

## Running Tests

### Command Line
```bash
# Run all tests
./gradlew test

# Run specific test class
./gradlew :server:test --tests SerializationTest

# Run tests with coverage
./gradlew :server:jacocoTestReport

# Run integration tests
./gradlew :server:integrationTest

# Run performance tests
./gradlew :server:performanceTest
```

### IDE Integration
```kotlin
// IntelliJ IDEA
// Right-click on test class or method
// Select "Run 'TestName'"

// VS Code
// Use Kotlin Test Explorer extension
// Click play button next to test
```

### Continuous Integration
```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

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
    
    - name: Run tests
      run: ./gradlew test
    
    - name: Generate coverage report
      run: ./gradlew jacocoTestReport
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
```

## Test Coverage

### Coverage Configuration
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
    
    finalizedBy(tasks.jacocoTestCoverageVerification)
}

tasks.jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                minimum = "0.80".toBigDecimal()
            }
        }
    }
}
```

### Coverage Goals
- **Overall Coverage**: 80%+
- **Critical Paths**: 95%+
- **New Code**: 90%+
- **API Endpoints**: 100%

## Test Best Practices

### Writing Effective Tests

1. **Test Naming**
   ```kotlin
   // Good: Descriptive test names
   @Test
   fun `should create permit package when valid data provided`()
   
   @Test
   fun `should throw ValidationException when county ID is invalid`()
   
   // Bad: Vague test names
   @Test
   fun test1()
   
   @Test
   fun testCreatePackage()
   ```

2. **Test Structure (AAA Pattern)**
   ```kotlin
   @Test
   fun `should calculate total correctly`() {
       // Arrange (Given)
       val items = listOf(Item(price = 10.0), Item(price = 20.0))
       val calculator = PriceCalculator()
       
       // Act (When)
       val total = calculator.calculateTotal(items)
       
       // Assert (Then)
       assertThat(total).isEqualTo(30.0)
   }
   ```

3. **Test Isolation**
   ```kotlin
   @Test
   fun `should not affect other tests`() {
       // Each test should be independent
       // Use @BeforeEach and @AfterEach for setup/cleanup
       // Don't rely on test execution order
   }
   ```

### Mocking and Stubbing

```kotlin
// Use MockK for Kotlin mocking
class PermitServiceTest {
    
    @MockK
    private lateinit var permitRepository: PermitRepository
    
    @MockK
    private lateinit var countyService: CountyService
    
    @BeforeEach
    fun setup() {
        MockKAnnotations.init(this)
    }
    
    @Test
    fun `should create permit package`() = runTest {
        // Given
        val county = TestFixtures.createTestCounty()
        coEvery { countyService.getCounty(1) } returns county
        coEvery { permitRepository.save(any()) } returns TestFixtures.createTestPermitPackage()
        
        // When
        val result = permitService.createPermitPackage(1, "Test Permit")
        
        // Then
        assertThat(result.name).isEqualTo("Test Permit")
        coVerify { permitRepository.save(any()) }
    }
}
```

## Troubleshooting Tests

### Common Issues

1. **Database Connection Issues**
   ```kotlin
   // Ensure test database is properly configured
   @BeforeEach
   fun setup() {
       Database.connect("jdbc:h2:mem:test", driver = "org.h2.Driver")
       SchemaUtils.create(Users, Counties, PermitPackages)
   }
   ```

2. **Async Test Issues**
   ```kotlin
   // Use runTest for coroutine tests
   @Test
   fun `should handle async operation`() = runTest {
       val result = asyncOperation()
       assertThat(result).isNotNull()
   }
   ```

3. **Test Data Cleanup**
   ```kotlin
   // Always clean up test data
   @AfterEach
   fun cleanup() {
       SchemaUtils.drop(Users, Counties, PermitPackages)
   }
   ```

### Debugging Tests

1. **Enable Debug Logging**
   ```kotlin
   // Add to test configuration
   System.setProperty("org.slf4j.simpleLogger.defaultLogLevel", "debug")
   ```

2. **Test Output**
   ```kotlin
   @Test
   fun `should debug test output`() {
       println("Debug information: $debugData")
       // Use assertions for verification, not println
   }
   ```

This testing guide provides comprehensive coverage of testing strategies and practices for the Permit Management System. Follow these guidelines to ensure high-quality, reliable software.
