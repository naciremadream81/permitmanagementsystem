package com.regnowsnaes.permitmanagementsystem.android

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import kotlinx.coroutines.launch
import java.io.File

@Composable
@Preview
fun AndroidApp() {
    var currentScreen by remember { mutableStateOf<AndroidScreen>(AndroidScreen.Login) }
    var currentUser by remember { mutableStateOf<AndroidUser?>(null) }
    var authToken by remember { mutableStateOf<String?>(null) }
    
    MaterialTheme {
        when (currentScreen) {
            AndroidScreen.Login -> {
                AndroidLoginScreen(
                    onLoginSuccess = { user, token ->
                        currentUser = user
                        authToken = token
                        currentScreen = AndroidScreen.Main
                    }
                )
            }
            AndroidScreen.Main -> {
                AndroidMainScreen(
                    user = currentUser!!,
                    authToken = authToken!!,
                    onLogout = {
                        currentUser = null
                        authToken = null
                        currentScreen = AndroidScreen.Login
                    }
                )
            }
        }
    }
}

@Composable
fun AndroidLoginScreen(onLoginSuccess: (AndroidUser, String) -> Unit) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // App Icon
        Icon(
            imageVector = Icons.Default.Business,
            contentDescription = null,
            modifier = Modifier.size(100.dp),
            tint = MaterialTheme.colors.primary
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "Permit Management",
            style = MaterialTheme.typography.h4,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colors.primary
        )
        
        Text(
            text = "Mobile App",
            style = MaterialTheme.typography.subtitle1,
            color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
        )
        
        Spacer(modifier = Modifier.height(48.dp))
        
        // Login Form
        Card(
            modifier = Modifier.fillMaxWidth(),
            elevation = 8.dp,
            shape = RoundedCornerShape(20.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Sign In",
                    style = MaterialTheme.typography.h5,
                    fontWeight = FontWeight.Bold
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Email") },
                    modifier = Modifier.fillMaxWidth(),
                    leadingIcon = { Icon(Icons.Default.Email, null) },
                    singleLine = true,
                    colors = TextFieldDefaults.outlinedTextFieldColors(
                        focusedBorderColor = MaterialTheme.colors.primary,
                        unfocusedBorderColor = MaterialTheme.colors.onSurface.copy(alpha = 0.3f)
                    )
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Password") },
                    modifier = Modifier.fillMaxWidth(),
                    leadingIcon = { Icon(Icons.Default.Lock, null) },
                    singleLine = true,
                    visualTransformation = androidx.compose.ui.text.input.PasswordVisualTransformation(),
                    colors = TextFieldDefaults.outlinedTextFieldColors(
                        focusedBorderColor = MaterialTheme.colors.primary,
                        unfocusedBorderColor = MaterialTheme.colors.onSurface.copy(alpha = 0.3f)
                    )
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                if (errorMessage != null) {
                    Text(
                        text = errorMessage!!,
                        color = MaterialTheme.colors.error,
                        style = MaterialTheme.typography.body2
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                }
                
                Button(
                    onClick = {
                        if (email.isNotBlank() && password.isNotBlank()) {
                            isLoading = true
                            // Simulate login
                            kotlinx.coroutines.GlobalScope.launch {
                                kotlinx.coroutines.delay(1000)
                                isLoading = false
                                onLoginSuccess(
                                    AndroidUser("1", "Mobile", "User", email),
                                    "mobile-token-456"
                                )
                            }
                        } else {
                            errorMessage = "Please fill in all fields"
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    enabled = !isLoading,
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = MaterialTheme.colors.primary
                    ),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = MaterialTheme.colors.onPrimary
                        )
                    } else {
                        Text("Sign In", fontSize = 18.sp, fontWeight = FontWeight.Bold)
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "Demo Mode - Tap Sign In to continue",
                    style = MaterialTheme.typography.caption,
                    color = MaterialTheme.colors.onSurface.copy(alpha = 0.6f)
                )
            }
        }
    }
}

