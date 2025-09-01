package com.regnowsnaes.permitmanagementsystem.logging

import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import org.slf4j.LoggerFactory
import java.time.Instant

/**
 * Simple structured logging for the Permit Management System
 * 
 * Provides basic structured logging with proper context and metadata
 * for better observability.
 */
object SimpleLogger {
    
    private val logger = LoggerFactory.getLogger("PermitManagementSystem")
    
    /**
     * Log levels for structured logging
     */
    enum class LogLevel {
        TRACE, DEBUG, INFO, WARN, ERROR, FATAL
    }
    
    /**
     * Log a structured message
     */
    fun log(
        level: LogLevel,
        message: String,
        traceId: String? = null,
        userId: String? = null,
        endpoint: String? = null,
        method: String? = null,
        statusCode: Int? = null,
        duration: Long? = null,
        error: Throwable? = null,
        metadata: Map<String, String> = emptyMap()
    ) {
        val logEntry = buildString {
            append("timestamp=${Instant.now()}")
            append(" level=${level.name}")
            append(" message=\"$message\"")
            traceId?.let { append(" traceId=$it") }
            userId?.let { append(" userId=$it") }
            endpoint?.let { append(" endpoint=$it") }
            method?.let { append(" method=$it") }
            statusCode?.let { append(" statusCode=$it") }
            duration?.let { append(" duration=${it}ms") }
            error?.let { append(" error=\"${it.message}\"") }
            metadata.forEach { (key, value) ->
                append(" $key=\"$value\"")
            }
        }
        
        when (level) {
            LogLevel.TRACE -> logger.trace(logEntry)
            LogLevel.DEBUG -> logger.debug(logEntry)
            LogLevel.INFO -> logger.info(logEntry)
            LogLevel.WARN -> logger.warn(logEntry)
            LogLevel.ERROR -> logger.error(logEntry)
            LogLevel.FATAL -> logger.error("FATAL: $logEntry")
        }
    }
    
    /**
     * Log info message
     */
    fun info(
        message: String,
        traceId: String? = null,
        userId: String? = null,
        endpoint: String? = null,
        metadata: Map<String, String> = emptyMap()
    ) {
        log(LogLevel.INFO, message, traceId = traceId, userId = userId, endpoint = endpoint, metadata = metadata)
    }
    
    /**
     * Log error message
     */
    fun error(
        message: String,
        error: Throwable? = null,
        traceId: String? = null,
        userId: String? = null,
        endpoint: String? = null,
        metadata: Map<String, String> = emptyMap()
    ) {
        log(LogLevel.ERROR, message, error = error, traceId = traceId, userId = userId, endpoint = endpoint, metadata = metadata)
    }
    
    /**
     * Log warning message
     */
    fun warn(
        message: String,
        traceId: String? = null,
        userId: String? = null,
        endpoint: String? = null,
        metadata: Map<String, String> = emptyMap()
    ) {
        log(LogLevel.WARN, message, traceId = traceId, userId = userId, endpoint = endpoint, metadata = metadata)
    }
    
    /**
     * Log debug message
     */
    fun debug(
        message: String,
        traceId: String? = null,
        userId: String? = null,
        endpoint: String? = null,
        metadata: Map<String, String> = emptyMap()
    ) {
        log(LogLevel.DEBUG, message, traceId = traceId, userId = userId, endpoint = endpoint, metadata = metadata)
    }
    
    /**
     * Log API request
     */
    fun logRequest(
        method: String,
        endpoint: String,
        userId: String? = null,
        requestId: String? = null,
        traceId: String? = null,
        metadata: Map<String, String> = emptyMap()
    ) {
        log(
            level = LogLevel.INFO,
            message = "API Request",
            traceId = traceId,
            userId = userId,
            endpoint = endpoint,
            method = method,
            metadata = metadata
        )
    }
    
    /**
     * Log API response
     */
    fun logResponse(
        method: String,
        endpoint: String,
        statusCode: Int,
        duration: Long,
        userId: String? = null,
        requestId: String? = null,
        traceId: String? = null,
        metadata: Map<String, String> = emptyMap()
    ) {
        log(
            level = if (statusCode >= 400) LogLevel.WARN else LogLevel.INFO,
            message = "API Response",
            traceId = traceId,
            userId = userId,
            endpoint = endpoint,
            method = method,
            statusCode = statusCode,
            duration = duration,
            metadata = metadata
        )
    }
    
    /**
     * Log database operation
     */
    fun logDatabaseOperation(
        operation: String,
        table: String,
        duration: Long,
        userId: String? = null,
        traceId: String? = null,
        metadata: Map<String, String> = emptyMap()
    ) {
        log(
            level = LogLevel.DEBUG,
            message = "Database Operation",
            traceId = traceId,
            userId = userId,
            metadata = metadata + mapOf(
                "operation" to operation,
                "table" to table,
                "duration_ms" to duration.toString()
            )
        )
    }
    
    /**
     * Log authentication event
     */
    fun logAuthEvent(
        event: String,
        userId: String? = null,
        email: String? = null,
        success: Boolean,
        traceId: String? = null,
        metadata: Map<String, String> = emptyMap()
    ) {
        log(
            level = if (success) LogLevel.INFO else LogLevel.WARN,
            message = "Authentication Event",
            traceId = traceId,
            userId = userId,
            metadata = metadata + mapOf(
                "event" to event,
                "email" to (email ?: "unknown"),
                "success" to success.toString()
            )
        )
    }
}

/**
 * Extension function to generate request ID
 */
fun generateRequestId(): String {
    return java.util.UUID.randomUUID().toString().substring(0, 8)
}

/**
 * Extension function to generate trace ID
 */
fun generateTraceId(): String {
    return java.util.UUID.randomUUID().toString()
}
