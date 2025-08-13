package com.regnowsnaes.permitmanagementsystem.models

import kotlinx.serialization.Serializable
import kotlinx.datetime.Instant

@Serializable
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val message: String? = null,
    val error: String? = null
)

@Serializable
data class County(
    val id: Int,
    val name: String,
    val state: String,
    val createdAt: String? = null,
    val updatedAt: String? = null
)

@Serializable
data class ChecklistItem(
    val id: Int,
    val countyId: Int,
    val title: String,
    val description: String,
    val required: Boolean,
    val orderIndex: Int,
    val createdAt: String,
    val updatedAt: String
)

@Serializable
data class User(
    val id: Int,
    val email: String,
    val firstName: String,
    val lastName: String,
    val role: String = "user",
    val createdAt: String,
    val updatedAt: String
)

@Serializable
data class PermitPackage(
    val id: Int,
    val userId: Int,
    val countyId: Int,
    val name: String,
    val description: String? = null,
    val status: String = "draft",
    
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
    
    val createdAt: String,
    val updatedAt: String,
    val county: County? = null
)

@Serializable
data class PermitDocument(
    val id: Int,
    val packageId: Int,
    val checklistItemId: Int,
    val fileName: String,
    val filePath: String,
    val fileSize: Long,
    val mimeType: String,
    val uploadedAt: String,
    val checklistItem: ChecklistItem? = null
)

// Request/Response DTOs
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
data class CreatePackageRequest(
    val countyId: Int,
    val name: String,
    val description: String? = null,
    
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
    val siteCounty: String? = null
)

@Serializable
data class UpdatePackageStatusRequest(
    val status: String
)

@Serializable
data class CountyWithChecklist(
    val county: County,
    val checklistItems: List<ChecklistItem>
)

@Serializable
data class PackageWithDetails(
    val permitPackage: PermitPackage,
    val documents: List<PermitDocument>,
    val checklistItems: List<ChecklistItem>
)

// Admin request models
@Serializable
data class UpdateUserRoleRequest(
    val role: String
)

@Serializable
data class CreateChecklistItemRequest(
    val title: String,
    val description: String,
    val required: Boolean,
    val orderIndex: Int
)

@Serializable
data class UpdateChecklistItemRequest(
    val title: String,
    val description: String,
    val required: Boolean,
    val orderIndex: Int
)