@Composable
fun AndroidMainScreen(user: AndroidUser, authToken: String, onLogout: () -> Unit) {
    var selectedTab by remember { mutableStateOf(0) }
    var selectedCounty by remember { mutableStateOf<String?>(null) }
    var selectedFiles by remember { mutableStateOf<List<File>>(emptyList()) }
    
    val tabs = listOf("Home", "Counties", "Docs", "Profile")
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Permit Management") },
                actions = {
                    IconButton(onClick = onLogout) {
                        Icon(Icons.Default.ExitToApp, "Logout")
                    }
                },
                backgroundColor = MaterialTheme.colors.primary,
                contentColor = MaterialTheme.colors.onPrimary
            )
        },
        bottomBar = {
            BottomNavigation(
                backgroundColor = MaterialTheme.colors.surface,
                contentColor = MaterialTheme.colors.onSurface
            ) {
                tabs.forEachIndexed { index, title ->
                    BottomNavigationItem(
                        icon = {
                            when (index) {
                                0 -> Icon(Icons.Default.Home, "Home")
                                1 -> Icon(Icons.Default.LocationOn, "Counties")
                                2 -> Icon(Icons.Default.Description, "Documents")
                                3 -> Icon(Icons.Default.Person, "Profile")
                            }
                        },
                        label = { Text(title) },
                        selected = selectedTab == index,
                        onClick = { selectedTab = index }
                    )
                }
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // User Welcome Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                elevation = 4.dp,
                shape = RoundedCornerShape(16.dp)
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colors.primary
                    )
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Column {
                        Text(
                            text = "Welcome, ${user.firstName} ${user.lastName}",
                            style = MaterialTheme.typography.h6,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = user.email,
                            style = MaterialTheme.typography.body2,
                            color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
                        )
                    }
                }
            }
            
            // Tab Content
            when (selectedTab) {
                0 -> AndroidHomeTab()
                1 -> AndroidCountiesTab(
                    selectedCounty = selectedCounty,
                    onCountySelected = { selectedCounty = it }
                )
                2 -> AndroidDocumentsTab(
                    selectedFiles = selectedFiles,
                    onFilesSelected = { selectedFiles = it }
                )
                3 -> AndroidProfileTab(user)
            }
        }
    }
}

@Composable
fun AndroidHomeTab() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp)
    ) {
        item {
            Text(
                text = "Dashboard",
                style = MaterialTheme.typography.h5,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }
        
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                AndroidStatCard(
                    title = "Active",
                    value = "12",
                    icon = Icons.Default.Assignment,
                    modifier = Modifier.weight(1f)
                )
                AndroidStatCard(
                    title = "Done",
                    value = "8",
                    icon = Icons.Default.CheckCircle,
                    modifier = Modifier.weight(1f)
                )
            }
        }
        
        item {
            Spacer(modifier = Modifier.height(12.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                AndroidStatCard(
                    title = "Files",
                    value = "45",
                    icon = Icons.Default.Description,
                    modifier = Modifier.weight(1f)
                )
                AndroidStatCard(
                    title = "Counties",
                    value = "67",
                    icon = Icons.Default.LocationOn,
                    modifier = Modifier.weight(1f)
                )
            }
        }
        
        item {
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = "Quick Actions",
                style = MaterialTheme.typography.h6,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }
        
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                AndroidQuickActionCard(
                    title = "New Permit",
                    icon = Icons.Default.Add,
                    modifier = Modifier.weight(1f)
                )
                AndroidQuickActionCard(
                    title = "Upload",
                    icon = Icons.Default.CloudUpload,
                    modifier = Modifier.weight(1f)
                )
            }
        }
        
        item {
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = "Recent Activity",
                style = MaterialTheme.typography.h6,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }
        
        items(3) { index ->
            AndroidActivityItem(
                title = "Permit Updated",
                description = "Building permit for Miami-Dade County",
                time = "${index + 1} hour${if (index == 0) "" else "s"} ago",
                icon = Icons.Default.Update
            )
        }
    }
}

