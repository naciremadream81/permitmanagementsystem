package com.regnowsnaes.permitmanagementsystem

import com.regnowsnaes.permitmanagementsystem.models.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*

class SerializationTest {
    
    private val json = Json {
        prettyPrint = true
        isLenient = true
        ignoreUnknownKeys = true
    }
    
    @Test
    fun `ApiResponse serialization should work correctly`() {
        // Test successful response
        val successResponse = ApiResponse(
            success = true,
            data = "test data",
            message = "Operation successful"
        )
        
        val serialized = json.encodeToString(successResponse)
        assertTrue(serialized.contains("success"))
        assertTrue(serialized.contains("test data"))
        assertTrue(serialized.contains("Operation successful"))
        
        // Test error response
        val errorResponse = ApiResponse<Nothing>(
            success = false,
            error = "Something went wrong"
        )
        
        val errorSerialized = json.encodeToString(errorResponse)
        assertTrue(errorSerialized.contains("success"))
        assertTrue(errorSerialized.contains("Something went wrong"))
    }
    
    @Test
    fun `County serialization should work correctly`() {
        val county = County(
            id = 1,
            name = "Alachua County",
            state = "FL",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z"
        )
        
        val serialized = json.encodeToString(county)
        assertTrue(serialized.contains("Alachua County"))
        assertTrue(serialized.contains("FL"))
        assertTrue(serialized.contains("1"))
    }
    
    @Test
    fun `User serialization should work correctly`() {
        val user = User(
            id = 1,
            email = "test@example.com",
            firstName = "John",
            lastName = "Doe",
            role = "user",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z"
        )
        
        val serialized = json.encodeToString(user)
        assertTrue(serialized.contains("test@example.com"))
        assertTrue(serialized.contains("John"))
        assertTrue(serialized.contains("Doe"))
        assertTrue(serialized.contains("user"))
    }
    
    @Test
    fun `PermitPackage serialization should work correctly`() {
        val permitPackage = PermitPackage(
            id = 1,
            userId = 1,
            countyId = 1,
            name = "Test Permit",
            description = "Test Description",
            status = "draft",
            customerName = "John Doe",
            customerEmail = "john@example.com",
            customerPhone = "555-1234",
            customerCompany = "Test Company",
            customerLicense = "LIC123",
            siteAddress = "123 Main St",
            siteCity = "Gainesville",
            siteState = "FL",
            siteZip = "32601",
            siteCounty = "Alachua",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z"
        )
        
        val serialized = json.encodeToString(permitPackage)
        assertTrue(serialized.contains("Test Permit"))
        assertTrue(serialized.contains("John Doe"))
        assertTrue(serialized.contains("john@example.com"))
        assertTrue(serialized.contains("draft"))
    }
    
    @Test
    fun `AuthResponse serialization should work correctly`() {
        val user = User(
            id = 1,
            email = "test@example.com",
            firstName = "John",
            lastName = "Doe",
            role = "user",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z"
        )
        
        val authResponse = AuthResponse(
            token = "jwt-token-here",
            user = user
        )
        
        val serialized = json.encodeToString(authResponse)
        assertTrue(serialized.contains("jwt-token-here"))
        assertTrue(serialized.contains("test@example.com"))
    }
    
    @Test
    fun `Request DTOs serialization should work correctly`() {
        val loginRequest = LoginRequest(
            email = "test@example.com",
            password = "password123"
        )
        
        val registerRequest = RegisterRequest(
            email = "newuser@example.com",
            password = "password123",
            firstName = "Jane",
            lastName = "Smith"
        )
        
        val createPackageRequest = CreatePackageRequest(
            countyId = 1,
            name = "New Permit",
            description = "New permit description",
            customerName = "Jane Smith",
            customerEmail = "jane@example.com",
            customerPhone = "555-5678",
            customerCompany = "Smith Corp",
            customerLicense = "LIC456",
            siteAddress = "456 Oak St",
            siteCity = "Orlando",
            siteState = "FL",
            siteZip = "32801",
            siteCounty = "Orange"
        )
        
        // Test serialization
        val loginSerialized = json.encodeToString(loginRequest)
        val registerSerialized = json.encodeToString(registerRequest)
        val packageSerialized = json.encodeToString(createPackageRequest)
        
        assertTrue(loginSerialized.contains("test@example.com"))
        assertTrue(registerSerialized.contains("Jane"))
        assertTrue(packageSerialized.contains("New Permit"))
    }
    
    @Test
    fun `Complex nested objects serialization should work correctly`() {
        val county = County(
            id = 1,
            name = "Alachua County",
            state = "FL",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z"
        )
        
        val permitPackage = PermitPackage(
            id = 1,
            userId = 1,
            countyId = 1,
            name = "Test Permit",
            description = "Test Description",
            status = "draft",
            createdAt = "2025-01-01T00:00:00Z",
            updatedAt = "2025-01-01T00:00:00Z",
            county = county
        )
        
        val response = ApiResponse(
            success = true,
            data = permitPackage,
            message = "Permit package retrieved successfully"
        )
        
        val serialized = json.encodeToString(response)
        assertTrue(serialized.contains("Test Permit"))
        assertTrue(serialized.contains("Alachua County"))
        assertTrue(serialized.contains("success"))
    }
}
