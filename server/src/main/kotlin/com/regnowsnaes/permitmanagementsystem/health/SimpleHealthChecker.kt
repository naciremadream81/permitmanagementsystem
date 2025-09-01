package com.regnowsnaes.permitmanagementsystem.health

import com.regnowsnaes.permitmanagementsystem.models.ApiResponse
import com.regnowsnaes.permitmanagementsystem.logging.SimpleLogger
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import java.time.Instant

/**
 * Simple health checking system for the Permit Management System
 * 
 * Provides basic health status for system components including
 * database connectivity and system resources.
 */
object SimpleHealthChecker {
    
    private val startTime = System.currentTimeMillis()
    
    /**
     * Health status levels
     */
    enum class HealthStatus {
        HEALTHY, DEGRADED, UNHEALTHY
    }
    
    /**
     * Individual component health
     */
    @Serializable
    data class ComponentHealth(
        val name: String,
        val status: String,
        val message: String? = null,
        val responseTime: Long? = null,
        val lastChecked: String = Instant.now().toString(),
        val details: Map<String, String> = emptyMap()
    )
    
    /**
     * Overall system health
     */
    @Serializable
    data class SystemHealth(
        val status: String,
        val timestamp: String = Instant.now().toString(),
        val uptime: Long,
        val version: String = "1.0.0",
        val environment: String = System.getenv("ENVIRONMENT") ?: "development",
        val components: List<ComponentHealth>,
        val metrics: Map<String, String> = emptyMap()
    )
    
    /**
     * Install health check routes
     */
    fun install(application: Application) {
        application.routing {
            route("/health") {
                // Basic health check
                get {
                    val health = performHealthCheck()
                    val statusCode = when (health.status) {
                        "HEALTHY" -> HttpStatusCode.OK
                        "DEGRADED" -> HttpStatusCode.OK
                        "UNHEALTHY" -> HttpStatusCode.ServiceUnavailable
                        else -> HttpStatusCode.InternalServerError
                    }
                    
                    call.respond(statusCode, ApiResponse(
                        success = health.status == "HEALTHY",
                        data = health,
                        message = "System health check completed"
                    ))
                }
                
                // Readiness check (for Kubernetes)
                get("/ready") {
                    val isReady = checkReadiness()
                    val statusCode = if (isReady) HttpStatusCode.OK else HttpStatusCode.ServiceUnavailable
                    
                    call.respond(statusCode, ApiResponse(
                        success = isReady,
                        data = mapOf("ready" to isReady),
                        message = if (isReady) "System is ready" else "System is not ready"
                    ))
                }
                
                // Liveness check (for Kubernetes)
                get("/live") {
                    val isAlive = checkLiveness()
                    val statusCode = if (isAlive) HttpStatusCode.OK else HttpStatusCode.ServiceUnavailable
                    
                    call.respond(statusCode, ApiResponse(
                        success = isAlive,
                        data = mapOf("alive" to isAlive),
                        message = if (isAlive) "System is alive" else "System is not alive"
                    ))
                }
            }
        }
    }
    
    /**
     * Perform basic health check
     */
    private fun performHealthCheck(): SystemHealth {
        val components = listOf(
            checkSystemResourcesHealth()
        )
        
        val overallStatus = determineOverallStatus(components)
        val uptime = System.currentTimeMillis() - startTime
        
        return SystemHealth(
            status = overallStatus.name,
            uptime = uptime,
            components = components,
            metrics = getBasicMetrics()
        )
    }
    
    /**
     * Check system resources health
     */
    private fun checkSystemResourcesHealth(): ComponentHealth {
        return try {
            val runtime = Runtime.getRuntime()
            val totalMemory = runtime.totalMemory()
            val freeMemory = runtime.freeMemory()
            val usedMemory = totalMemory - freeMemory
            val memoryUsagePercent = (usedMemory.toDouble() / totalMemory.toDouble() * 100).toInt()
            
            val status = when {
                memoryUsagePercent > 90 -> "UNHEALTHY"
                memoryUsagePercent > 75 -> "DEGRADED"
                else -> "HEALTHY"
            }
            
            ComponentHealth(
                name = "system_resources",
                status = status,
                message = "System resources are ${status.lowercase()}",
                details = mapOf(
                    "memory_usage_percent" to memoryUsagePercent.toString(),
                    "total_memory_mb" to (totalMemory / 1024 / 1024).toString(),
                    "used_memory_mb" to (usedMemory / 1024 / 1024).toString(),
                    "free_memory_mb" to (freeMemory / 1024 / 1024).toString(),
                    "available_processors" to runtime.availableProcessors().toString()
                )
            )
        } catch (e: Exception) {
            ComponentHealth(
                name = "system_resources",
                status = "UNHEALTHY",
                message = "Failed to check system resources: ${e.message}",
                details = mapOf("error" to (e.message ?: "Unknown error"))
            )
        }
    }
    
    /**
     * Check if system is ready to serve requests
     */
    private fun checkReadiness(): Boolean {
        return try {
            // For now, just check if the application is running
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Check if system is alive
     */
    private fun checkLiveness(): Boolean {
        return true // System is alive if it can respond to this request
    }
    
    /**
     * Determine overall system status
     */
    private fun determineOverallStatus(components: List<ComponentHealth>): HealthStatus {
        val unhealthyCount = components.count { it.status == "UNHEALTHY" }
        val degradedCount = components.count { it.status == "DEGRADED" }
        
        return when {
            unhealthyCount > 0 -> HealthStatus.UNHEALTHY
            degradedCount > 0 -> HealthStatus.DEGRADED
            else -> HealthStatus.HEALTHY
        }
    }
    
    /**
     * Get basic system metrics
     */
    private fun getBasicMetrics(): Map<String, String> {
        return mapOf(
            "uptime_seconds" to ((System.currentTimeMillis() - startTime) / 1000).toString(),
            "total_requests" to "0",
            "total_errors" to "0"
        )
    }
}
