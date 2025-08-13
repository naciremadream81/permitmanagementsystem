package com.regnowsnaes.permitmanagementsystem.api

import com.regnowsnaes.permitmanagementsystem.models.*
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.auth.*
import io.ktor.client.plugins.auth.providers.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.request.*
import io.ktor.client.request.forms.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.json.Json

class ApiService {
    private val baseUrl = "http://localhost:8080"
    
    private val _authToken = MutableStateFlow<String?>(null)
    val authToken: StateFlow<String?> = _authToken
    
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser
    
    private val httpClient = HttpClient {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                isLenient = true
            })
        }
        
        install(Logging) {
            level = LogLevel.INFO
        }
        
        install(Auth) {
            bearer {
                loadTokens {
                    _authToken.value?.let { token ->
                        BearerTokens(token, token)
                    }
                }
            }
        }
        
        install(DefaultRequest) {
            contentType(ContentType.Application.Json)
        }
    }
    
    // Authentication
    suspend fun login(email: String, password: String): Result<AuthResponse> {
        return try {
            val response: HttpResponse = httpClient.post("$baseUrl/auth/login") {
                setBody(LoginRequest(email, password))
            }
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<AuthResponse> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    _authToken.value = apiResponse.data.token
                    _currentUser.value = apiResponse.data.user
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Login failed"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Login failed: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun register(email: String, password: String, firstName: String, lastName: String): Result<AuthResponse> {
        return try {
            val response: HttpResponse = httpClient.post("$baseUrl/auth/register") {
                setBody(RegisterRequest(email, password, firstName, lastName))
            }
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<AuthResponse> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    _authToken.value = apiResponse.data.token
                    _currentUser.value = apiResponse.data.user
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Registration failed"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Registration failed: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    fun logout() {
        _authToken.value = null
        _currentUser.value = null
    }
    
    // Counties
    suspend fun getCounties(): Result<List<County>> {
        return try {
            val response: HttpResponse = httpClient.get("$baseUrl/counties")
            
            if (response.status.isSuccess()) {
                val counties: List<County> = response.body()
                Result.success(counties)
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to get counties: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun getCountyChecklist(countyId: Int): Result<List<ChecklistItem>> {
        return try {
            val response: HttpResponse = httpClient.get("$baseUrl/counties/$countyId/checklist")
            
            if (response.status.isSuccess()) {
                val checklist: List<ChecklistItem> = response.body()
                Result.success(checklist)
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to get county checklist: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    // Permit Packages
    suspend fun getPackages(): Result<List<PermitPackage>> {
        return try {
            val response: HttpResponse = httpClient.get("$baseUrl/packages")
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<List<PermitPackage>> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Failed to get packages"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to get packages: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun createPackage(
        countyId: Int, 
        name: String, 
        description: String?,
        customerName: String? = null,
        customerEmail: String? = null,
        customerPhone: String? = null,
        customerCompany: String? = null,
        customerLicense: String? = null,
        siteAddress: String? = null,
        siteCity: String? = null,
        siteState: String? = null,
        siteZip: String? = null,
        siteCounty: String? = null
    ): Result<PermitPackage> {
        return try {
            val response: HttpResponse = httpClient.post("$baseUrl/packages") {
                setBody(CreatePackageRequest(
                    countyId = countyId,
                    name = name,
                    description = description,
                    customerName = customerName,
                    customerEmail = customerEmail,
                    customerPhone = customerPhone,
                    customerCompany = customerCompany,
                    customerLicense = customerLicense,
                    siteAddress = siteAddress,
                    siteCity = siteCity,
                    siteState = siteState,
                    siteZip = siteZip,
                    siteCounty = siteCounty
                ))
            }
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<PermitPackage> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Failed to create package"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to create package: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun getPackageDetails(packageId: Int): Result<PackageWithDetails> {
        return try {
            val response: HttpResponse = httpClient.get("$baseUrl/packages/$packageId")
            
            if (response.status.isSuccess()) {
                val packageDetails: PackageWithDetails = response.body()
                Result.success(packageDetails)
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to get package details: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun updatePackageStatus(packageId: Int, status: String): Result<PermitPackage> {
        return try {
            val response: HttpResponse = httpClient.put("$baseUrl/packages/$packageId/status") {
                setBody(UpdatePackageStatusRequest(status))
            }
            
            if (response.status.isSuccess()) {
                val permitPackage: PermitPackage = response.body()
                Result.success(permitPackage)
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to update package status: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    // Documents
    suspend fun getPackageDocuments(packageId: Int): Result<List<PermitDocument>> {
        return try {
            val response: HttpResponse = httpClient.get("$baseUrl/packages/$packageId/documents")
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<List<PermitDocument>> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Failed to get package documents"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to get package documents: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun deleteDocument(packageId: Int, documentId: Int): Result<Unit> {
        return try {
            val response: HttpResponse = httpClient.delete("$baseUrl/packages/$packageId/documents/$documentId")
            
            if (response.status.isSuccess()) {
                Result.success(Unit)
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to delete document: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    fun close() {
        httpClient.close()
    }
    
    // Admin functions
    suspend fun getAllUsers(): Result<List<User>> {
        return try {
            val response: HttpResponse = httpClient.get("$baseUrl/admin/users")
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<List<User>> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Failed to get users"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to get users: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun updateUserRole(userId: Int, role: String): Result<User> {
        return try {
            val response: HttpResponse = httpClient.put("$baseUrl/admin/users/$userId/role") {
                setBody(UpdateUserRoleRequest(role))
            }
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<User> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Failed to update user role"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to update user role: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun deleteUser(userId: Int): Result<Unit> {
        return try {
            val response: HttpResponse = httpClient.delete("$baseUrl/admin/users/$userId")
            
            if (response.status.isSuccess()) {
                Result.success(Unit)
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to delete user: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun createChecklistItem(countyId: Int, title: String, description: String, required: Boolean, orderIndex: Int): Result<ChecklistItem> {
        return try {
            val response: HttpResponse = httpClient.post("$baseUrl/admin/counties/$countyId/checklist") {
                setBody(CreateChecklistItemRequest(title, description, required, orderIndex))
            }
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<ChecklistItem> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Failed to create checklist item"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to create checklist item: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun updateChecklistItem(countyId: Int, itemId: Int, title: String, description: String, required: Boolean, orderIndex: Int): Result<ChecklistItem> {
        return try {
            val response: HttpResponse = httpClient.put("$baseUrl/admin/counties/$countyId/checklist/$itemId") {
                setBody(UpdateChecklistItemRequest(title, description, required, orderIndex))
            }
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<ChecklistItem> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Failed to update checklist item"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to update checklist item: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun deleteChecklistItem(countyId: Int, itemId: Int): Result<Unit> {
        return try {
            val response: HttpResponse = httpClient.delete("$baseUrl/admin/counties/$countyId/checklist/$itemId")
            
            if (response.status.isSuccess()) {
                Result.success(Unit)
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to delete checklist item: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun uploadDocument(packageId: Int, checklistItemId: Int, fileName: String, fileBytes: ByteArray, mimeType: String): Result<PermitDocument> {
        return try {
            val response: HttpResponse = httpClient.post("$baseUrl/packages/$packageId/documents") {
                setBody(MultiPartFormDataContent(
                    formData {
                        append("checklistItemId", checklistItemId.toString())
                        append("file", fileBytes, Headers.build {
                            append(HttpHeaders.ContentType, mimeType)
                            append(HttpHeaders.ContentDisposition, "filename=\"$fileName\"")
                        })
                    }
                ))
            }
            
            if (response.status.isSuccess()) {
                val apiResponse: ApiResponse<PermitDocument> = response.body()
                if (apiResponse.success && apiResponse.data != null) {
                    Result.success(apiResponse.data)
                } else {
                    Result.failure(Exception(apiResponse.error ?: "Failed to upload document"))
                }
            } else {
                val errorBody = response.bodyAsText()
                Result.failure(Exception("Failed to upload document: $errorBody"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    companion object {
        @Volatile
        private var INSTANCE: ApiService? = null
        
        fun getInstance(): ApiService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: ApiService().also { INSTANCE = it }
            }
        }
    }
}
