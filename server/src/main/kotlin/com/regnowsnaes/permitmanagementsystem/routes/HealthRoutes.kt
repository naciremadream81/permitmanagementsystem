package com.regnowsnaes.permitmanagementsystem.routes

import com.regnowsnaes.permitmanagementsystem.database.Users
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import java.io.File
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

@Serializable
data class HealthStatus(
    val status: String,
    val timestamp: String,
    val version: String,
    val environment: String,
    val uptime: Long,
    val checks: Map<String, HealthCheck>
)

@Serializable
data class HealthCheck(
    val status: String,
    val message: String,
    val responseTime: Long? = null,
    val details: Map<String, String>? = null
)

fun Route.healthRoutes() {
    val startTime = System.currentTimeMillis()
    
    route("/health") {
        // Basic health check
        get {
            val healthStatus = performHealthChecks(startTime)
            val httpStatus = if (healthStatus.status == "healthy") HttpStatusCode.OK else HttpStatusCode.ServiceUnavailable
            call.respond(httpStatus, healthStatus)
        }
        
        // Detailed health check
        get("/detailed") {
            val healthStatus = performDetailedHealthChecks(startTime)
            val httpStatus = if (healthStatus.status == "healthy") HttpStatusCode.OK else HttpStatusCode.ServiceUnavailable
            call.respond(httpStatus, healthStatus)
        }
        
        // Database health check
        get("/db") {
            val dbCheck = checkDatabase()
            val httpStatus = if (dbCheck.status == "healthy") HttpStatusCode.OK else HttpStatusCode.ServiceUnavailable
            call.respond(httpStatus, dbCheck)
        }
        
        // Readiness probe (for Kubernetes)
        get("/ready") {
            val checks = mapOf(
                "database" to checkDatabase(),
                "filesystem" to checkFilesystem()
            )
            
            val allHealthy = checks.values.all { it.status == "healthy" }
            val status = if (allHealthy) "ready" else "not_ready"
            val httpStatus = if (allHealthy) HttpStatusCode.OK else HttpStatusCode.ServiceUnavailable
            
            call.respond(httpStatus, mapOf(
                "status" to status,
                "checks" to checks
            ))
        }
        
        // Liveness probe (for Kubernetes)
        get("/live") {
            call.respond(HttpStatusCode.OK, mapOf(
                "status" to "alive",
                "timestamp" to LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            ))
        }
    }
}

private fun performHealthChecks(startTime: Long): HealthStatus {
    val checks = mutableMapOf<String, HealthCheck>()
    
    // Database check
    checks["database"] = checkDatabase()
    
    // Filesystem check
    checks["filesystem"] = checkFilesystem()
    
    // Memory check
    checks["memory"] = checkMemory()
    
    val allHealthy = checks.values.all { it.status == "healthy" }
    val overallStatus = if (allHealthy) "healthy" else "unhealthy"
    
    return HealthStatus(
        status = overallStatus,
        timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
        version = "1.0.0",
        environment = System.getenv("ENVIRONMENT") ?: "development",
        uptime = System.currentTimeMillis() - startTime,
        checks = checks
    )
}

private fun performDetailedHealthChecks(startTime: Long): HealthStatus {
    val checks = mutableMapOf<String, HealthCheck>()
    
    // All basic checks
    checks["database"] = checkDatabase()
    checks["filesystem"] = checkFilesystem()
    checks["memory"] = checkMemory()
    
    // Additional detailed checks
    checks["disk_space"] = checkDiskSpace()
    checks["environment"] = checkEnvironmentVariables()
    checks["jwt_config"] = checkJWTConfiguration()
    
    val allHealthy = checks.values.all { it.status == "healthy" }
    val overallStatus = if (allHealthy) "healthy" else "unhealthy"
    
    return HealthStatus(
        status = overallStatus,
        timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
        version = "1.0.0",
        environment = System.getenv("ENVIRONMENT") ?: "development",
        uptime = System.currentTimeMillis() - startTime,
        checks = checks
    )
}

private fun checkDatabase(): HealthCheck {
    return try {
        val startTime = System.currentTimeMillis()
        val userCount = transaction {
            Users.selectAll().count()
        }
        val responseTime = System.currentTimeMillis() - startTime
        
        HealthCheck(
            status = "healthy",
            message = "Database connection successful",
            responseTime = responseTime,
            details = mapOf(
                "user_count" to userCount.toString(),
                "connection_url" to (System.getenv("DATABASE_URL")?.substringBefore("?") ?: "unknown")
            )
        )
    } catch (e: Exception) {
        HealthCheck(
            status = "unhealthy",
            message = "Database connection failed: ${e.message}",
            details = mapOf("error" to e.javaClass.simpleName)
        )
    }
}

