// Enhanced Admin Dashboard JavaScript Functions

// Authentication Functions
async function checkExistingSession() {
    const token = localStorage.getItem('adminSessionToken');
    if (token) {
        try {
            const response = await fetch('http://localhost:8080/admin/auth/me', {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            
            if (response.ok) {
                const data = await response.json();
                currentUser = data.data;
                sessionToken = token;
                showDashboard();
                loadDashboardData();
            } else {
                localStorage.removeItem('adminSessionToken');
                showLogin();
            }
        } catch (error) {
            console.error('Session check failed:', error);
            showLogin();
        }
    } else {
        showLogin();
    }
}

async function login(email, password) {
    try {
        const response = await fetch('http://localhost:8080/admin/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password })
        });
        
        const data = await response.json();
        
        if (data.success) {
            currentUser = data.user;
            sessionToken = data.sessionToken;
            localStorage.setItem('adminSessionToken', sessionToken);
            showDashboard();
            loadDashboardData();
            showNotification('Login successful!', 'success');
        } else {
            showNotification(data.message, 'error');
        }
    } catch (error) {
        console.error('Login failed:', error);
        showNotification('Login failed: ' + error.message, 'error');
    }
}

async function logout() {
    try {
        if (sessionToken) {
            await fetch('http://localhost:8080/admin/auth/logout', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${sessionToken}`
                }
            });
        }
    } catch (error) {
        console.error('Logout error:', error);
    } finally {
        localStorage.removeItem('adminSessionToken');
        currentUser = null;
        sessionToken = null;
        showLogin();
    }
}

// UI Functions
function showLogin() {
    document.getElementById('login-container').classList.remove('hidden');
    document.getElementById('admin-dashboard').classList.add('hidden');
}

function showDashboard() {
    document.getElementById('login-container').classList.add('hidden');
    document.getElementById('admin-dashboard').classList.remove('hidden');
    
    // Update user info
    if (currentUser) {
        document.getElementById('user-name').textContent = `${currentUser.firstName} ${currentUser.lastName}`;
        document.getElementById('user-role').textContent = currentUser.role;
        document.getElementById('user-avatar').textContent = currentUser.firstName.charAt(0);
    }
}

function showTab(tabName) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from all nav tabs
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Show selected tab
    document.getElementById(`${tabName}-tab`).classList.add('active');
    event.target.classList.add('active');
    
    // Load tab-specific data
    switch(tabName) {
        case 'counties':
            loadCounties();
            break;
        case 'bulk-ops':
            loadCountiesForBulkOps();
            break;
        case 'templates':
            loadTemplates();
            break;
        case 'documents':
            loadDocuments();
            break;
        case 'users':
            loadUsers();
            break;
        case 'audit':
            loadAuditLog();
            break;
    }
}

function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.classList.add('show');
    }, 100);
    
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 3000);
}

// Dashboard Data Loading
async function loadDashboardData() {
    try {
        // Load counties count
        const countiesResponse = await fetch('http://localhost:8080/counties');
        if (countiesResponse.ok) {
            const countiesData = await countiesResponse.json();
            document.getElementById('total-counties').textContent = countiesData.length;
            
            // Calculate total items
            let totalItems = 0;
            for (const county of countiesData) {
                const checklistResponse = await fetch(`http://localhost:8080/counties/${county.id}/checklist`);
                if (checklistResponse.ok) {
                    const checklistData = await checklistResponse.json();
                    const items = checklistData.success ? checklistData.data : checklistData;
                    totalItems += items.length;
                }
            }
            document.getElementById('total-items').textContent = totalItems;
        }
        
        // Load templates count
        const templatesResponse = await fetch('http://localhost:8080/admin/templates', {
            headers: { 'Authorization': `Bearer ${sessionToken}` }
        });
        if (templatesResponse.ok) {
            const templatesData = await templatesResponse.json();
            document.getElementById('total-templates').textContent = templatesData.data.length;
        }
        
        // Load documents count
        const documentsResponse = await fetch('http://localhost:8080/admin/documents', {
            headers: { 'Authorization': `Bearer ${sessionToken}` }
        });
        if (documentsResponse.ok) {
            const documentsData = await documentsResponse.json();
            document.getElementById('total-documents').textContent = documentsData.data.length;
        }
        
    } catch (error) {
        console.error('Error loading dashboard data:', error);
    }
}

// Counties Management
async function loadCounties() {
    try {
        const response = await fetch('http://localhost:8080/counties');
        if (response.ok) {
            counties = await response.json();
            displayCountiesGrid();
        }
    } catch (error) {
        console.error('Error loading counties:', error);
        showNotification('Failed to load counties', 'error');
    }
}

function displayCountiesGrid() {
    const grid = document.getElementById('counties-grid');
    grid.innerHTML = '';
    
    counties.forEach(county => {
        const card = document.createElement('div');
        card.className = 'stat-card';
        card.innerHTML = `
            <h4>${county.name}</h4>
            <p style="color: #666; margin: 10px 0;">${county.state}</p>
            <div style="margin-top: 15px;">
                <button class="btn" onclick="manageCountyChecklist(${county.id}, '${county.name}')">
                    Manage Checklist
                </button>
            </div>
        `;
        grid.appendChild(card);
    });
}

// Bulk Operations
async function loadCountiesForBulkOps() {
    try {
        const response = await fetch('http://localhost:8080/admin/bulk/counties-by-type', {
            headers: { 'Authorization': `Bearer ${sessionToken}` }
        });
        
        if (response.ok) {
            const data = await response.json();
            displayCountyCheckboxes(data.all);
        }
    } catch (error) {
        console.error('Error loading counties for bulk ops:', error);
    }
}

function displayCountyCheckboxes(countiesList) {
    const container = document.getElementById('county-checkboxes');
    container.innerHTML = '';
    
    countiesList.forEach(county => {
        const checkbox = document.createElement('label');
        checkbox.className = 'county-checkbox';
        checkbox.innerHTML = `
            <input type="checkbox" value="${county.id}" name="county-selection">
            ${county.name}
        `;
        container.appendChild(checkbox);
    });
}

function selectCountyType(type) {
    // This would select counties based on type (major, medium, small, all)
    const checkboxes = document.querySelectorAll('input[name="county-selection"]');
    
    if (type === 'all') {
        checkboxes.forEach(cb => cb.checked = true);
    } else if (type === 'major') {
        // Select major counties (Miami-Dade, Broward, etc.)
        const majorCountyIds = [6, 28, 43, 48, 50, 52];
        checkboxes.forEach(cb => {
            cb.checked = majorCountyIds.includes(parseInt(cb.value));
        });
    } else {
        // Implement other selections
        clearCountySelection();
    }
}

function clearCountySelection() {
    document.querySelectorAll('input[name="county-selection"]').forEach(cb => {
        cb.checked = false;
    });
}

async function performBulkAdd(formData) {
    const selectedCounties = Array.from(document.querySelectorAll('input[name="county-selection"]:checked'))
        .map(cb => parseInt(cb.value));
    
    if (selectedCounties.length === 0) {
        showNotification('Please select at least one county', 'error');
        return;
    }
    
    try {
        const response = await fetch('http://localhost:8080/admin/bulk/add-item', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${sessionToken}`
            },
            body: JSON.stringify({
                countyIds: selectedCounties,
                title: formData.get('title'),
                description: formData.get('description'),
                required: formData.has('required')
            })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showNotification(`Successfully added item to ${result.affectedCounties} counties`, 'success');
            document.getElementById('bulk-add-form').reset();
        } else {
            showNotification(`Bulk add failed: ${result.message}`, 'error');
        }
        
    } catch (error) {
        console.error('Bulk add error:', error);
        showNotification('Bulk add operation failed', 'error');
    }
}

// Templates Management
async function loadTemplates() {
    try {
        const response = await fetch('http://localhost:8080/admin/templates', {
            headers: { 'Authorization': `Bearer ${sessionToken}` }
        });
        
        if (response.ok) {
            const data = await response.json();
            displayTemplates(data.data);
        }
    } catch (error) {
        console.error('Error loading templates:', error);
    }
}

function displayTemplates(templates) {
    const container = document.getElementById('templates-list');
    container.innerHTML = '';
    
    templates.forEach(template => {
        const card = document.createElement('div');
        card.className = 'template-card';
        card.onclick = () => selectTemplate(template);
        card.innerHTML = `
            <h4>${template.name}</h4>
            <p style="color: #666; margin: 10px 0;">${template.description}</p>
            <div style="font-size: 14px; color: #888;">
                Category: ${template.category} | ${template.items.length} items
            </div>
        `;
        container.appendChild(card);
    });
}

function selectTemplate(template) {
    selectedTemplate = template;
    
    // Update UI to show selected template
    document.querySelectorAll('.template-card').forEach(card => {
        card.classList.remove('selected');
    });
    event.target.closest('.template-card').classList.add('selected');
    
    // Show application section
    document.getElementById('template-apply-section').classList.remove('hidden');
    
    // Load counties for template application
    loadCountiesForTemplateApplication();
}

async function loadCountiesForTemplateApplication() {
    try {
        const response = await fetch('http://localhost:8080/counties');
        if (response.ok) {
            const counties = await response.json();
            displayTemplateCountyCheckboxes(counties);
        }
    } catch (error) {
        console.error('Error loading counties for template:', error);
    }
}

function displayTemplateCountyCheckboxes(countiesList) {
    const container = document.getElementById('template-county-checkboxes');
    container.innerHTML = '';
    
    countiesList.forEach(county => {
        const checkbox = document.createElement('label');
        checkbox.className = 'county-checkbox';
        checkbox.innerHTML = `
            <input type="checkbox" value="${county.id}" name="template-county-selection">
            ${county.name}
        `;
        container.appendChild(checkbox);
    });
}

async function applySelectedTemplate() {
    if (!selectedTemplate) {
        showNotification('Please select a template first', 'error');
        return;
    }
    
    const selectedCounties = Array.from(document.querySelectorAll('input[name="template-county-selection"]:checked'))
        .map(cb => parseInt(cb.value));
    
    if (selectedCounties.length === 0) {
        showNotification('Please select at least one county', 'error');
        return;
    }
    
    const replaceExisting = document.getElementById('replace-existing').checked;
    
    try {
        const response = await fetch('http://localhost:8080/admin/templates/apply', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${sessionToken}`
            },
            body: JSON.stringify({
                templateId: selectedTemplate.id,
                countyIds: selectedCounties,
                replaceExisting: replaceExisting
            })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showNotification(`Template applied to ${result.affectedCounties} counties`, 'success');
            cancelTemplateApplication();
        } else {
            showNotification(`Template application failed: ${result.message}`, 'error');
        }
        
    } catch (error) {
        console.error('Template application error:', error);
        showNotification('Template application failed', 'error');
    }
}

function cancelTemplateApplication() {
    selectedTemplate = null;
    document.getElementById('template-apply-section').classList.add('hidden');
    document.querySelectorAll('.template-card').forEach(card => {
        card.classList.remove('selected');
    });
}

// Event Listeners
document.getElementById('login-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;
    
    document.getElementById('login-loading').classList.remove('hidden');
    document.getElementById('login-text').textContent = 'Logging in...';
    
    await login(email, password);
    
    document.getElementById('login-loading').classList.add('hidden');
    document.getElementById('login-text').textContent = 'Login';
});

document.getElementById('bulk-add-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    const formData = new FormData(this);
    await performBulkAdd(formData);
});

// Additional functions for documents, users, and audit log will be added in the next part
