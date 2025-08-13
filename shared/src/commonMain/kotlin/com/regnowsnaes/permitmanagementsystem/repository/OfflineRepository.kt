package com.regnowsnaes.permitmanagementsystem.repository

import com.regnowsnaes.permitmanagementsystem.database.DatabaseDriverFactory
import com.regnowsnaes.permitmanagementsystem.database.PermitDatabase
import com.regnowsnaes.permitmanagementsystem.models.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.datetime.Clock

class OfflineRepository(databaseDriverFactory: DatabaseDriverFactory) {
    private val database = PermitDatabase(databaseDriverFactory.createDriver())
    private val queries = database.permitDatabaseQueries
    
    // User operations
    suspend fun saveUser(user: User) = withContext(Dispatchers.Default) {
        val now = Clock.System.now().toString()
        queries.insertUser(
            id = user.id?.toLong() ?: 0L,
            email = user.email,
            firstName = user.firstName,
            lastName = user.lastName,
            role = user.role ?: "user",
            createdAt = user.createdAt ?: now,
            updatedAt = user.updatedAt ?: now,
            lastSyncedAt = now
        )
    }
    
    suspend fun getCurrentUser(): User? = withContext(Dispatchers.Default) {
        queries.getCurrentUser().executeAsOneOrNull()?.let { entity ->
            User(
                id = entity.id?.toInt() ?: 0,
                email = entity.email,
                firstName = entity.firstName,
                lastName = entity.lastName,
                role = entity.role,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt
            )
        }
    }
    
    suspend fun clearUser() = withContext(Dispatchers.Default) {
        queries.deleteAllUsers()
    }
    
    // County operations
    suspend fun saveCounties(counties: List<County>) = withContext(Dispatchers.Default) {
        val now = Clock.System.now().toString()
        counties.forEach { county ->
            queries.insertCounty(
                id = county.id.toLong(),
                name = county.name,
                state = county.state,
                createdAt = county.createdAt ?: now,
                updatedAt = county.updatedAt ?: now,
                lastSyncedAt = now
            )
        }
    }
    
    suspend fun getAllCounties(): List<County> = withContext(Dispatchers.Default) {
        queries.getAllCounties().executeAsList().map { entity ->
            County(
                id = entity.id.toInt(),
                name = entity.name,
                state = entity.state,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt
            )
        }
    }
    
    // Checklist item operations
    suspend fun saveChecklistItems(countyId: Int, items: List<ChecklistItem>) = withContext(Dispatchers.Default) {
        val now = Clock.System.now().toString()
        // Clear existing items for this county
        queries.deleteChecklistItemsByCounty(countyId.toLong())
        
        items.forEach { item ->
            queries.insertChecklistItem(
                id = item.id?.toLong() ?: 0L,
                countyId = countyId.toLong(),
                title = item.title,
                description = item.description ?: "",
                required = if (item.required) 1L else 0L,
                orderIndex = item.orderIndex?.toLong() ?: 0L,
                createdAt = item.createdAt ?: now,
                updatedAt = item.updatedAt ?: now,
                lastSyncedAt = now
            )
        }
    }
    
    suspend fun getChecklistItemsByCounty(countyId: Int): List<ChecklistItem> = withContext(Dispatchers.Default) {
        queries.getChecklistItemsByCounty(countyId.toLong()).executeAsList().map { entity ->
            ChecklistItem(
                id = entity.id?.toInt() ?: 0,
                countyId = entity.countyId.toInt(),
                title = entity.title,
                description = entity.description ?: "",
                required = entity.required == 1L,
                orderIndex = entity.orderIndex.toInt(),
                createdAt = entity.createdAt ?: "",
                updatedAt = entity.updatedAt ?: ""
            )
        }
    }
    
    // Permit package operations
    suspend fun savePermitPackages(packages: List<PermitPackage>) = withContext(Dispatchers.Default) {
        val now = Clock.System.now().toString()
        packages.forEach { pkg ->
            queries.insertPermitPackage(
                id = pkg.id.toLong(),
                userId = pkg.userId.toLong(),
                countyId = pkg.countyId.toLong(),
                name = pkg.name,
                description = pkg.description,
                status = pkg.status,
                createdAt = pkg.createdAt,
                updatedAt = pkg.updatedAt,
                lastSyncedAt = now,
                pendingSync = 0L
            )
        }
    }
    
    suspend fun getAllPermitPackages(): List<PermitPackage> = withContext(Dispatchers.Default) {
        queries.getAllPermitPackages().executeAsList().map { entity ->
            PermitPackage(
                id = entity.id.toInt(),
                userId = entity.userId.toInt(),
                countyId = entity.countyId.toInt(),
                name = entity.name,
                description = entity.description,
                status = entity.status,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt
            )
        }
    }
    
    suspend fun createPermitPackageOffline(
        userId: Int,
        countyId: Int,
        name: String,
        description: String?
    ): PermitPackage = withContext(Dispatchers.Default) {
        val now = Clock.System.now().toString()
        val tempId = System.currentTimeMillis().toInt() // Temporary ID for offline creation
        
        val package_ = PermitPackage(
            id = tempId,
            userId = userId,
            countyId = countyId,
            name = name,
            description = description,
            status = "draft",
            createdAt = now,
            updatedAt = now
        )
        
        queries.insertPermitPackage(
            id = tempId.toLong(),
            userId = userId.toLong(),
            countyId = countyId.toLong(),
            name = name,
            description = description,
            status = "draft",
            createdAt = now,
            updatedAt = now,
            lastSyncedAt = null,
            pendingSync = 1L
        )
        
        package_
    }
    
    suspend fun updatePackageStatusOffline(packageId: Int, status: String) = withContext(Dispatchers.Default) {
        val now = Clock.System.now().toString()
        queries.updatePackageStatus(status, now, packageId.toLong())
    }
    
    // Document operations - simplified for now
    suspend fun savePermitDocuments(packageId: Int, documents: List<PermitDocument>) = withContext(Dispatchers.Default) {
        // Simplified implementation - just store basic info
        // Full implementation would handle file storage
    }
    
    suspend fun getDocumentsByPackage(packageId: Int): List<PermitDocument> = withContext(Dispatchers.Default) {
        // Return empty list for now - will implement later
        emptyList()
    }
    
    // Utility operations
    suspend fun getLastSyncTime(): String? = withContext(Dispatchers.Default) {
        queries.getLastSyncTime().executeAsOneOrNull()?.toString()
    }
    
    suspend fun clearAllData() = withContext(Dispatchers.Default) {
        queries.deleteAllUsers()
        queries.deleteAllCounties()
        queries.deleteAllChecklistItems()
        queries.deleteAllPermitPackages()
        queries.deleteAllDocuments()
        queries.deleteAllSyncOperations()
    }
    
    suspend fun markPackageSynced(packageId: Int) = withContext(Dispatchers.Default) {
        val now = Clock.System.now().toString()
        queries.markPackageSynced(now, packageId.toLong())
    }
    
    suspend fun markDocumentSynced(documentId: Int) = withContext(Dispatchers.Default) {
        val now = Clock.System.now().toString()
        queries.markDocumentSynced(now, documentId.toLong())
    }
    
    // Simplified sync queue operations
    suspend fun getPendingSyncOperations() = withContext(Dispatchers.Default) {
        queries.getPendingSyncOperations().executeAsList()
    }
    
    suspend fun markSyncOperationCompleted(operationId: Long) = withContext(Dispatchers.Default) {
        queries.deleteSyncOperation(operationId)
    }
}
