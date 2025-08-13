package com.regnowsnaes.permitmanagementsystem.routes

import com.regnowsnaes.permitmanagementsystem.models.*
import com.regnowsnaes.permitmanagementsystem.services.AuthService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Route.authRoutes() {
    route("/auth") {
        post("/register") {
            try {
                val request = call.receive<RegisterRequest>()
                
                // Validate input
                if (request.email.isBlank() || request.password.isBlank() || 
                    request.firstName.isBlank() || request.lastName.isBlank()) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ApiResponse<Nothing>(
                            success = false,
                            error = "All fields are required"
                        )
                    )
                    return@post
                }
                
                if (request.password.length < 6) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ApiResponse<Nothing>(
                            success = false,
                            error = "Password must be at least 6 characters long"
                        )
                    )
                    return@post
                }
                
                val user = AuthService.register(
                    email = request.email,
                    password = request.password,
                    firstName = request.firstName,
                    lastName = request.lastName
                )
                
                val token = AuthService.generateToken(user)
                
                call.respond(
                    HttpStatusCode.Created,
                    ApiResponse(
                        success = true,
                        data = AuthResponse(token = token, user = user),
                        message = "User registered successfully"
                    )
                )
            } catch (e: IllegalArgumentException) {
                call.respond(
                    HttpStatusCode.BadRequest,
                    ApiResponse<Nothing>(
                        success = false,
                        error = e.message ?: "Registration failed"
                    )
                )
            } catch (e: Exception) {
                call.respond(
                    HttpStatusCode.InternalServerError,
                    ApiResponse<Nothing>(
                        success = false,
                        error = "Internal server error"
                    )
                )
            }
        }
        
        post("/login") {
            try {
                val request = call.receive<LoginRequest>()
                
                // Validate input
                if (request.email.isBlank() || request.password.isBlank()) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ApiResponse<Nothing>(
                            success = false,
                            error = "Email and password are required"
                        )
                    )
                    return@post
                }
                
                val user = AuthService.login(
                    email = request.email,
                    password = request.password
                )
                
                val token = AuthService.generateToken(user)
                
                call.respond(
                    HttpStatusCode.OK,
                    ApiResponse(
                        success = true,
                        data = AuthResponse(token = token, user = user),
                        message = "Login successful"
                    )
                )
            } catch (e: IllegalArgumentException) {
                call.respond(
                    HttpStatusCode.Unauthorized,
                    ApiResponse<Nothing>(
                        success = false,
                        error = e.message ?: "Invalid credentials"
                    )
                )
            } catch (e: Exception) {
                call.respond(
                    HttpStatusCode.InternalServerError,
                    ApiResponse<Nothing>(
                        success = false,
                        error = "Internal server error"
                    )
                )
            }
        }
    }
} 