package com.regnowsnaes.permitmanagementsystem.repository

import com.regnowsnaes.permitmanagementsystem.api.ApiService
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.datetime.Clock

class SyncManager(
    private val apiService: ApiService,
    private val offlineRepository: OfflineRepository
) {
    private val _syncStatus = MutableStateFlow<SyncStatus>(SyncStatus.Idle)
    val syncStatus: StateFlow<SyncStatus> = _syncStatus.asStateFlow()
    
    private val _lastSyncTime = MutableStateFlow<String?>(null)
    val lastSyncTime: StateFlow<String?> = _lastSyncTime.asStateFlow()
    
    private var syncJob: Job? = null
    
    sealed class SyncStatus {
        object Idle : SyncStatus()
        object Syncing : SyncStatus()
        data class Success(val message: String) : SyncStatus()
        data class Error(val message: String) : SyncStatus()
    }
    
    init {
        // Load last sync time
        CoroutineScope(Dispatchers.Default).launch {
            _lastSyncTime.value = offlineRepository.getLastSyncTime()
        }
    }
    
    /**
     * Performs a full synchronization between local and remote data
     */
    suspend fun performFullSync(): Boolean {
        if (_syncStatus.value is SyncStatus.Syncing) {
            return false // Already syncing
        }
        
        _syncStatus.value = SyncStatus.Syncing
        
        return try {
            // Step 1: Pull latest data from server
            val pullSuccess = pullRemoteData()
            
            if (pullSuccess) {
                val now = Clock.System.now().toString()
                _lastSyncTime.value = now
                _syncStatus.value = SyncStatus.Success("Sync completed successfully")
                true
            } else {
                _syncStatus.value = SyncStatus.Error("Sync failed")
                false
            }
        } catch (e: Exception) {
            _syncStatus.value = SyncStatus.Error("Sync failed: ${e.message}")
            false
        }
    }
    
    /**
     * Pull latest data from the server
     */
    private suspend fun pullRemoteData(): Boolean {
        return try {
            var allSuccess = true
            
            // Pull counties
            val countiesResult = apiService.getCounties()
            if (countiesResult.isSuccess) {
                val counties = countiesResult.getOrNull() ?: emptyList()
                offlineRepository.saveCounties(counties)
                
                // Pull checklist items for each county
                for (county in counties) {
                    val checklistResult = apiService.getCountyChecklist(county.id)
                    if (checklistResult.isSuccess) {
                        val checklist = checklistResult.getOrNull() ?: emptyList()
                        offlineRepository.saveChecklistItems(county.id, checklist)
                    } else {
                        allSuccess = false
                    }
                }
            } else {
                allSuccess = false
            }
            
            // Pull user's permit packages
            val packagesResult = apiService.getPackages()
            if (packagesResult.isSuccess) {
                val packages = packagesResult.getOrNull() ?: emptyList()
                offlineRepository.savePermitPackages(packages)
                
                // Pull documents for each package
                for (package_ in packages) {
                    val documentsResult = apiService.getPackageDocuments(package_.id)
                    if (documentsResult.isSuccess) {
                        val documents = documentsResult.getOrNull() ?: emptyList()
                        offlineRepository.savePermitDocuments(package_.id, documents)
                    } else {
                        allSuccess = false
                    }
                }
            } else {
                allSuccess = false
            }
            
            allSuccess
        } catch (e: Exception) {
            println("Error pulling remote data: ${e.message}")
            false
        }
    }
    
    /**
     * Performs background sync with retry logic
     */
    fun startBackgroundSync() {
        syncJob?.cancel()
        syncJob = CoroutineScope(Dispatchers.Default).launch {
            while (isActive) {
                try {
                    if (apiService.authToken.value != null) {
                        performFullSync()
                    }
                    delay(300_000) // Sync every 5 minutes
                } catch (e: Exception) {
                    println("Background sync error: ${e.message}")
                    delay(60_000) // Wait 1 minute before retry
                }
            }
        }
    }
    
    fun stopBackgroundSync() {
        syncJob?.cancel()
        syncJob = null
    }
    
    /**
     * Check if device is online (simplified check)
     */
    suspend fun isOnline(): Boolean {
        return try {
            val result = apiService.getCounties()
            result.isSuccess
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Force sync now
     */
    suspend fun forceSyncNow(): Boolean {
        return performFullSync()
    }
    
    /**
     * Get sync statistics
     */
    suspend fun getSyncStats(): SyncStats {
        val pendingOperations = offlineRepository.getPendingSyncOperations()
        val lastSync = offlineRepository.getLastSyncTime()
        
        return SyncStats(
            pendingOperations = pendingOperations.size,
            lastSyncTime = lastSync,
            isOnline = isOnline()
        )
    }
    
    data class SyncStats(
        val pendingOperations: Int,
        val lastSyncTime: String?,
        val isOnline: Boolean
    )
}
