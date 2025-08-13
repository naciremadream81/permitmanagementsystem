package com.regnowsnaes.permitmanagementsystem.models

import com.regnowsnaes.permitmanagementsystem.serializers.LocalDateTimeSerializer
import kotlinx.serialization.Serializable
import java.time.LocalDateTime

@Serializable
data class User(
    val id: Int? = null,
    val email: String,
    val password: String? = null, // Only for registration/login
    val firstName: String,
    val lastName: String,
    val role: String = "user", // user, admin, county_admin
    @Serializable(with = LocalDateTimeSerializer::class)
    val createdAt: LocalDateTime? = null,
    @Serializable(with = LocalDateTimeSerializer::class)
    val updatedAt: LocalDateTime? = null
)

@Serializable
data class CountyDTO(
    val id: Int,
    val name: String,
    val state: String
)

@Serializable
data class County(
    val id: Int? = null,
    val name: String,
    val state: String,
    @Serializable(with = LocalDateTimeSerializer::class)
    val createdAt: LocalDateTime? = null,
    @Serializable(with = LocalDateTimeSerializer::class)
    val updatedAt: LocalDateTime? = null
)

@Serializable
data class ChecklistItem(
    val id: Int? = null,
    val countyId: Int,
    val title: String,
    val description: String,
    val required: Boolean,
    val orderIndex: Int,
    @Serializable(with = LocalDateTimeSerializer::class)
    val createdAt: LocalDateTime? = null,
    @Serializable(with = LocalDateTimeSerializer::class)
    val updatedAt: LocalDateTime? = null
)

@Serializable
data class PermitPackage(
    val id: Int? = null,
    val userId: Int,
    val countyId: Int,
    val name: String,
    val description: String?,
    val status: String = "draft", // draft, in_progress, completed, submitted
    
    // Customer Information
    val customerName: String? = null,
    val customerEmail: String? = null,
    val customerPhone: String? = null,
    val customerCompany: String? = null,
    val customerLicense: String? = null,
    
    // Site Information
    val siteAddress: String? = null,
    val siteCity: String? = null,
    val siteState: String? = null,
    val siteZip: String? = null,
    val siteCounty: String? = null,
    
    @Serializable(with = LocalDateTimeSerializer::class)
    val createdAt: LocalDateTime? = null,
    @Serializable(with = LocalDateTimeSerializer::class)
    val updatedAt: LocalDateTime? = null
)

@Serializable
data class PermitDocument(
    val id: Int? = null,
    val packageId: Int,
    val checklistItemId: Int,
    val fileName: String,
    val fileUrl: String,
    val fileSize: Int,
    val mimeType: String,
    val documentType: String = "general", // drawing, form, photo, inspection, etc.
    val version: String = "1.0",
    val isApproved: Boolean = false,
    @Serializable(with = LocalDateTimeSerializer::class)
    val approvalDate: LocalDateTime? = null,
    val approvedBy: Int? = null,
    val rejectionReason: String? = null,
    @Serializable(with = LocalDateTimeSerializer::class)
    val uploadedAt: LocalDateTime? = null
)

// Request/Response DTOs
@Serializable
data class CreatePackageRequest(
    val countyId: Int,
    val name: String,
    val description: String? = null,
    val customerName: String? = null,
    val customerEmail: String? = null,
    val customerPhone: String? = null,
    val customerCompany: String? = null,
    val customerLicense: String? = null,
    val siteAddress: String? = null,
    val siteCity: String? = null,
    val siteState: String? = null,
    val siteZip: String? = null,
    val siteCounty: String? = null
)

@Serializable
data class UpdatePackageRequest(
    val name: String? = null,
    val description: String? = null,
    val status: String? = null,
    val customerName: String? = null,
    val customerEmail: String? = null,
    val customerPhone: String? = null,
    val customerCompany: String? = null,
    val customerLicense: String? = null,
    val siteAddress: String? = null,
    val siteCity: String? = null,
    val siteState: String? = null,
    val siteZip: String? = null,
    val siteCounty: String? = null
)

@Serializable
data class LoginRequest(
    val email: String,
    val password: String
)

@Serializable
data class RegisterRequest(
    val email: String,
    val password: String,
    val firstName: String,
    val lastName: String
)

@Serializable
data class AuthResponse(
    val token: String,
    val user: User
)

@Serializable
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val message: String? = null,
    val error: String? = null
) 