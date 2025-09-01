package com.regnowsnaes.permitmanagementsystem.error

import com.regnowsnaes.permitmanagementsystem.models.ApiResponse
import com.regnowsnaes.permitmanagementsystem.logging.SimpleLogger
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.statuspages.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import kotlinx.serialization.Serializable
import java.time.Instant

/**
 * Simple error handling for the Permit Management System
 * 
 * Provides consistent error responses with proper HTTP status codes
 * and helpful error messages for debugging.
 */
object SimpleErrorHandler {
    
    /**
     * Custom exception classes for better error handling
     */
    class ValidationException(message: String, val field: String? = null) : Exception(message)
    class AuthenticationException(message: String) : Exception(message)
    class AuthorizationException(message: String) : Exception(message)
    class ResourceNotFoundException(message: String, val resourceType: String? = null) : Exception(message)
    class BusinessLogicException(message: String) : Exception(message)
    class ExternalServiceException(message: String, val service: String? = null) : Exception(message)
    
    /**
     * Error response structure
     */
    @Serializable
    data class ErrorResponse(
        val success: Boolean = false,
        val error: String,
        val message: String? = null,
        val code: String? = null,
        val field: String? = null,
        val timestamp: String = Instant.now().toString(),
        val path: String? = null,
        val method: String? = null
    )
    
    /**
     * Install error handling
     */
    fun install(application: Application) {
        application.install(StatusPages) {
            // Handle validation errors
            exception<ValidationException> { call, cause ->
                handleValidationError(call, cause)
            }
            
            // Handle authentication errors
            exception<AuthenticationException> { call, cause ->
                handleAuthenticationError(call, cause)
            }
            
            // Handle authorization errors
            exception<AuthorizationException> { call, cause ->
                handleAuthorizationError(call, cause)
            }
            
            // Handle resource not found errors
            exception<ResourceNotFoundException> { call, cause ->
                handleResourceNotFoundError(call, cause)
            }
            
            // Handle business logic errors
            exception<BusinessLogicException> { call, cause ->
                handleBusinessLogicError(call, cause)
            }
            
            // Handle external service errors
            exception<ExternalServiceException> { call, cause ->
                handleExternalServiceError(call, cause)
            }
            
            // Handle generic exceptions
            exception<Throwable> { call, cause ->
                handleGenericError(call, cause)
            }
            
            // Handle HTTP status codes
            status(HttpStatusCode.NotFound) { call, status ->
                handleNotFound(call, status)
            }
            
            status(HttpStatusCode.Unauthorized) { call, status ->
                handleUnauthorized(call, status)
            }
            
            status(HttpStatusCode.Forbidden) { call, status ->
                handleForbidden(call, status)
            }
            
            status(HttpStatusCode.BadRequest) { call, status ->
                handleBadRequest(call, status)
            }
            
            status(HttpStatusCode.InternalServerError) { call, status ->
                handleInternalServerError(call, status)
            }
        }
    }
    
