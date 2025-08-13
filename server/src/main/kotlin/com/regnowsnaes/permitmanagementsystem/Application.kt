package com.regnowsnaes.permitmanagementsystem

import com.regnowsnaes.permitmanagementsystem.config.SecurityConfig
import com.regnowsnaes.permitmanagementsystem.database.DatabaseConfig
import com.regnowsnaes.permitmanagementsystem.routes.authRoutes
import com.regnowsnaes.permitmanagementsystem.routes.configurePermitRoutes
import com.regnowsnaes.permitmanagementsystem.routes.configureDocumentRoutes
// import com.regnowsnaes.permitmanagementsystem.routes.adminRoutes
import com.regnowsnaes.permitmanagementsystem.routes.healthRoutes
import com.regnowsnaes.permitmanagementsystem.routes.configureChecklistRoutes
import com.regnowsnaes.permitmanagementsystem.services.PermitService
import com.regnowsnaes.permitmanagementsystem.services.AuthService
import com.regnowsnaes.permitmanagementsystem.models.ApiResponse
// Advanced features temporarily disabled for compilation
// import com.regnowsnaes.permitmanagementsystem.routes.configureBulkOperationsRoutes
// import com.regnowsnaes.permitmanagementsystem.routes.configureTemplatesRoutes
// import com.regnowsnaes.permitmanagementsystem.routes.configureAdminAuthRoutes
// import com.regnowsnaes.permitmanagementsystem.routes.configureDocumentRoutes
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.server.plugins.contentnegotiation.*
import io.ktor.server.plugins.statuspages.*

import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.ktor.server.http.content.*
import kotlinx.serialization.json.Json
import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import java.io.File
import kotlin.system.exitProcess

fun main() {
    // Validate environment variables before starting
    val validationErrors = SecurityConfig.validateEnvironmentVariables()
    if (validationErrors.isNotEmpty()) {
        println("❌ Environment validation failed:")
        validationErrors.forEach { println("  - $it") }
        println("\nPlease fix these issues before starting the server.")
        exitProcess(1)
    }
    
    // Initialize database
    try {
        DatabaseConfig.init()
        println("✅ Database initialized successfully")
    } catch (e: Exception) {
        println("❌ Database initialization failed: ${e.message}")
        exitProcess(1)
    }
    
    val port = System.getenv("SERVER_PORT")?.toIntOrNull() ?: 8080
    val host = System.getenv("SERVER_HOST") ?: "0.0.0.0"
    
    println("🚀 Starting Permit Management System Server")
    println("   Environment: ${System.getenv("ENVIRONMENT") ?: "development"}")
    println("   Server: $host:$port")
    println("   Database: ${System.getenv("DATABASE_URL")?.substringBefore("?") ?: "unknown"}")
    
    embeddedServer(Netty, port = port, host = host, module = Application::module)
        .start(wait = true)
}

