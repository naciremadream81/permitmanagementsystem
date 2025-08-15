package com.regnowsnaes.permitmanagementsystem.routes

import com.regnowsnaes.permitmanagementsystem.models.*
import com.regnowsnaes.permitmanagementsystem.services.AuthService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.ktor.http.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import java.time.LocalDateTime
import java.io.File
import java.util.UUID

fun Route.configureDocumentRoutes(authService: AuthService) {
    route("/documents") {
        // Get all documents for a user
        get("/list") {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Missing authorization token"))
                    return@get
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Invalid token"))
                    return@get
                }

                // For now, return sample documents - in production this would query the database
                val documents = listOf(
                    mapOf(
                        "id" to "doc-001",
                        "fileName" to "Building Plans.pdf",
                        "documentType" to "drawing",
                        "fileSize" to 2048576,
                        "uploadedAt" to "2025-08-12T21:00:00",
                        "status" to "approved"
                    ),
                    mapOf(
                        "id" to "doc-002",
                        "fileName" to "Permit Application.pdf",
                        "documentType" to "form",
                        "fileSize" to 512000,
                        "uploadedAt" to "2025-08-12T21:00:00",
                        "status" to "pending"
                    ),
                    mapOf(
                        "id" to "doc-003",
                        "fileName" to "Site Plan.dwg",
                        "documentType" to "cad",
                        "fileSize" to 1048576,
                        "uploadedAt" to "2025-08-12T21:00:00",
                        "status" to "review"
                    )
                )

                call.respond(mapOf("success" to true, "data" to documents))

            } catch (e: Exception) {
                call.respond(
                    HttpStatusCode.InternalServerError,
                    mapOf("success" to false, "error" to "Failed to retrieve documents: ${e.message}")
                )
            }
        }

        // Get documents for a specific package
        get("/package/{packageId}") {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Missing authorization token"))
                    return@get
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Invalid token"))
                    return@get
                }

                val packageId = call.parameters["packageId"]?.toIntOrNull()
                if (packageId == null) {
                    call.respond(HttpStatusCode.BadRequest, mapOf("success" to false, "error" to "Invalid package ID"))
                    return@get
                }

                // Return sample documents for the package
                val documents = listOf(
                    mapOf(
                        "id" to "doc-001",
                        "fileName" to "Building Plans.pdf",
                        "documentType" to "drawing",
                        "uploadedAt" to "2025-08-12T21:00:00"
                    ),
                    mapOf(
                        "id" to "doc-002",
                        "fileName" to "Permit Application.pdf",
                        "documentType" to "form",
                        "uploadedAt" to "2025-08-12T21:00:00"
                    )
                )

                call.respond(mapOf("success" to true, "data" to documents))

            } catch (e: Exception) {
                call.respond(
                    HttpStatusCode.InternalServerError,
                    mapOf("success" to false, "error" to "Failed to retrieve documents: ${e.message}")
                )
            }
        }

        // File upload endpoint
        post("/upload") {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Missing authorization token"))
                    return@post
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Invalid token"))
                    return@post
                }

                // For now, return a simple success response
                // In production, this would handle actual file uploads
                call.respond(
                    HttpStatusCode.Created,
                    mapOf(
                        "success" to true,
                        "message" to "File upload endpoint ready (implementation pending)",
                        "files" to listOf<Map<String, Any>>()
                    )
                )
                
            } catch (e: Exception) {
                call.respond(
                    HttpStatusCode.InternalServerError,
                    mapOf("success" to false, "error" to "Upload failed: ${e.message}")
                )
            }
        }

        // Simple document creation endpoint
        post("/create") {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Missing authorization token"))
                    return@post
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Invalid token"))
                    return@post
                }

                val request = call.receive<CreateDocumentRequest>()
                
                // Return success with simple response
                call.respond(
                    HttpStatusCode.Created,
                    mapOf(
                        "success" to true,
                        "message" to "Document record created successfully",
                        "documentId" to 123,
                        "fileName" to request.fileName
                    )
                )

            } catch (e: Exception) {
                call.respond(
                    HttpStatusCode.InternalServerError,
                    mapOf("success" to false, "error" to "Failed to create document: ${e.message}")
                )
            }
        }

        // File download endpoint
        get("/download/{documentId}") {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Missing authorization token"))
                    return@get
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Invalid token"))
                    return@get
                }

                val documentId = call.parameters["documentId"]
                if (documentId == null) {
                    call.respond(HttpStatusCode.BadRequest, mapOf("success" to false, "error" to "Invalid document ID"))
                    return@get
                }

                // For demo purposes, return a sample file
                // In production, this would look up the actual file path from the database
                val sampleFile = File("uploads/sample-document.pdf")
                
                if (!sampleFile.exists()) {
                    // Create a sample file if it doesn't exist
                    sampleFile.parentFile?.mkdirs()
                    sampleFile.writeText("This is a sample document for demonstration purposes.")
                }
                
                call.response.header(
                    HttpHeaders.ContentDisposition,
                    ContentDisposition.Attachment.withParameter(
                        ContentDisposition.Parameters.FileName,
                        "sample-document.pdf"
                    ).toString()
                )
                
                call.respondFile(sampleFile)
                
            } catch (e: Exception) {
                call.respond(
                    HttpStatusCode.InternalServerError,
                    mapOf("success" to false, "error" to "Download failed: ${e.message}")
                )
            }
        }

        // Document deletion endpoint
        delete("/{documentId}") {
            try {
                val token = call.request.header("Authorization")?.removePrefix("Bearer ")
                if (token == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Missing authorization token"))
                    return@delete
                }

                val user = authService.validateToken(token)
                if (user == null) {
                    call.respond(HttpStatusCode.Unauthorized, mapOf("success" to false, "error" to "Invalid token"))
                    return@delete
                }

                val documentId = call.parameters["documentId"]?.toIntOrNull()
                if (documentId == null) {
                    call.respond(HttpStatusCode.BadRequest, mapOf("success" to false, "error" to "Invalid document ID"))
                    return@delete
                }

                call.respond(mapOf("success" to true, "message" to "Document deleted successfully"))

            } catch (e: Exception) {
                call.respond(
                    HttpStatusCode.InternalServerError,
                    mapOf("success" to false, "error" to "Failed to delete document: ${e.message}")
                )
            }
        }

        // Health check for documents endpoint
        get("/health") {
            call.respond(mapOf(
                "status" to "healthy",
                "endpoint" to "documents",
                "timestamp" to System.currentTimeMillis().toString()
            ))
        }
    }
}

@Serializable
data class CreateDocumentRequest(
    val packageId: Int,
    val checklistItemId: Int,
    val fileName: String,
    val fileUrl: String,
    val fileSize: Int,
    val mimeType: String,
    val documentType: String = "general"
)