@Composable
fun AndroidCountiesTab(
    selectedCounty: String?,
    onCountySelected: (String?) -> Unit
) {
    val floridaCounties = listOf(
        "Alachua County", "Baker County", "Bay County", "Bradford County", "Brevard County",
        "Broward County", "Calhoun County", "Charlotte County", "Citrus County", "Clay County",
        "Collier County", "Columbia County", "DeSoto County", "Dixie County", "Duval County",
        "Escambia County", "Flagler County", "Franklin County", "Gadsden County", "Gilchrist County",
        "Glades County", "Gulf County", "Hamilton County", "Hardee County", "Hendry County",
        "Hernando County", "Highlands County", "Hillsborough County", "Holmes County", "Indian River County",
        "Jackson County", "Jefferson County", "Lafayette County", "Lake County", "Lee County",
        "Leon County", "Levy County", "Liberty County", "Madison County", "Manatee County",
        "Marion County", "Martin County", "Miami-Dade County", "Monroe County", "Nassau County",
        "Okaloosa County", "Okeechobee County", "Orange County", "Osceola County", "Palm Beach County",
        "Pasco County", "Pinellas County", "Polk County", "Putnam County", "Santa Rosa County",
        "Sarasota County", "Seminole County", "St. Johns County", "St. Lucie County", "Sumter County",
        "Suwannee County", "Taylor County", "Union County", "Volusia County", "Wakulla County",
        "Walton County", "Washington County"
    )
    
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp)
    ) {
        item {
            Text(
                text = "Florida Counties",
                style = MaterialTheme.typography.h5,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            
            Text(
                text = "Select a county to view requirements",
                style = MaterialTheme.typography.body2,
                color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f),
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }
        
        items(floridaCounties) { county ->
            AndroidCountyItem(
                county = county,
                isSelected = county == selectedCounty,
                onClick = { onCountySelected(county) }
            )
        }
    }
}

@Composable
fun AndroidDocumentsTab(
    selectedFiles: List<File>,
    onFilesSelected: (List<File>) -> Unit
) {
    var showFilePicker by remember { mutableStateOf(false) }
    
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp)
    ) {
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Documents",
                    style = MaterialTheme.typography.h5,
                    fontWeight = FontWeight.Bold
                )
                
                FloatingActionButton(
                    onClick = { showFilePicker = true },
                    backgroundColor = MaterialTheme.colors.primary
                ) {
                    Icon(Icons.Default.Add, "Add Files")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
        }
        
        if (selectedFiles.isEmpty()) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    elevation = 2.dp,
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.CloudUpload,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colors.onSurface.copy(alpha = 0.5f)
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = "No documents",
                            style = MaterialTheme.typography.h6,
                            color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
                        )
                        
                        Text(
                            text = "Tap + to upload your first document",
                            style = MaterialTheme.typography.body2,
                            color = MaterialTheme.colors.onSurface.copy(alpha = 0.5f)
                        )
                    }
                }
            }
        } else {
            items(selectedFiles) { file ->
                AndroidDocumentItem(
                    file = file,
                    onRemove = {
                        onFilesSelected(selectedFiles.filter { it != file })
                    }
                )
            }
        }
    }
    
    if (showFilePicker) {
        // File picker would be implemented here
        LaunchedEffect(Unit) {
            kotlinx.coroutines.delay(100)
            onFilesSelected(listOf(File("sample-document.pdf")))
            showFilePicker = false
        }
    }
}

@Composable
fun AndroidProfileTab(user: AndroidUser) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp)
    ) {
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = 4.dp,
                shape = RoundedCornerShape(20.dp)
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        modifier = Modifier.size(80.dp),
                        tint = MaterialTheme.colors.primary
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = "${user.firstName} ${user.lastName}",
                        style = MaterialTheme.typography.h5,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Text(
                        text = user.email,
                        style = MaterialTheme.typography.body1,
                        color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
        }
        
        item {
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = "Account Settings",
                style = MaterialTheme.typography.h6,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }
        
        item {
            AndroidSettingsSection(title = "Preferences") {
                AndroidSettingsItem(
                    icon = Icons.Default.Notifications,
                    title = "Notifications",
                    subtitle = "Enabled"
                )
                AndroidSettingsItem(
                    icon = Icons.Default.Security,
                    title = "Security",
                    subtitle = "JWT Authentication"
                )
                AndroidSettingsItem(
                    icon = Icons.Default.Language,
                    title = "Language",
                    subtitle = "English"
                )
            }
        }
        
        item {
            Spacer(modifier = Modifier.height(16.dp))
            AndroidSettingsSection(title = "App Info") {
                AndroidSettingsItem(
                    icon = Icons.Default.Info,
                    title = "Version",
                    subtitle = "1.0.0 Production"
                )
                AndroidSettingsItem(
                    icon = Icons.Default.Business,
                    title = "Company",
                    subtitle = "Permit Management System"
                )
            }
        }
    }
}

