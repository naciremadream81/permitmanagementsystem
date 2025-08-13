package com.regnowsnaes.permitmanagementsystem.routes

import com.regnowsnaes.permitmanagementsystem.models.*
import com.regnowsnaes.permitmanagementsystem.services.PermitService
import com.regnowsnaes.permitmanagementsystem.services.AuthService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.jetbrains.exposed.sql.transactions.transaction

fun Route.configurePermitRoutes(authService: AuthService) {
    route("/packages") {
        // Get all permit packages for the authenticated user
        get {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Missing authorization token"))
                    return@get
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Invalid token"))
                    return@get
                }
                
                val packages = PermitService.getPermitPackagesByUserId(user.id!!)
                call.respond(ApiResponse(success = true, data = packages))
            } catch (e: Exception) {
                call.respond(HttpStatusCode.InternalServerError, ApiResponse<Nothing>(success = false, error = "Failed to retrieve permit packages: ${e.message}"))
            }
        }

        // Create a new permit package
        post {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Missing authorization token"))
                    return@post
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Invalid token"))
                    return@post
                }

                val request = call.receive<CreatePackageRequest>()
                val permitPackage = PermitService.createPermitPackage(
                    userId = user.id!!,
                    countyId = request.countyId,
                    name = request.name,
                    description = request.description,
                    customerName = request.customerName,
                    customerEmail = request.customerEmail,
                    customerPhone = request.customerPhone,
                    customerCompany = request.customerCompany,
                    customerLicense = request.customerLicense,
                    siteAddress = request.siteAddress,
                    siteCity = request.siteCity,
                    siteState = request.siteState,
                    siteZip = request.siteZip,
                    siteCounty = request.siteCounty
                )
                
                call.respond(HttpStatusCode.Created, ApiResponse(success = true, data = permitPackage))
            } catch (e: Exception) {
                call.respond(HttpStatusCode.InternalServerError, ApiResponse<Nothing>(success = false, error = "Failed to create permit package: ${e.message}"))
            }
        }

        // Get a specific permit package by ID
        get("{id}") {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Missing authorization token"))
                    return@get
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Invalid token"))
                    return@get
                }

                val packageId = call.parameters["id"]?.toIntOrNull()
                if (packageId == null) {
                    call.respond(HttpStatusCode.BadRequest, ApiResponse<Nothing>(success = false, error = "Invalid package ID"))
                    return@get
                }
                
                val permitPackage = PermitService.getPermitPackageById(packageId, user.id!!)
                if (permitPackage == null) {
                    call.respond(HttpStatusCode.NotFound, ApiResponse<Nothing>(success = false, error = "Permit package not found"))
                    return@get
                }
                
                call.respond(ApiResponse(success = true, data = permitPackage))
            } catch (e: Exception) {
                call.respond(HttpStatusCode.InternalServerError, ApiResponse<Nothing>(success = false, error = "Failed to retrieve permit package: ${e.message}"))
            }
        }

        // Update a permit package status
        put("{id}/status") {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Missing authorization token"))
                    return@put
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Invalid token"))
                    return@put
                }
                
                val packageId = call.parameters["id"]?.toIntOrNull()
                if (packageId == null) {
                    call.respond(HttpStatusCode.BadRequest, ApiResponse<Nothing>(success = false, error = "Invalid package ID"))
                    return@put
                }

                val request = call.receive<UpdatePackageRequest>()
                val status = request.status ?: "draft"
                
                val updatedPackage = PermitService.updatePermitPackageStatus(packageId, user.id!!, status)
                if (updatedPackage == null) {
                    call.respond(HttpStatusCode.NotFound, ApiResponse<Nothing>(success = false, error = "Permit package not found"))
                    return@put
                }
                
                call.respond(ApiResponse(success = true, data = updatedPackage, message = "Permit package status updated successfully"))
            } catch (e: Exception) {
                call.respond(HttpStatusCode.InternalServerError, ApiResponse<Nothing>(success = false, error = "Failed to update permit package: ${e.message}"))
            }
        }

        // Delete a permit package
        delete("{id}") {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Missing authorization token"))
                    return@delete
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, ApiResponse<Nothing>(success = false, error = "Invalid token"))
                    return@delete
                }

                    val packageId = call.parameters["id"]?.toIntOrNull()
                    if (packageId == null) {
                    call.respond(HttpStatusCode.BadRequest, ApiResponse<Nothing>(success = false, error = "Invalid package ID"))
                    return@delete
                }

                val success = PermitService.deletePermitPackage(packageId, user.id!!)
                
                if (success) {
                    call.respond(ApiResponse<Nothing>(success = true, message = "Permit package deleted successfully"))
                } else {
                    call.respond(HttpStatusCode.NotFound, ApiResponse<Nothing>(success = false, error = "Permit package not found"))
                }
            } catch (e: Exception) {
                call.respond(HttpStatusCode.InternalServerError, ApiResponse<Nothing>(success = false, error = "Failed to delete permit package: ${e.message}"))
            }
        }
    }

    route("/counties") {
        // Get all counties
        get {
            try {
                val counties = PermitService.getAllCounties()
                call.respond(ApiResponse(success = true, data = counties))
                } catch (e: Exception) {
                call.respond(HttpStatusCode.InternalServerError, ApiResponse<Nothing>(success = false, error = "Failed to retrieve counties: ${e.message}"))
            }
        }
    }

    route("/checklists") {
        // Get checklist items for a specific county
        get("{countyId}") {
            try {
                val countyId = call.parameters["countyId"]?.toIntOrNull()
                if (countyId == null) {
                    call.respond(HttpStatusCode.BadRequest, ApiResponse<Nothing>(success = false, error = "Invalid county ID"))
                    return@get
                }

                val checklistItems = PermitService.getChecklistByCountyId(countyId)
                call.respond(ApiResponse(success = true, data = checklistItems))
                } catch (e: Exception) {
                call.respond(HttpStatusCode.InternalServerError, ApiResponse<Nothing>(success = false, error = "Failed to retrieve checklist items: ${e.message}"))
            }
        }
    }
}