private fun checkFilesystem(): HealthCheck {
    return try {
        val uploadsDir = File("uploads")
        val logsDir = File("logs")
        
        val uploadsExists = uploadsDir.exists() || uploadsDir.mkdirs()
        val logsExists = logsDir.exists() || logsDir.mkdirs()
        
        if (uploadsExists && logsExists) {
            HealthCheck(
                status = "healthy",
                message = "Filesystem access successful",
                details = mapOf(
                    "uploads_dir" to uploadsDir.absolutePath,
                    "logs_dir" to logsDir.absolutePath,
                    "uploads_writable" to uploadsDir.canWrite().toString(),
                    "logs_writable" to logsDir.canWrite().toString()
                )
            )
        } else {
            HealthCheck(
                status = "unhealthy",
                message = "Cannot create required directories",
                details = mapOf(
                    "uploads_exists" to uploadsExists.toString(),
                    "logs_exists" to logsExists.toString()
                )
            )
        }
    } catch (e: Exception) {
        HealthCheck(
            status = "unhealthy",
            message = "Filesystem check failed: ${e.message}",
            details = mapOf("error" to e.javaClass.simpleName)
        )
    }
}

private fun checkMemory(): HealthCheck {
    val runtime = Runtime.getRuntime()
    val maxMemory = runtime.maxMemory()
    val totalMemory = runtime.totalMemory()
    val freeMemory = runtime.freeMemory()
    val usedMemory = totalMemory - freeMemory
    val memoryUsagePercent = (usedMemory.toDouble() / maxMemory * 100).toInt()
    
    val status = when {
        memoryUsagePercent > 90 -> "unhealthy"
        memoryUsagePercent > 80 -> "warning"
        else -> "healthy"
    }
    
    val message = when (status) {
        "unhealthy" -> "Memory usage critically high"
        "warning" -> "Memory usage high"
        else -> "Memory usage normal"
    }
    
    return HealthCheck(
        status = status,
        message = message,
        details = mapOf(
            "max_memory_mb" to (maxMemory / 1024 / 1024).toString(),
            "total_memory_mb" to (totalMemory / 1024 / 1024).toString(),
            "used_memory_mb" to (usedMemory / 1024 / 1024).toString(),
            "free_memory_mb" to (freeMemory / 1024 / 1024).toString(),
            "usage_percent" to "$memoryUsagePercent%"
        )
    )
}

private fun checkDiskSpace(): HealthCheck {
    return try {
        val currentDir = File(".")
        val totalSpace = currentDir.totalSpace
        val freeSpace = currentDir.freeSpace
        val usedSpace = totalSpace - freeSpace
        val usagePercent = (usedSpace.toDouble() / totalSpace * 100).toInt()
        
        val status = when {
            usagePercent > 95 -> "unhealthy"
            usagePercent > 85 -> "warning"
            else -> "healthy"
        }
        
        val message = when (status) {
            "unhealthy" -> "Disk space critically low"
            "warning" -> "Disk space low"
            else -> "Disk space sufficient"
        }
        
        HealthCheck(
            status = status,
            message = message,
            details = mapOf(
                "total_space_gb" to (totalSpace / 1024 / 1024 / 1024).toString(),
                "free_space_gb" to (freeSpace / 1024 / 1024 / 1024).toString(),
                "used_space_gb" to (usedSpace / 1024 / 1024 / 1024).toString(),
                "usage_percent" to "$usagePercent%"
            )
        )
    } catch (e: Exception) {
        HealthCheck(
            status = "unhealthy",
            message = "Disk space check failed: ${e.message}",
            details = mapOf("error" to e.javaClass.simpleName)
        )
    }
}

private fun checkEnvironmentVariables(): HealthCheck {
    val requiredVars = listOf(
        "DATABASE_URL", "DB_USER", "DB_PASSWORD", "JWT_SECRET"
    )
    
    val missingVars = requiredVars.filter { System.getenv(it).isNullOrBlank() }
    val weakJWT = System.getenv("JWT_SECRET")?.let { it.length < 32 } ?: true
    
    return when {
        missingVars.isNotEmpty() -> HealthCheck(
            status = "unhealthy",
            message = "Required environment variables missing",
            details = mapOf("missing_vars" to missingVars.joinToString(", "))
        )
        weakJWT -> HealthCheck(
            status = "warning",
            message = "JWT secret should be at least 32 characters",
            details = mapOf("jwt_length" to (System.getenv("JWT_SECRET")?.length?.toString() ?: "0"))
        )
        else -> HealthCheck(
            status = "healthy",
            message = "All required environment variables present",
            details = mapOf("checked_vars" to requiredVars.joinToString(", "))
        )
    }
}

private fun checkJWTConfiguration(): HealthCheck {
    val jwtSecret = System.getenv("JWT_SECRET")
    
    return when {
        jwtSecret.isNullOrBlank() -> HealthCheck(
            status = "unhealthy",
            message = "JWT secret not configured"
        )
        jwtSecret == "your-secret-key-change-in-production" -> HealthCheck(
            status = "unhealthy",
            message = "JWT secret is using default value - security risk!"
        )
        jwtSecret.length < 32 -> HealthCheck(
            status = "warning",
            message = "JWT secret should be at least 32 characters for security"
        )
        else -> HealthCheck(
            status = "healthy",
            message = "JWT configuration is secure"
        )
    }
}