@Composable
fun AndroidStatCard(
    title: String,
    value: String,
    icon: ImageVector,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        elevation = 4.dp,
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(32.dp),
                tint = MaterialTheme.colors.primary
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = value,
                style = MaterialTheme.typography.h4,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colors.primary
            )
            
            Text(
                text = title,
                style = MaterialTheme.typography.body2,
                color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
fun AndroidQuickActionCard(
    title: String,
    icon: ImageVector,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        elevation = 2.dp,
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(32.dp),
                tint = MaterialTheme.colors.primary
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = title,
                style = MaterialTheme.typography.body2,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@Composable
fun AndroidActivityItem(
    title: String,
    description: String,
    time: String,
    icon: ImageVector
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        elevation = 2.dp,
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colors.primary
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.subtitle1,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = description,
                    style = MaterialTheme.typography.body2,
                    color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
                )
            }
            
            Text(
                text = time,
                style = MaterialTheme.typography.caption,
                color = MaterialTheme.colors.onSurface.copy(alpha = 0.5f)
            )
        }
    }
}

@Composable
fun AndroidCountyItem(
    county: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        elevation = if (isSelected) 8.dp else 2.dp,
        backgroundColor = if (isSelected) MaterialTheme.colors.primary else MaterialTheme.colors.surface,
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onClick() }
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.LocationOn,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = if (isSelected) MaterialTheme.colors.onPrimary else MaterialTheme.colors.primary
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Text(
                text = county,
                style = MaterialTheme.typography.subtitle1,
                fontWeight = FontWeight.Medium,
                color = if (isSelected) MaterialTheme.colors.onPrimary else MaterialTheme.colors.onSurface
            )
            
            if (isSelected) {
                Spacer(modifier = Modifier.weight(1f))
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = null,
                    tint = MaterialTheme.colors.onPrimary
                )
            }
        }
    }
}

@Composable
fun AndroidDocumentItem(file: File, onRemove: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        elevation = 2.dp,
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Description,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colors.primary
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = file.name,
                    style = MaterialTheme.typography.subtitle1,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = "${(file.length() / 1024 / 1024).toDouble().format(2)} MB",
                    style = MaterialTheme.typography.body2,
                    color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
                )
            }
            
            IconButton(onClick = onRemove) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = "Remove",
                    tint = MaterialTheme.colors.error
                )
            }
        }
    }
}

@Composable
fun AndroidSettingsSection(title: String, content: @Composable () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = 2.dp,
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.h6,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 16.dp)
            )
            content()
        }
    }
}

@Composable
fun AndroidSettingsItem(icon: ImageVector, title: String, subtitle: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(24.dp),
            tint = MaterialTheme.colors.primary
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.subtitle1,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.body2,
                color = MaterialTheme.colors.onSurface.copy(alpha = 0.7f)
            )
        }
        
        Icon(
            imageVector = Icons.Default.ChevronRight,
            contentDescription = null,
            tint = MaterialTheme.colors.onSurface.copy(alpha = 0.5f)
        )
    }
}

// Data classes
data class AndroidUser(
    val id: String,
    val firstName: String,
    val lastName: String,
    val email: String
)

enum class AndroidScreen {
    Login, Main
}

// Extension function for number formatting
fun Double.format(digits: Int) = "%.${digits}f".format(this)

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        title = "Permit Management System - Android",
        state = rememberWindowState(width = 400.dp, height = 800.dp)
    ) {
        AndroidApp()
    }
}