fun Application.module() {
                // Install content negotiation
            install(ContentNegotiation) {
                json(Json {
                    prettyPrint = true
                    isLenient = true
                    ignoreUnknownKeys = true
                })
            }
            

    
    // Configure security (CORS, etc.)
    SecurityConfig.run { configureSecurity() }
    
    // Install Status Pages for error handling
    install(StatusPages) {
        exception<Throwable> { call, cause ->
            val environment = System.getenv("ENVIRONMENT") ?: "development"
            
            // Log the error
            call.application.log.error("Unhandled exception", cause)
            
            // Return appropriate error response
            val errorResponse = if (environment == "production") {
                mapOf(
                    "error" to "Internal server error",
                    "timestamp" to System.currentTimeMillis(),
                    "path" to call.request.uri
                )
            } else {
                mapOf(
                    "error" to (cause.message ?: "Unknown error"),
                    "type" to cause.javaClass.simpleName,
                    "timestamp" to System.currentTimeMillis(),
                    "path" to call.request.uri,
                    "stackTrace" to cause.stackTrace.take(5).map { it.toString() }
                )
            }
            
            // Add security headers
            SecurityConfig.getSecurityHeaders().forEach { (key, value) ->
                call.response.header(key, value)
            }
            
            call.respond(HttpStatusCode.InternalServerError, errorResponse)
        }
        
        status(HttpStatusCode.NotFound) { call, status ->
            call.respond(
                status,
                mapOf(
                    "error" to "Endpoint not found",
                    "path" to call.request.uri,
                    "method" to call.request.httpMethod.value,
                    "timestamp" to System.currentTimeMillis()
                )
            )
        }
        
        status(HttpStatusCode.Unauthorized) { call, status ->
            call.respond(
                status,
                mapOf(
                    "error" to "Authentication required",
                    "message" to "Please provide a valid JWT token",
                    "timestamp" to System.currentTimeMillis()
                )
            )
        }
    }
    
    // Install JWT Authentication
    val jwtSecret = System.getenv("JWT_SECRET") ?: "your-secret-key-change-in-production"
    install(Authentication) {
        jwt("auth-jwt") {
            verifier(
                JWT
                    .require(Algorithm.HMAC256(jwtSecret))
                    .build()
            )
            validate { credential ->
                if (credential.payload.getClaim("userId").asInt() != null) {
                    JWTPrincipal(credential.payload)
                } else {
                    null
                }
            }
            challenge { defaultScheme, realm ->
                call.respond(
                    HttpStatusCode.Unauthorized, 
                    mapOf(
                        "error" to "Token is not valid or has expired",
                        "timestamp" to System.currentTimeMillis()
                    )
                )
            }
        }
    }
    
    routing {
        // Add security headers to all responses
        intercept(ApplicationCallPipeline.Plugins) {
            SecurityConfig.getSecurityHeaders().forEach { (key, value) ->
                call.response.header(key, value)
            }
        }
        
        // Health check endpoints (must be first for load balancers)
        healthRoutes()
        
                        // Basic health check endpoint
                get("/") {
                    try {
                        call.respondText(
                            contentType = ContentType.Text.Html,
                            text = File("web-interface.html").readText()
                        )
                    } catch (e: Exception) {
                        call.respondText(
                            contentType = ContentType.Text.Html,
                            text = """
                                <html><body>
                                <h1>File Reading Error</h1>
                                <p>Error: ${e.message}</p>
                                <p>Working directory: ${System.getProperty("user.dir")}</p>
                                <p>Files in current directory:</p>
                                <ul>
                                ${File(".").listFiles()?.joinToString("") { "<li>${it.name}</li>" } ?: "No files found"}
                                </ul>
                                </body></html>
                            """.trimIndent()
                        )
                    }
                }
        
        // Debug endpoint to test file reading
        get("/debug") {
            val currentDir = System.getProperty("user.dir")
            val files = File(".").listFiles()?.map { it.name }?.sorted() ?: emptyList()
            
            call.respondText(
                contentType = ContentType.Text.Html,
                text = """
                    <html><body>
                    <h1>Debug Information</h1>
                    <p><strong>Working Directory:</strong> $currentDir</p>
                    <p><strong>Files in current directory:</strong></p>
                    <ul>
                    ${files.joinToString("") { "<li>$it</li>" }}
                    </ul>
                    <p><strong>web-app-fixed.html exists:</strong> ${File("web-app-fixed.html").exists()}</p>
                    <p><strong>web-app-fixed.html readable:</strong> ${File("web-app-fixed.html").canRead()}</p>
                    </body></html>
                """.trimIndent()
            )
        }
        
        // Original production interface
        get("/production") {
            call.respondText(
                contentType = ContentType.Text.Html,
                text = File("web-app-production.html").readText()
            )
        }
        
        // Test interface
        get("/test") {
            call.respondText(
                contentType = ContentType.Text.Html,
                text = File("web-test.html").readText()
            )
        }
        
                        // API health check endpoint
                get("/api") {
                    call.respond(
                        ApiResponse(
                            success = true,
                            data = mapOf(
                                "message" to "Permit Management System API is running",
                                "version" to "1.0.0",
                                "environment" to (System.getenv("ENVIRONMENT") ?: "development"),
                                "timestamp" to System.currentTimeMillis().toString()
                            )
                        )
                    )
                }
        
                        // API routes
                authRoutes()
                configurePermitRoutes(AuthService)
                configureDocumentRoutes(AuthService)
                // adminRoutes() // Temporarily disabled due to compilation issues
        
        // Static file serving for uploaded documents
        static("/uploads") {
            files("uploads")
        }
    }
    
    // Configure checklist management routes
    configureChecklistRoutes()
    
    // Advanced admin features temporarily disabled for compilation
    // configureBulkOperationsRoutes()
    // configureTemplatesRoutes()
    // configureAdminAuthRoutes()
    // configureDocumentRoutes()
}
