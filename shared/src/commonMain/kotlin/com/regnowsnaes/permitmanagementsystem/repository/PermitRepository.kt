package com.regnowsnaes.permitmanagementsystem.repository

import com.regnowsnaes.permitmanagementsystem.api.ApiService
import com.regnowsnaes.permitmanagementsystem.database.DatabaseDriverFactory
import com.regnowsnaes.permitmanagementsystem.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class PermitRepository(databaseDriverFactory: DatabaseDriverFactory) {
    private val _apiService = ApiService.getInstance()
    val apiService = _apiService // Expose for admin functions
    
    // Offline repository for local storage
    private val offlineRepository = OfflineRepository(databaseDriverFactory)
    
    // Sync manager for online/offline synchronization
    private val syncManager = SyncManager(_apiService, offlineRepository)
    
    // State flows for reactive UI
    private val _counties = MutableStateFlow<List<County>>(emptyList())
    val counties: StateFlow<List<County>> = _counties.asStateFlow()
    
    private val _packages = MutableStateFlow<List<PermitPackage>>(emptyList())
    val packages: StateFlow<List<PermitPackage>> = _packages.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()
    
    private val _isOnline = MutableStateFlow(true)
    val isOnline: StateFlow<Boolean> = _isOnline.asStateFlow()
    
    // Authentication
    val authToken = _apiService.authToken
    val currentUser = _apiService.currentUser
    
    // Sync status
    val syncStatus = syncManager.syncStatus
    val lastSyncTime = syncManager.lastSyncTime
    
    init {
        // Start background sync
        syncManager.startBackgroundSync()
    }
    
    suspend fun login(email: String, password: String): Boolean {
        _isLoading.value = true
        _error.value = null
        
        return try {
            // Try online login first
            val result = _apiService.login(email, password)
            if (result.isSuccess) {
                _isOnline.value = true
                
                // Save user to offline storage
                _apiService.currentUser.value?.let { user ->
                    offlineRepository.saveUser(user)
                }
                
                // Load data (will try online first, fallback to offline)
                loadCounties()
                loadPackages()
                
                // Perform initial sync
                syncManager.performFullSync()
                
                true
            } else {
                // Try offline login (check if user exists locally)
                val offlineUser = offlineRepository.getCurrentUser()
                if (offlineUser != null && offlineUser.email == email) {
                    _isOnline.value = false
                    _error.value = "Working offline - limited functionality available"
                    
                    // Load offline data
                    loadOfflineData()
                    true
                } else {
                    _error.value = result.exceptionOrNull()?.message ?: "Login failed"
                    false
                }
            }
        } catch (e: Exception) {
            // Network error - try offline
            val offlineUser = offlineRepository.getCurrentUser()
            if (offlineUser != null && offlineUser.email == email) {
                _isOnline.value = false
                _error.value = "Working offline - no internet connection"
                loadOfflineData()
                true
            } else {
                _error.value = e.message ?: "Login failed"
                false
            }
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun register(email: String, password: String, firstName: String, lastName: String): Boolean {
        _isLoading.value = true
        _error.value = null
        
        return try {
            val result = _apiService.register(email, password, firstName, lastName)
            if (result.isSuccess) {
                _isOnline.value = true
                
                // Save user to offline storage
                _apiService.currentUser.value?.let { user ->
                    offlineRepository.saveUser(user)
                }
                
                // Load user data after successful registration
                loadCounties()
                loadPackages()
                
                // Perform initial sync
                syncManager.performFullSync()
                
                true
            } else {
                _error.value = result.exceptionOrNull()?.message ?: "Registration failed"
                false
            }
        } catch (e: Exception) {
            _error.value = e.message ?: "Registration failed - no internet connection"
            false
        } finally {
            _isLoading.value = false
        }
    }
    
    fun logout() {
        _apiService.logout()
        syncManager.stopBackgroundSync()
        
        _counties.value = emptyList()
        _packages.value = emptyList()
        _error.value = null
        _isOnline.value = true
    }
    
    // Counties
    suspend fun loadCounties() {
        _isLoading.value = true
        _error.value = null
        
        try {
            if (_isOnline.value) {
                // Try online first
                val result = _apiService.getCounties()
                if (result.isSuccess) {
                    val counties = result.getOrNull() ?: emptyList()
                    _counties.value = counties
                    
                    // Save to offline storage
                    offlineRepository.saveCounties(counties)
                    return
                }
            }
            
            // Fallback to offline data
            val offlineCounties = offlineRepository.getAllCounties()
            _counties.value = offlineCounties
            
            if (offlineCounties.isEmpty() && _isOnline.value) {
                _error.value = "Failed to load counties"
            } else if (!_isOnline.value) {
                _error.value = "Working offline - data may not be current"
            }
            
        } catch (e: Exception) {
            // Network error - use offline data
            _isOnline.value = false
            val offlineCounties = offlineRepository.getAllCounties()
            _counties.value = offlineCounties
            _error.value = "No internet connection - showing cached data"
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun getCountyChecklist(countyId: Int): List<ChecklistItem> {
        return try {
            if (_isOnline.value) {
                val result = _apiService.getCountyChecklist(countyId)
                if (result.isSuccess) {
                    val checklist = result.getOrNull() ?: emptyList()
                    // Save to offline storage
                    offlineRepository.saveChecklistItems(countyId, checklist)
                    return checklist
                }
            }
            
            // Fallback to offline data
            offlineRepository.getChecklistItemsByCounty(countyId)
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to load county checklist"
            offlineRepository.getChecklistItemsByCounty(countyId)
        }
    }
    
    // Packages
    suspend fun loadPackages() {
        if (_apiService.authToken.value == null && _apiService.currentUser.value == null) return
        
        _isLoading.value = true
        _error.value = null
        
        try {
            if (_isOnline.value) {
                val result = _apiService.getPackages()
                if (result.isSuccess) {
                    val packages = result.getOrNull() ?: emptyList()
                    _packages.value = packages
                    
                    // Save to offline storage
                    offlineRepository.savePermitPackages(packages)
                    return
                }
            }
            
            // Fallback to offline data
            val offlinePackages = offlineRepository.getAllPermitPackages()
            _packages.value = offlinePackages
            
            if (!_isOnline.value && offlinePackages.isNotEmpty()) {
                _error.value = "Working offline - some changes may not be synced"
            }
            
        } catch (e: Exception) {
            _isOnline.value = false
            val offlinePackages = offlineRepository.getAllPermitPackages()
            _packages.value = offlinePackages
            _error.value = "No internet connection - showing cached data"
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun createPackage(countyId: Int, name: String, description: String?): Boolean {
        _isLoading.value = true
        _error.value = null
        
        return try {
            val currentUserId = _apiService.currentUser.value?.id ?: return false
            
            if (_isOnline.value) {
                // Try online creation
                val result = _apiService.createPackage(countyId, name, description)
                if (result.isSuccess) {
                    // Reload packages to get the updated list
                    loadPackages()
                    return true
                }
            }
            
            // Create offline
            val offlinePackage = offlineRepository.createPermitPackageOffline(
                userId = currentUserId,
                countyId = countyId,
                name = name,
                description = description
            )
            
            // Update UI immediately
            val currentPackages = _packages.value.toMutableList()
            currentPackages.add(0, offlinePackage)
            _packages.value = currentPackages
            
            _error.value = if (!_isOnline.value) {
                "Package created offline - will sync when online"
            } else null
            
            true
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to create package"
            false
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun getPackageDetails(packageId: Int): PackageWithDetails? {
        return try {
            if (_isOnline.value) {
                val result = _apiService.getPackageDetails(packageId)
                if (result.isSuccess) {
                    return result.getOrNull()
                }
            }
            
            // TODO: Implement offline package details
            null
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to load package details"
            null
        }
    }
    
    suspend fun updatePackageStatus(packageId: Int, status: String): Boolean {
        return try {
            if (_isOnline.value) {
                val result = _apiService.updatePackageStatus(packageId, status)
                if (result.isSuccess) {
                    // Reload packages to get the updated list
                    loadPackages()
                    return true
                }
            }
            
            // Update offline
            offlineRepository.updatePackageStatusOffline(packageId, status)
            
            // Update UI immediately
            val updatedPackages = _packages.value.map { pkg ->
                if (pkg.id == packageId) {
                    pkg.copy(status = status)
                } else {
                    pkg
                }
            }
            _packages.value = updatedPackages
            
            _error.value = if (!_isOnline.value) {
                "Status updated offline - will sync when online"
            } else null
            
            true
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to update package status"
            false
        }
    }
    
    // Documents
    suspend fun getPackageDocuments(packageId: Int): List<PermitDocument> {
        return try {
            if (_isOnline.value) {
                val result = _apiService.getPackageDocuments(packageId)
                if (result.isSuccess) {
                    val documents = result.getOrNull() ?: emptyList()
                    // Save to offline storage
                    offlineRepository.savePermitDocuments(packageId, documents)
                    return documents
                }
            }
            
            // Fallback to offline data
            offlineRepository.getDocumentsByPackage(packageId)
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to load package documents"
            offlineRepository.getDocumentsByPackage(packageId)
        }
    }
    
    suspend fun deleteDocument(packageId: Int, documentId: Int): Boolean {
        return try {
            if (_isOnline.value) {
                val result = _apiService.deleteDocument(packageId, documentId)
                if (result.isSuccess) {
                    return true
                }
            }
            
            // TODO: Implement offline document deletion
            _error.value = "Document deletion offline not yet supported"
            false
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to delete document"
            false
        }
    }
    
    // Offline-specific methods
    private suspend fun loadOfflineData() {
        _counties.value = offlineRepository.getAllCounties()
        _packages.value = offlineRepository.getAllPermitPackages()
    }
    
    suspend fun forceSyncNow(): Boolean {
        return syncManager.forceSyncNow()
    }
    
    suspend fun getSyncStats(): SyncManager.SyncStats {
        return syncManager.getSyncStats()
    }
    
    fun clearError() {
        _error.value = null
    }
    
    companion object {
        @Volatile
        private var INSTANCE: PermitRepository? = null
        
        fun getInstance(databaseDriverFactory: DatabaseDriverFactory): PermitRepository {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: PermitRepository(databaseDriverFactory).also { INSTANCE = it }
            }
        }
        
        // Backward compatibility - will need to be updated in UI
        @Deprecated("Use getInstance(DatabaseDriverFactory) instead")
        fun getInstance(): PermitRepository {
            throw IllegalStateException("DatabaseDriverFactory is required for offline functionality")
        }
    }
}
