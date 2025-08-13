package com.regnowsnaes.permitmanagementsystem

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.jetbrains.compose.ui.tooling.preview.Preview
import com.regnowsnaes.permitmanagementsystem.repository.PermitRepository
import com.regnowsnaes.permitmanagementsystem.database.DatabaseProvider
import com.regnowsnaes.permitmanagementsystem.models.County
import com.regnowsnaes.permitmanagementsystem.models.PermitPackage
import com.regnowsnaes.permitmanagementsystem.models.ChecklistItem
import com.regnowsnaes.permitmanagementsystem.models.PermitDocument
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
@Preview
fun App() {
    val repository = remember { 
        PermitRepository.getInstance(DatabaseProvider.getDatabaseDriverFactory()) 
    }
    val scope = rememberCoroutineScope()
    
    // State
    var selectedTab by remember { mutableStateOf(0) }
    var showLogin by remember { mutableStateOf(true) }
    
    // Observe repository state
    val counties by repository.counties.collectAsState()
    val packages by repository.packages.collectAsState()
    val currentUser by repository.currentUser.collectAsState()
    val isLoading by repository.isLoading.collectAsState()
    val error by repository.error.collectAsState()
    val isOnline by repository.isOnline.collectAsState()
    val syncStatus by repository.syncStatus.collectAsState()
    val lastSyncTime by repository.lastSyncTime.collectAsState()
    
    // Mock user for demo
    val mockUser = remember {
        com.regnowsnaes.permitmanagementsystem.models.User(
            id = 1,
            email = "demo@example.com",
            firstName = "Demo",
            lastName = "User",
            createdAt = "2025-01-01T00:00:00",
            updatedAt = "2025-01-01T00:00:00"
        )
    }
    
    // Load counties on startup
    LaunchedEffect(Unit) {
        repository.loadCounties()
    }
    
    // Show login if no user
    if (currentUser == null && showLogin) {
        LoginScreen(
            repository = repository,
            onLoginSuccess = { 
                showLogin = false
                scope.launch {
                    repository.loadPackages()
                }
            },
            onSwitchToRegister = { showLogin = false }
        )
        return
    }
    
    MaterialTheme {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // Header
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Florida Permit Management System",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Welcome, ${(currentUser ?: mockUser).firstName}!",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Sync Status and Offline Indicator
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Online/Offline Status
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = if (isOnline) 
                            MaterialTheme.colorScheme.primaryContainer 
                        else 
                            MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = if (isOnline) "🟢 Online" else "🔴 Offline",
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isOnline) 
                                MaterialTheme.colorScheme.onPrimaryContainer 
                            else 
                                MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
                
                // Sync Status
                when (syncStatus) {
                    is com.regnowsnaes.permitmanagementsystem.repository.SyncManager.SyncStatus.Syncing -> {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Syncing...",
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }
                    is com.regnowsnaes.permitmanagementsystem.repository.SyncManager.SyncStatus.Success -> {
                        TextButton(
                            onClick = {
                                scope.launch {
                                    repository.forceSyncNow()
                                }
                            }
                        ) {
                            Text("🔄 Sync Now")
                        }
                    }
                    is com.regnowsnaes.permitmanagementsystem.repository.SyncManager.SyncStatus.Error -> {
                        TextButton(
                            onClick = {
                                scope.launch {
                                    repository.forceSyncNow()
                                }
                            }
                        ) {
                            Text("⚠️ Retry Sync")
                        }
                    }
                    else -> {
                        TextButton(
                            onClick = {
                                scope.launch {
                                    repository.forceSyncNow()
                                }
                            }
                        ) {
                            Text("🔄 Sync")
                        }
                    }
                }
            }
            
            // Last sync time
            lastSyncTime?.let { syncTime ->
                Text(
                    text = "Last sync: ${syncTime.take(19).replace('T', ' ')}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 8.dp)
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Error display
            error?.let { errorMessage ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = errorMessage,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.weight(1f)
                        )
                        TextButton(onClick = { repository.clearError() }) {
                            Text("Dismiss")
                        }
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            // Loading indicator
            if (isLoading) {
                LinearProgressIndicator(
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            // Tab Row
            val tabs = if ((currentUser ?: mockUser).role == "admin") {
                listOf("Counties", "My Permits", "Admin", "Profile")
            } else {
                listOf("Counties", "My Permits", "Profile")
            }
            TabRow(selectedTabIndex = selectedTab) {
                tabs.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = { Text(title) }
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Content based on selected tab
            val isAdmin = (currentUser ?: mockUser).role == "admin"
            when (selectedTab) {
                0 -> CountiesScreen(counties = counties, repository = repository)
                1 -> PermitsScreen(packages = packages, repository = repository)
                2 -> if (isAdmin) AdminScreen(repository = repository) else ProfileScreen(repository = repository)
                3 -> if (isAdmin) ProfileScreen(repository = repository) else Unit
            }
        }
    }
}

@Composable
fun LoginScreen(
    repository: PermitRepository,
    onLoginSuccess: () -> Unit,
    onSwitchToRegister: () -> Unit
) {
    var email by remember { mutableStateOf("alice@example.com") }
    var password by remember { mutableStateOf("password123") }
    var isRegisterMode by remember { mutableStateOf(false) }
    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    
    val scope = rememberCoroutineScope()
    val isLoading by repository.isLoading.collectAsState()
    val error by repository.error.collectAsState()
    
    MaterialTheme {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = if (isRegisterMode) "Create Account" else "Welcome Back",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            if (isRegisterMode) {
                OutlinedTextField(
                    value = firstName,
                    onValueChange = { firstName = it },
                    label = { Text("First Name") },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(16.dp))
                
                OutlinedTextField(
                    value = lastName,
                    onValueChange = { lastName = it },
                    label = { Text("Last Name") },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email") },
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            error?.let { errorMessage ->
                Text(
                    text = errorMessage,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
            }
            
            Button(
                onClick = {
                    scope.launch {
                        val success = if (isRegisterMode) {
                            repository.register(email, password, firstName, lastName)
                        } else {
                            repository.login(email, password)
                        }
                        if (success) {
                            onLoginSuccess()
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(16.dp))
                } else {
                    Text(if (isRegisterMode) "Create Account" else "Login")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            TextButton(
                onClick = { isRegisterMode = !isRegisterMode }
            ) {
                Text(
                    if (isRegisterMode) "Already have an account? Login" 
                    else "Don't have an account? Register"
                )
            }
        }
    }
}

@Composable
fun CountiesScreen(counties: List<County>, repository: PermitRepository) {
    val scope = rememberCoroutineScope()
    var showCreateDialog by remember { mutableStateOf(false) }
    var selectedCounty by remember { mutableStateOf<County?>(null) }
    
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Florida Counties (${counties.size})",
                style = MaterialTheme.typography.headlineSmall,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            
            Button(
                onClick = { 
                    if (counties.isNotEmpty()) {
                        selectedCounty = counties.first()
                        showCreateDialog = true
                    }
                }
            ) {
                Text("Create Permit")
            }
        }
        
        if (counties.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text("Loading counties...")
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(counties) { county ->
                    CountyCard(county = county, repository = repository)
                }
            }
        }
    }
    
    // Create Permit Dialog
    if (showCreateDialog && selectedCounty != null) {
        CreatePermitDialog(
            county = selectedCounty!!,
            counties = counties,
            onDismiss = { showCreateDialog = false },
            onConfirm = { county, name, description ->
                scope.launch {
                    repository.createPackage(county.id, name, description)
                    showCreateDialog = false
                }
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CountyCard(county: County, repository: PermitRepository) {
    val scope = rememberCoroutineScope()
    var showChecklist by remember { mutableStateOf(false) }
    var checklistItems by remember { mutableStateOf<List<ChecklistItem>>(emptyList()) }
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = { 
            scope.launch {
                checklistItems = repository.getCountyChecklist(county.id)
                showChecklist = true
            }
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = county.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = county.state,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Text(
                text = "View Requirements",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
    
    // Checklist Dialog
    if (showChecklist) {
        AlertDialog(
            onDismissRequest = { showChecklist = false },
            title = { Text("${county.name} Requirements") },
            text = {
                LazyColumn {
                    if (checklistItems.isEmpty()) {
                        item {
                            Text("No specific requirements available for this county.")
                        }
                    } else {
                        items(checklistItems) { item ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp)
                            ) {
                                Column(
                                    modifier = Modifier.padding(12.dp)
                                ) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            text = item.title,
                                            style = MaterialTheme.typography.titleSmall,
                                            fontWeight = FontWeight.Medium
                                        )
                                        if (item.required) {
                                            Text(
                                                text = " *",
                                                color = MaterialTheme.colorScheme.error,
                                                style = MaterialTheme.typography.titleSmall
                                            )
                                        }
                                    }
                                    Text(
                                        text = item.description,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier.padding(top = 4.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showChecklist = false }) {
                    Text("Close")
                }
            }
        )
    }
}

@Composable
fun PermitsScreen(packages: List<PermitPackage>, repository: PermitRepository) {
    val scope = rememberCoroutineScope()
    
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "My Permits (${packages.size})",
                style = MaterialTheme.typography.headlineSmall,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            
            Button(
                onClick = {
                    scope.launch {
                        repository.loadPackages()
                    }
                }
            ) {
                Text("Refresh")
            }
        }
        
        if (packages.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("No permits yet")
                    Text(
                        "Create a permit from the Counties tab",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(packages) { permitPackage ->
                    PermitCard(permitPackage = permitPackage, repository = repository)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PermitCard(permitPackage: PermitPackage, repository: PermitRepository) {
    val scope = rememberCoroutineScope()
    var showStatusDialog by remember { mutableStateOf(false) }
    var showDocumentsDialog by remember { mutableStateOf(false) }
    
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = permitPackage.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    
                    // Show county name if available, otherwise show county ID
                    Text(
                        text = "County ID: ${permitPackage.countyId}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    permitPackage.description?.let { description ->
                        Text(
                            text = description,
                            style = MaterialTheme.typography.bodySmall,
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }
                    
                    Text(
                        text = "Created: ${permitPackage.createdAt.take(10)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
                
                StatusChip(permitPackage.status)
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = { showStatusDialog = true },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Update Status")
                }
                
                OutlinedButton(
                    onClick = { showDocumentsDialog = true },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Documents")
                }
            }
        }
    }
    
    // Status Update Dialog
    if (showStatusDialog) {
        StatusUpdateDialog(
            currentStatus = permitPackage.status,
            onDismiss = { showStatusDialog = false },
            onConfirm = { newStatus ->
                scope.launch {
                    repository.updatePackageStatus(permitPackage.id, newStatus)
                    showStatusDialog = false
                }
            }
        )
    }
    
    // Documents Dialog
    if (showDocumentsDialog) {
        DocumentsDialog(
            permitPackage = permitPackage,
            repository = repository,
            onDismiss = { showDocumentsDialog = false }
        )
    }
}

@Composable
fun StatusUpdateDialog(
    currentStatus: String,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    val statusOptions = listOf(
        "draft" to "Draft",
        "submitted" to "Submitted", 
        "in_progress" to "In Progress",
        "approved" to "Approved",
        "rejected" to "Rejected"
    )
    
    var selectedStatus by remember { mutableStateOf(currentStatus) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Update Permit Status") },
        text = {
            Column {
                Text(
                    text = "Current status: ${statusOptions.find { it.first == currentStatus }?.second ?: currentStatus}",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
                
                statusOptions.forEach { (value, label) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = selectedStatus == value,
                            onClick = { selectedStatus = value }
                        )
                        Text(
                            text = label,
                            modifier = Modifier.padding(start = 8.dp)
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onConfirm(selectedStatus) },
                enabled = selectedStatus != currentStatus
            ) {
                Text("Update")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun StatusChip(status: String) {
    val (color, text) = when (status) {
        "approved" -> MaterialTheme.colorScheme.primary to "Approved"
        "in_progress" -> MaterialTheme.colorScheme.secondary to "In Progress"
        "submitted" -> MaterialTheme.colorScheme.tertiary to "Submitted"
        "draft" -> MaterialTheme.colorScheme.outline to "Draft"
        else -> MaterialTheme.colorScheme.outline to status.capitalize()
    }
    
    Surface(
        color = color.copy(alpha = 0.1f),
        shape = MaterialTheme.shapes.small,
        modifier = Modifier.padding(4.dp)
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall,
            color = color
        )
    }
}

@Composable
fun ProfileScreen(repository: PermitRepository) {
    val currentUser by repository.currentUser.collectAsState()
    val scope = rememberCoroutineScope()
    
    // Mock user for demo
    val mockUser = com.regnowsnaes.permitmanagementsystem.models.User(
        id = 1,
        email = "demo@example.com",
        firstName = "Demo",
        lastName = "User",
        createdAt = "2025-01-01T00:00:00",
        updatedAt = "2025-01-01T00:00:00"
    )
    
    val displayUser = currentUser ?: mockUser
    
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "User Profile",
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                ProfileItem("Name", "${displayUser.firstName} ${displayUser.lastName}")
                ProfileItem("Email", displayUser.email)
                ProfileItem("Member Since", displayUser.createdAt?.take(10) ?: "2025-01-01") // Just the date part
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Button(
                    onClick = {
                        repository.logout()
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Logout")
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "App Information",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                ProfileItem("Version", "1.0.0")
                ProfileItem("Platform", getPlatform().name)
                ProfileItem("Server Status", "Connected")
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreatePermitDialog(
    county: County,
    counties: List<County>,
    onDismiss: () -> Unit,
    onConfirm: (County, String, String) -> Unit
) {
    var selectedCounty by remember { mutableStateOf(county) }
    var permitName by remember { mutableStateOf("") }
    var permitDescription by remember { mutableStateOf("") }
    var expanded by remember { mutableStateOf(false) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create New Permit") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // County Selector
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = selectedCounty.name,
                        onValueChange = { },
                        readOnly = true,
                        label = { Text("County") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        modifier = Modifier
                            .menuAnchor()
                            .fillMaxWidth()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        counties.forEach { county ->
                            DropdownMenuItem(
                                text = { Text(county.name) },
                                onClick = {
                                    selectedCounty = county
                                    expanded = false
                                }
                            )
                        }
                    }
                }
                
                // Permit Name
                OutlinedTextField(
                    value = permitName,
                    onValueChange = { permitName = it },
                    label = { Text("Permit Name") },
                    placeholder = { Text("e.g., Pool Installation, Deck Construction") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                // Permit Description
                OutlinedTextField(
                    value = permitDescription,
                    onValueChange = { permitDescription = it },
                    label = { Text("Description") },
                    placeholder = { Text("Brief description of the project") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (permitName.isNotBlank()) {
                        onConfirm(selectedCounty, permitName, permitDescription.ifBlank { null } ?: permitDescription)
                    }
                },
                enabled = permitName.isNotBlank()
            ) {
                Text("Create")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun AdminScreen(repository: PermitRepository) {
    var selectedAdminTab by remember { mutableStateOf(0) }
    val adminTabs = listOf("Users", "Counties")
    
    Column {
        Text(
            text = "System Administration",
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        
        TabRow(selectedTabIndex = selectedAdminTab) {
            adminTabs.forEachIndexed { index, title ->
                Tab(
                    selected = selectedAdminTab == index,
                    onClick = { selectedAdminTab = index },
                    text = { Text(title) }
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        when (selectedAdminTab) {
            0 -> UserManagementScreen(repository = repository)
            1 -> CountyManagementScreen(repository = repository)
        }
    }
}

@Composable
fun UserManagementScreen(repository: PermitRepository) {
    var users by remember { mutableStateOf<List<com.regnowsnaes.permitmanagementsystem.models.User>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    
    // Load users on first composition
    LaunchedEffect(Unit) {
        isLoading = true
        try {
            val result = repository.apiService.getAllUsers()
            if (result.isSuccess) {
                users = result.getOrNull() ?: emptyList()
            } else {
                error = result.exceptionOrNull()?.message ?: "Failed to load users"
            }
        } catch (e: Exception) {
            error = e.message ?: "Failed to load users"
        } finally {
            isLoading = false
        }
    }
    
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "User Management (${users.size})",
                style = MaterialTheme.typography.titleLarge
            )
            
            Button(
                onClick = {
                    scope.launch {
                        isLoading = true
                        try {
                            val result = repository.apiService.getAllUsers()
                            if (result.isSuccess) {
                                users = result.getOrNull() ?: emptyList()
                                error = null
                            } else {
                                error = result.exceptionOrNull()?.message ?: "Failed to load users"
                            }
                        } catch (e: Exception) {
                            error = e.message ?: "Failed to load users"
                        } finally {
                            isLoading = false
                        }
                    }
                }
            ) {
                Text("Refresh")
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        error?.let { errorMessage ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
            ) {
                Text(
                    text = errorMessage,
                    modifier = Modifier.padding(16.dp),
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
        }
        
        if (isLoading) {
            LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))
        }
        
        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(users) { user ->
                UserManagementCard(user = user, repository = repository) { updatedUser ->
                    users = users.map { if (it.id == updatedUser.id) updatedUser else it }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UserManagementCard(
    user: com.regnowsnaes.permitmanagementsystem.models.User,
    repository: PermitRepository,
    onUserUpdated: (com.regnowsnaes.permitmanagementsystem.models.User) -> Unit
) {
    var showRoleDialog by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "${user.firstName} ${user.lastName}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = user.email,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "Member since: ${user.createdAt.take(10)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                Surface(
                    color = when (user.role) {
                        "admin" -> MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                        "county_admin" -> MaterialTheme.colorScheme.secondary.copy(alpha = 0.1f)
                        else -> MaterialTheme.colorScheme.outline.copy(alpha = 0.1f)
                    },
                    shape = MaterialTheme.shapes.small
                ) {
                    Text(
                        text = user.role.replace("_", " ").uppercase(),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = when (user.role) {
                            "admin" -> MaterialTheme.colorScheme.primary
                            "county_admin" -> MaterialTheme.colorScheme.secondary
                            else -> MaterialTheme.colorScheme.outline
                        }
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = { showRoleDialog = true },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Change Role")
                }
                
                OutlinedButton(
                    onClick = {
                        scope.launch {
                            val result = repository.apiService.deleteUser(user.id)
                            if (result.isSuccess) {
                                // User will be removed from list on next refresh
                            }
                        }
                    },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Delete")
                }
            }
        }
    }
    
    // Role Change Dialog
    if (showRoleDialog) {
        RoleChangeDialog(
            currentRole = user.role,
            onDismiss = { showRoleDialog = false },
            onConfirm = { newRole ->
                scope.launch {
                    val result = repository.apiService.updateUserRole(user.id, newRole)
                    if (result.isSuccess) {
                        result.getOrNull()?.let { updatedUser ->
                            onUserUpdated(updatedUser)
                        }
                    }
                    showRoleDialog = false
                }
            }
        )
    }
}

@Composable
fun RoleChangeDialog(
    currentRole: String,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    val roles = listOf(
        "user" to "Regular User",
        "county_admin" to "County Administrator", 
        "admin" to "System Administrator"
    )
    
    var selectedRole by remember { mutableStateOf(currentRole) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Change User Role") },
        text = {
            Column {
                Text(
                    text = "Current role: ${roles.find { it.first == currentRole }?.second ?: currentRole}",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
                
                roles.forEach { (value, label) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = selectedRole == value,
                            onClick = { selectedRole = value }
                        )
                        Text(
                            text = label,
                            modifier = Modifier.padding(start = 8.dp)
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onConfirm(selectedRole) },
                enabled = selectedRole != currentRole
            ) {
                Text("Update")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun CountyManagementScreen(repository: PermitRepository) {
    val counties by repository.counties.collectAsState()
    var selectedCounty by remember { mutableStateOf<County?>(null) }
    
    Column {
        Text(
            text = "County Checklist Management",
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier.padding(bottom = 16.dp)
        )
        
        if (counties.isEmpty()) {
            Text("Loading counties...")
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(counties) { county ->
                    CountyManagementCard(
                        county = county,
                        repository = repository
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CountyManagementCard(
    county: County,
    repository: PermitRepository
) {
    var showChecklistDialog by remember { mutableStateOf(false) }
    var checklistItems by remember { mutableStateOf<List<ChecklistItem>>(emptyList()) }
    val scope = rememberCoroutineScope()
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = {
            scope.launch {
                checklistItems = repository.getCountyChecklist(county.id)
                showChecklistDialog = true
            }
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = county.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = county.state,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Text(
                text = "Manage Checklist",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
    
    // Checklist Management Dialog
    if (showChecklistDialog) {
        ChecklistManagementDialog(
            county = county,
            checklistItems = checklistItems,
            repository = repository,
            onDismiss = { showChecklistDialog = false },
            onItemsUpdated = { updatedItems ->
                checklistItems = updatedItems
            }
        )
    }
}

@Composable
fun ChecklistManagementDialog(
    county: County,
    checklistItems: List<ChecklistItem>,
    repository: PermitRepository,
    onDismiss: () -> Unit,
    onItemsUpdated: (List<ChecklistItem>) -> Unit
) {
    var showAddDialog by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("${county.name} Checklist") },
        text = {
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Requirements (${checklistItems.size})")
                    TextButton(onClick = { showAddDialog = true }) {
                        Text("Add Item")
                    }
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                LazyColumn(
                    modifier = Modifier.height(300.dp)
                ) {
                    items(checklistItems) { item ->
                        ChecklistItemCard(
                            item = item,
                            county = county,
                            repository = repository,
                            onItemDeleted = {
                                onItemsUpdated(checklistItems.filter { it.id != item.id })
                            }
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close")
            }
        }
    )
    
    // Add Item Dialog
    if (showAddDialog) {
        AddChecklistItemDialog(
            county = county,
            repository = repository,
            onDismiss = { showAddDialog = false },
            onItemAdded = { newItem ->
                onItemsUpdated(checklistItems + newItem)
                showAddDialog = false
            }
        )
    }
}

@Composable
fun ChecklistItemCard(
    item: ChecklistItem,
    county: County,
    repository: PermitRepository,
    onItemDeleted: () -> Unit
) {
    val scope = rememberCoroutineScope()
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = item.title,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Medium
                        )
                        if (item.required) {
                            Text(
                                text = " *",
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.titleSmall
                            )
                        }
                    }
                    Text(
                        text = item.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
                
                TextButton(
                    onClick = {
                        scope.launch {
                            val result = repository.apiService.deleteChecklistItem(county.id, item.id!!)
                            if (result.isSuccess) {
                                onItemDeleted()
                            }
                        }
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Delete", style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}

@Composable
fun DocumentsDialog(
    permitPackage: PermitPackage,
    repository: PermitRepository,
    onDismiss: () -> Unit
) {
    var documents by remember { mutableStateOf<List<PermitDocument>>(emptyList()) }
    var checklistItems by remember { mutableStateOf<List<ChecklistItem>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    
    // Load documents and checklist items
    LaunchedEffect(permitPackage.id) {
        isLoading = true
        try {
            documents = repository.getPackageDocuments(permitPackage.id)
            checklistItems = repository.getCountyChecklist(permitPackage.countyId)
        } catch (e: Exception) {
            error = e.message ?: "Failed to load documents"
        } finally {
            isLoading = false
        }
    }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("${permitPackage.name} - Documents") },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(400.dp)
            ) {
                if (isLoading) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                } else {
                    error?.let { errorMessage ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
                        ) {
                            Text(
                                text = errorMessage,
                                modifier = Modifier.padding(16.dp),
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                    
                    Text(
                        text = "Required Documents (${checklistItems.filter { it.required }.size})",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(checklistItems) { item ->
                            DocumentRequirementCard(
                                checklistItem = item,
                                documents = documents.filter { it.checklistItemId == item.id },
                                permitPackage = permitPackage,
                                repository = repository,
                                onDocumentUploaded = { newDoc ->
                                    documents = documents + newDoc
                                },
                                onDocumentDeleted = { deletedDocId ->
                                    documents = documents.filter { it.id != deletedDocId }
                                }
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close")
            }
        }
    )
}

@Composable
fun DocumentRequirementCard(
    checklistItem: ChecklistItem,
    documents: List<PermitDocument>,
    permitPackage: PermitPackage,
    repository: PermitRepository,
    onDocumentUploaded: (PermitDocument) -> Unit,
    onDocumentDeleted: (Int) -> Unit
) {
    var showUploadDialog by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = checklistItem.title,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Medium
                        )
                        if (checklistItem.required) {
                            Text(
                                text = " *",
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.titleSmall
                            )
                        }
                    }
                    Text(
                        text = checklistItem.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 2.dp)
                    )
                }
                
                Surface(
                    color = if (documents.isNotEmpty()) {
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                    } else if (checklistItem.required) {
                        MaterialTheme.colorScheme.error.copy(alpha = 0.1f)
                    } else {
                        MaterialTheme.colorScheme.outline.copy(alpha = 0.1f)
                    },
                    shape = MaterialTheme.shapes.small
                ) {
                    Text(
                        text = if (documents.isNotEmpty()) "✓ ${documents.size}" else if (checklistItem.required) "Required" else "Optional",
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = if (documents.isNotEmpty()) {
                            MaterialTheme.colorScheme.primary
                        } else if (checklistItem.required) {
                            MaterialTheme.colorScheme.error
                        } else {
                            MaterialTheme.colorScheme.outline
                        }
                    )
                }
            }
            
            if (documents.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                documents.forEach { document ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 2.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = document.fileName,
                                style = MaterialTheme.typography.bodySmall,
                                fontWeight = FontWeight.Medium
                            )
                            Text(
                                text = "${(document.fileSize / 1024).toInt()} KB • ${document.uploadedAt.take(10)}",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        
                        TextButton(
                            onClick = {
                                scope.launch {
                                    val result = repository.apiService.deleteDocument(permitPackage.id, document.id)
                                    if (result.isSuccess) {
                                        onDocumentDeleted(document.id)
                                    }
                                }
                            },
                            colors = ButtonDefaults.textButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Text("Delete", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Button(
                onClick = { showUploadDialog = true },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    contentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            ) {
                Text("Upload Document")
            }
        }
    }
    
    // Upload Dialog (placeholder for now)
    if (showUploadDialog) {
        AlertDialog(
            onDismissRequest = { showUploadDialog = false },
            title = { Text("Upload Document") },
            text = {
                Column {
                    Text("Document upload functionality is not yet implemented in the desktop version.")
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        "This feature will be available in the mobile apps where file picking is supported.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = { showUploadDialog = false }) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
fun AddChecklistItemDialog(
    county: County,
    repository: PermitRepository,
    onDismiss: () -> Unit,
    onItemAdded: (ChecklistItem) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var required by remember { mutableStateOf(true) }
    var orderIndex by remember { mutableStateOf("1") }
    val scope = rememberCoroutineScope()
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Checklist Item") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Title") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2
                )
                
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Checkbox(
                        checked = required,
                        onCheckedChange = { required = it }
                    )
                    Text("Required", modifier = Modifier.padding(start = 8.dp))
                }
                
                OutlinedTextField(
                    value = orderIndex,
                    onValueChange = { orderIndex = it },
                    label = { Text("Order Index") },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    scope.launch {
                        val result = repository.apiService.createChecklistItem(
                            countyId = county.id,
                            title = title,
                            description = description,
                            required = required,
                            orderIndex = orderIndex.toIntOrNull() ?: 1
                        )
                        if (result.isSuccess) {
                            result.getOrNull()?.let { newItem ->
                                onItemAdded(newItem)
                            }
                        }
                    }
                },
                enabled = title.isNotBlank() && description.isNotBlank()
            ) {
                Text("Add")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun CreatePackageDialog(
    county: County,
    repository: PermitRepository,
    onDismiss: () -> Unit,
    onPackageCreated: () -> Unit
) {
    var name by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    
    // Customer Information
    var customerName by remember { mutableStateOf("") }
    var customerEmail by remember { mutableStateOf("") }
    var customerPhone by remember { mutableStateOf("") }
    var customerCompany by remember { mutableStateOf("") }
    var customerLicense by remember { mutableStateOf("") }
    
    // Site Information
    var siteAddress by remember { mutableStateOf("") }
    var siteCity by remember { mutableStateOf("") }
    var siteState by remember { mutableStateOf("FL") }
    var siteZip by remember { mutableStateOf("") }
    var siteCounty by remember { mutableStateOf(county.name) }
    
    var currentTab by remember { mutableStateOf(0) }
    val scope = rememberCoroutineScope()
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create Permit Package - ${county.name}") },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(500.dp)
            ) {
                // Tab Row
                val tabs = listOf("Basic Info", "Customer", "Site")
                TabRow(selectedTabIndex = currentTab) {
                    tabs.forEachIndexed { index, title ->
                        Tab(
                            selected = currentTab == index,
                            onClick = { currentTab = index },
                            text = { Text(title, style = MaterialTheme.typography.labelMedium) }
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Tab Content
                when (currentTab) {
                    0 -> {
                        // Basic Information
                        Column(
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            OutlinedTextField(
                                value = name,
                                onValueChange = { name = it },
                                label = { Text("Project Name *") },
                                modifier = Modifier.fillMaxWidth(),
                                placeholder = { Text("e.g., Home Addition, New Construction") }
                            )
                            
                            OutlinedTextField(
                                value = description,
                                onValueChange = { description = it },
                                label = { Text("Project Description") },
                                modifier = Modifier.fillMaxWidth(),
                                minLines = 3,
                                placeholder = { Text("Describe the scope of work...") }
                            )
                        }
                    }
                    
                    1 -> {
                        // Customer Information
                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            item {
                                OutlinedTextField(
                                    value = customerName,
                                    onValueChange = { customerName = it },
                                    label = { Text("Customer Name") },
                                    modifier = Modifier.fillMaxWidth(),
                                    placeholder = { Text("Full name or business name") }
                                )
                            }
                            
                            item {
                                OutlinedTextField(
                                    value = customerEmail,
                                    onValueChange = { customerEmail = it },
                                    label = { Text("Email Address") },
                                    modifier = Modifier.fillMaxWidth(),
                                    placeholder = { Text("customer@example.com") }
                                )
                            }
                            
                            item {
                                OutlinedTextField(
                                    value = customerPhone,
                                    onValueChange = { customerPhone = it },
                                    label = { Text("Phone Number") },
                                    modifier = Modifier.fillMaxWidth(),
                                    placeholder = { Text("(555) 123-4567") }
                                )
                            }
                            
                            item {
                                OutlinedTextField(
                                    value = customerCompany,
                                    onValueChange = { customerCompany = it },
                                    label = { Text("Company Name") },
                                    modifier = Modifier.fillMaxWidth(),
                                    placeholder = { Text("Optional") }
                                )
                            }
                            
                            item {
                                OutlinedTextField(
                                    value = customerLicense,
                                    onValueChange = { customerLicense = it },
                                    label = { Text("License Number") },
                                    modifier = Modifier.fillMaxWidth(),
                                    placeholder = { Text("Contractor license, if applicable") }
                                )
                            }
                        }
                    }
                    
                    2 -> {
                        // Site Information
                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            item {
                                OutlinedTextField(
                                    value = siteAddress,
                                    onValueChange = { siteAddress = it },
                                    label = { Text("Site Address") },
                                    modifier = Modifier.fillMaxWidth(),
                                    placeholder = { Text("123 Main Street") }
                                )
                            }
                            
                            item {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    OutlinedTextField(
                                        value = siteCity,
                                        onValueChange = { siteCity = it },
                                        label = { Text("City") },
                                        modifier = Modifier.weight(2f),
                                        placeholder = { Text("Miami") }
                                    )
                                    
                                    OutlinedTextField(
                                        value = siteState,
                                        onValueChange = { siteState = it },
                                        label = { Text("State") },
                                        modifier = Modifier.weight(1f),
                                        placeholder = { Text("FL") }
                                    )
                                }
                            }
                            
                            item {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    OutlinedTextField(
                                        value = siteZip,
                                        onValueChange = { siteZip = it },
                                        label = { Text("ZIP Code") },
                                        modifier = Modifier.weight(1f),
                                        placeholder = { Text("33101") }
                                    )
                                    
                                    OutlinedTextField(
                                        value = siteCounty,
                                        onValueChange = { siteCounty = it },
                                        label = { Text("County") },
                                        modifier = Modifier.weight(2f),
                                        enabled = false
                                    )
                                }
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (currentTab > 0) {
                    TextButton(onClick = { currentTab-- }) {
                        Text("Previous")
                    }
                }
                
                if (currentTab < 2) {
                    Button(
                        onClick = { currentTab++ },
                        enabled = if (currentTab == 0) name.isNotBlank() else true
                    ) {
                        Text("Next")
                    }
                } else {
                    Button(
                        onClick = {
                            scope.launch {
                                val result = repository.apiService.createPackage(
                                    countyId = county.id,
                                    name = name,
                                    description = description.takeIf { it.isNotBlank() },
                                    customerName = customerName.takeIf { it.isNotBlank() },
                                    customerEmail = customerEmail.takeIf { it.isNotBlank() },
                                    customerPhone = customerPhone.takeIf { it.isNotBlank() },
                                    customerCompany = customerCompany.takeIf { it.isNotBlank() },
                                    customerLicense = customerLicense.takeIf { it.isNotBlank() },
                                    siteAddress = siteAddress.takeIf { it.isNotBlank() },
                                    siteCity = siteCity.takeIf { it.isNotBlank() },
                                    siteState = siteState.takeIf { it.isNotBlank() },
                                    siteZip = siteZip.takeIf { it.isNotBlank() },
                                    siteCounty = siteCounty.takeIf { it.isNotBlank() }
                                )
                                if (result.isSuccess) {
                                    onPackageCreated()
                                }
                            }
                        },
                        enabled = name.isNotBlank()
                    ) {
                        Text("Create Package")
                    }
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun ProfileItem(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}