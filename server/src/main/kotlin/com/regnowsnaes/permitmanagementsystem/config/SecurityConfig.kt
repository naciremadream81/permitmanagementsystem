package com.regnowsnaes.permitmanagementsystem.config

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.cors.routing.*
import io.ktor.server.response.*

object SecurityConfig {
    
    fun Application.configureSecurity() {
        // Configure CORS with production-safe settings
        install(CORS) {
            // Only allow specific methods
            allowMethod(HttpMethod.Get)
            allowMethod(HttpMethod.Post)
            allowMethod(HttpMethod.Put)
            allowMethod(HttpMethod.Delete)
            allowMethod(HttpMethod.Options)
            
            // Only allow necessary headers
            allowHeader(HttpHeaders.Authorization)
            allowHeader(HttpHeaders.ContentType)
            allowHeader(HttpHeaders.Accept)
            allowHeader("X-Requested-With")
            
            // Configure allowed origins based on environment
            val allowedOrigins = System.getenv("CORS_ALLOWED_ORIGINS")?.split(",") ?: listOf()
            val environment = System.getenv("ENVIRONMENT") ?: "development"
            
            when (environment) {
                "production" -> {
                    // Only allow specific domains in production
                    allowedOrigins.forEach { origin ->
                        val cleanOrigin = origin.trim().removePrefix("https://").removePrefix("http://")
                        allowHost(cleanOrigin, schemes = listOf("https"))
                    }
                }
                "staging" -> {
                    // Allow staging domains
                    allowedOrigins.forEach { origin ->
                        val cleanOrigin = origin.trim().removePrefix("https://").removePrefix("http://")
                        allowHost(cleanOrigin, schemes = listOf("https", "http"))
                    }
                }
                else -> {
                    // Development - allow localhost
                    allowHost("localhost:3000")
                    allowHost("127.0.0.1:3000")
                    allowHost("localhost:8080")
                    anyHost() // Only for development
                }
            }
            
            // Security headers
            allowCredentials = false // Disable credentials for security
            maxAgeInSeconds = 86400 // 24 hours
        }
    }
    
    fun validateEnvironmentVariables(): List<String> {
        val errors = mutableListOf<String>()
        
        val requiredVars = mapOf(
            "DATABASE_URL" to System.getenv("DATABASE_URL"),
            "DB_USER" to System.getenv("DB_USER"),
            "DB_PASSWORD" to System.getenv("DB_PASSWORD"),
            "JWT_SECRET" to System.getenv("JWT_SECRET")
        )
        
        requiredVars.forEach { (key, value) ->
            when {
                value.isNullOrBlank() -> errors.add("$key is required but not set")
                key == "JWT_SECRET" && value.length < 32 -> 
                    errors.add("JWT_SECRET must be at least 32 characters long")
                key == "DB_PASSWORD" && value.length < 8 -> 
                    errors.add("DB_PASSWORD should be at least 8 characters long")
            }
        }
        
        return errors
    }
    
    fun getSecurityHeaders(): Map<String, String> {
        return mapOf(
            "X-Content-Type-Options" to "nosniff",
            "X-Frame-Options" to "DENY",
            "X-XSS-Protection" to "1; mode=block",
            "Strict-Transport-Security" to "max-age=31536000; includeSubDomains",
            "Content-Security-Policy" to "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'",
            "Referrer-Policy" to "strict-origin-when-cross-origin"
        )
    }
}
