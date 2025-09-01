package com.regnowsnaes.permitmanagementsystem.api

import kotlinx.serialization.Serializable

/**
 * API Version management for the Permit Management System
 * 
 * This class handles API versioning to ensure backward compatibility
 * and smooth transitions between API versions.
 */
object ApiVersion {
    const val CURRENT_VERSION = "v1"
    val SUPPORTED_VERSIONS = listOf("v1")
    
    /**
     * Check if a given version is supported
     */
    fun isSupported(version: String): Boolean {
        return SUPPORTED_VERSIONS.contains(version)
    }
    
    /**
     * Get the latest supported version
     */
    fun getLatestVersion(): String {
        return SUPPORTED_VERSIONS.maxOrNull() ?: CURRENT_VERSION
    }
    
    /**
     * Parse version from request header or URL
     */
    fun parseVersion(versionString: String?): String {
        return when {
            versionString.isNullOrBlank() -> CURRENT_VERSION
            isSupported(versionString) -> versionString
            else -> CURRENT_VERSION
        }
    }
}

/**
 * Versioned API response wrapper
 */
@Serializable
data class VersionedApiResponse<T>(
    val version: String,
    val success: Boolean,
    val data: T? = null,
    val message: String? = null,
    val error: String? = null,
    val timestamp: Long = System.currentTimeMillis()
)

/**
 * API version information
 */
@Serializable
data class ApiVersionInfo(
    val currentVersion: String,
    val supportedVersions: List<String>,
    val deprecatedVersions: List<String> = emptyList(),
    val migrationGuide: String? = null
)