    private suspend fun handleValidationError(call: ApplicationCall, cause: ValidationException) {
        val errorResponse = ErrorResponse(
            error = "Validation failed",
            message = cause.message,
            code = "VALIDATION_ERROR",
            field = cause.field,
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        SimpleLogger.warn(
            message = "Validation error: ${cause.message}",
            endpoint = call.request.uri,
            metadata = mapOf(
                "field" to (cause.field ?: "unknown"),
                "error_type" to "validation"
            )
        )
        
        call.respond(HttpStatusCode.BadRequest, errorResponse)
    }
    
    private suspend fun handleAuthenticationError(call: ApplicationCall, cause: AuthenticationException) {
        val errorResponse = ErrorResponse(
            error = "Authentication failed",
            message = cause.message,
            code = "AUTHENTICATION_ERROR",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        SimpleLogger.warn(
            message = "Authentication error: ${cause.message}",
            endpoint = call.request.uri,
            metadata = mapOf("error_type" to "authentication")
        )
        
        call.respond(HttpStatusCode.Unauthorized, errorResponse)
    }
    
    private suspend fun handleAuthorizationError(call: ApplicationCall, cause: AuthorizationException) {
        val errorResponse = ErrorResponse(
            error = "Access denied",
            message = cause.message,
            code = "AUTHORIZATION_ERROR",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        SimpleLogger.warn(
            message = "Authorization error: ${cause.message}",
            endpoint = call.request.uri,
            metadata = mapOf("error_type" to "authorization")
        )
        
        call.respond(HttpStatusCode.Forbidden, errorResponse)
    }
    
    private suspend fun handleResourceNotFoundError(call: ApplicationCall, cause: ResourceNotFoundException) {
        val errorResponse = ErrorResponse(
            error = "Resource not found",
            message = cause.message,
            code = "RESOURCE_NOT_FOUND",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        SimpleLogger.info(
            message = "Resource not found: ${cause.message}",
            endpoint = call.request.uri,
            metadata = mapOf(
                "resource_type" to (cause.resourceType ?: "unknown"),
                "error_type" to "not_found"
            )
        )
        
        call.respond(HttpStatusCode.NotFound, errorResponse)
    }
    
    private suspend fun handleBusinessLogicError(call: ApplicationCall, cause: BusinessLogicException) {
        val errorResponse = ErrorResponse(
            error = "Business logic error",
            message = cause.message,
            code = "BUSINESS_LOGIC_ERROR",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        SimpleLogger.warn(
            message = "Business logic error: ${cause.message}",
            endpoint = call.request.uri,
            metadata = mapOf("error_type" to "business_logic")
        )
        
        call.respond(HttpStatusCode.BadRequest, errorResponse)
    }
    
    private suspend fun handleExternalServiceError(call: ApplicationCall, cause: ExternalServiceException) {
        val errorResponse = ErrorResponse(
            error = "External service error",
            message = cause.message,
            code = "EXTERNAL_SERVICE_ERROR",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        SimpleLogger.error(
            message = "External service error: ${cause.message}",
            error = cause,
            endpoint = call.request.uri,
            metadata = mapOf(
                "service" to (cause.service ?: "unknown"),
                "error_type" to "external_service"
            )
        )
        
        call.respond(HttpStatusCode.BadGateway, errorResponse)
    }
    
    private suspend fun handleGenericError(call: ApplicationCall, cause: Throwable) {
        val environment = System.getenv("ENVIRONMENT") ?: "development"
        
        val errorResponse = ErrorResponse(
            error = "Internal server error",
            message = if (environment == "production") {
                "An unexpected error occurred. Please try again later."
            } else {
                cause.message ?: "Unknown error"
            },
            code = "INTERNAL_SERVER_ERROR",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        SimpleLogger.error(
            message = "Unhandled exception: ${cause.message}",
            error = cause,
            endpoint = call.request.uri,
            metadata = mapOf(
                "exception_type" to cause.javaClass.simpleName,
                "error_type" to "unhandled_exception"
            )
        )
        
        call.respond(HttpStatusCode.InternalServerError, errorResponse)
    }
    
    private suspend fun handleNotFound(call: ApplicationCall, status: HttpStatusCode) {
        val errorResponse = ErrorResponse(
            error = "Endpoint not found",
            message = "The requested endpoint does not exist",
            code = "NOT_FOUND",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        call.respond(status, errorResponse)
    }
    
    private suspend fun handleUnauthorized(call: ApplicationCall, status: HttpStatusCode) {
        val errorResponse = ErrorResponse(
            error = "Authentication required",
            message = "Please provide a valid authentication token",
            code = "UNAUTHORIZED",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        call.respond(status, errorResponse)
    }
    
    private suspend fun handleForbidden(call: ApplicationCall, status: HttpStatusCode) {
        val errorResponse = ErrorResponse(
            error = "Access denied",
            message = "You do not have permission to access this resource",
            code = "FORBIDDEN",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        call.respond(status, errorResponse)
    }
    
    private suspend fun handleBadRequest(call: ApplicationCall, status: HttpStatusCode) {
        val errorResponse = ErrorResponse(
            error = "Bad request",
            message = "The request is invalid or malformed",
            code = "BAD_REQUEST",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        call.respond(status, errorResponse)
    }
    
    private suspend fun handleInternalServerError(call: ApplicationCall, status: HttpStatusCode) {
        val errorResponse = ErrorResponse(
            error = "Internal server error",
            message = "An unexpected error occurred on the server",
            code = "INTERNAL_SERVER_ERROR",
            path = call.request.uri,
            method = call.request.httpMethod.value
        )
        
        call.respond(status, errorResponse)
    }
}
