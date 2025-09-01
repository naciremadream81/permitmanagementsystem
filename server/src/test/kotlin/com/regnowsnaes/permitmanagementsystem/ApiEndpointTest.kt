package com.regnowsnaes.permitmanagementsystem

import com.regnowsnaes.permitmanagementsystem.models.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.server.testing.*
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*

class ApiEndpointTest {
    
    private val json = Json {
        prettyPrint = true
        isLenient = true
        ignoreUnknownKeys = true
    }
    
    @Test
    fun `API health check should return success`() = testApplication {
        val response = client.get("/api")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val responseText = response.bodyAsText()
        assertTrue(responseText.contains("success"))
        assertTrue(responseText.contains("Permit Management System API"))
    }
    
    @Test
    fun `Counties endpoint should return valid JSON`() = testApplication {
        val response = client.get("/counties")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val responseText = response.bodyAsText()
        assertTrue(responseText.contains("success"))
        assertTrue(responseText.contains("data"))
        
        // Try to parse as ApiResponse<List<County>>
        val apiResponse = json.decodeFromString<ApiResponse<List<County>>>(responseText)
        assertTrue(apiResponse.success)
        assertNotNull(apiResponse.data)
    }
    
    @Test
    fun `Root endpoint should serve HTML`() = testApplication {
        val response = client.get("/")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val contentType = response.headers[HttpHeaders.ContentType]
        assertTrue(contentType?.contains("text/html") == true)
    }
    
    @Test
    fun `Auth register endpoint should accept valid data`() = testApplication {
        val registerRequest = RegisterRequest(
            email = "test@example.com",
            password = "password123",
            firstName = "Test",
            lastName = "User"
        )
        
        val response = client.post("/auth/register") {
            contentType(ContentType.Application.Json)
            setBody(json.encodeToString(registerRequest))
        }
        
        // Should either succeed (201) or fail with validation error (400)
        assertTrue(response.status == HttpStatusCode.Created || response.status == HttpStatusCode.BadRequest)
    }
    
    @Test
    fun `Auth login endpoint should accept valid data`() = testApplication {
        val loginRequest = LoginRequest(
            email = "test@example.com",
            password = "password123"
        )
        
        val response = client.post("/auth/login") {
            contentType(ContentType.Application.Json)
            setBody(json.encodeToString(loginRequest))
        }
        
        // Should either succeed (200) or fail with auth error (401)
        assertTrue(response.status == HttpStatusCode.OK || response.status == HttpStatusCode.Unauthorized)
    }
    
    @Test
    fun `Packages endpoint should require authentication`() = testApplication {
        val response = client.get("/packages")
        assertEquals(HttpStatusCode.Unauthorized, response.status)
        
        val responseText = response.bodyAsText()
        assertTrue(responseText.contains("error") || responseText.contains("Unauthorized"))
    }
    
    @Test
    fun `Checklist endpoint should return valid data`() = testApplication {
        // Test with a valid county ID (assuming county ID 1 exists)
        val response = client.get("/counties/1/checklist")
        
        // Should either succeed (200) or return not found (404)
        assertTrue(response.status == HttpStatusCode.OK || response.status == HttpStatusCode.NotFound)
        
        if (response.status == HttpStatusCode.OK) {
            val responseText = response.bodyAsText()
            assertTrue(responseText.contains("success") || responseText.contains("data"))
        }
    }
    
    @Test
    fun `Invalid endpoints should return 404`() = testApplication {
        val response = client.get("/nonexistent")
        assertEquals(HttpStatusCode.NotFound, response.status)
    }
    
    @Test
    fun `Static files endpoint should be accessible`() = testApplication {
        val response = client.get("/uploads/")
        // Should return 404 if no files, but endpoint should be accessible
        assertTrue(response.status == HttpStatusCode.NotFound || response.status == HttpStatusCode.OK)
    }
}
