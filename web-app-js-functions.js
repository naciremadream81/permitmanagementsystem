// Tab management
function showTab(tabName) {
    // Hide all tab contents
    const tabContents = document.querySelectorAll('.tab-content');
    tabContents.forEach(tab => tab.classList.remove('active'));
    
    // Remove active class from all tabs
    const tabs = document.querySelectorAll('.nav-tab');
    tabs.forEach(tab => tab.classList.remove('active'));
    
    // Show selected tab content
    document.getElementById(tabName + '-tab').classList.add('active');
    
    // Add active class to selected tab
    event.target.classList.add('active');
    
    // Load tab-specific data
    if (tabName === 'dashboard') {
        loadDashboard();
    } else if (tabName === 'my-permits') {
        loadUserPermits();
    }
}

// Load counties from API
async function loadCounties() {
    try {
        const response = await fetch(`${API_BASE}/counties`);
        const data = await response.json();
        
        if (response.ok) {
            counties = data;
            populateCountySelect();
        } else {
            console.error('Failed to load counties');
        }
    } catch (error) {
        console.error('Error loading counties:', error);
    }
}

function populateCountySelect() {
    const select = document.getElementById('permit-county');
    select.innerHTML = '<option value="">Choose a county...</option>';
    
    counties.forEach(county => {
        const option = document.createElement('option');
        option.value = county.id;
        option.textContent = `${county.name}, ${county.state}`;
        select.appendChild(option);
    });
}

// Dashboard functions
async function loadDashboard() {
    try {
        const response = await fetch(`${API_BASE}/packages`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            const permits = await response.json();
            updateDashboardStats(permits);
            updateRecentActivity(permits);
        }
    } catch (error) {
        console.error('Error loading dashboard:', error);
    }
}

function updateDashboardStats(permits) {
    const total = permits.length;
    const inProgress = permits.filter(p => p.status === 'in_progress' || p.status === 'submitted').length;
    const approved = permits.filter(p => p.status === 'approved').length;
    
    document.getElementById('total-permits').textContent = total;
    document.getElementById('in-progress-permits').textContent = inProgress;
    document.getElementById('approved-permits').textContent = approved;
}

function updateRecentActivity(permits) {
    const activityList = document.getElementById('activity-list');
    
    if (permits.length === 0) {
        activityList.innerHTML = '<p style="color: #64748b; text-align: center; padding: 2rem;">No permits created yet</p>';
        return;
    }
    
    // Sort by creation date (most recent first)
    const recentPermits = permits
        .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
        .slice(0, 5);
    
    activityList.innerHTML = recentPermits.map(permit => `
        <div style="padding: 1rem; border-left: 3px solid #3b82f6; margin-bottom: 1rem; background: #f8fafc;">
            <h4 style="margin-bottom: 0.5rem;">${permit.name}</h4>
            <p style="color: #64748b; margin-bottom: 0.5rem;">${permit.description}</p>
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <span class="status-badge status-${permit.status}">${formatStatus(permit.status)}</span>
                <small style="color: #64748b;">${formatDate(permit.createdAt)}</small>
            </div>
        </div>
    `).join('');
}

// Permit management functions
async function loadUserPermits() {
    const permitsList = document.getElementById('permits-list');
    permitsList.innerHTML = '<div class="loading" style="margin: 2rem auto; display: block;"></div>';
    
    try {
        const response = await fetch(`${API_BASE}/packages`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            userPermits = await response.json();
            displayUserPermits();
        } else {
            permitsList.innerHTML = '<p style="color: #ef4444; text-align: center; padding: 2rem;">Failed to load permits</p>';
        }
    } catch (error) {
        console.error('Error loading permits:', error);
        permitsList.innerHTML = '<p style="color: #ef4444; text-align: center; padding: 2rem;">Error loading permits</p>';
    }
}

function displayUserPermits() {
    const permitsList = document.getElementById('permits-list');
    
    if (userPermits.length === 0) {
        permitsList.innerHTML = `
            <div style="text-align: center; padding: 3rem; color: #64748b;">
                <h3>No permits created yet</h3>
                <p style="margin: 1rem 0;">Create your first permit package to get started.</p>
                <button class="btn btn-primary" onclick="showTab('new-permit')">Create New Permit</button>
            </div>
        `;
        return;
    }
    
    permitsList.innerHTML = `
        <div class="permit-grid">
            ${userPermits.map(permit => createPermitCard(permit)).join('')}
        </div>
    `;
}

function createPermitCard(permit) {
    const county = counties.find(c => c.id === permit.countyId);
    const countyName = county ? `${county.name}, ${county.state}` : 'Unknown County';
    
    return `
        <div class="permit-card" onclick="openPermitDetails(${permit.id})">
            <h3>${permit.name}</h3>
            <p><strong>County:</strong> ${countyName}</p>
            <p><strong>Description:</strong> ${permit.description}</p>
            <p><strong>Created:</strong> ${formatDate(permit.createdAt)}</p>
            <div style="margin: 1rem 0;">
                <span class="status-badge status-${permit.status}">${formatStatus(permit.status)}</span>
            </div>
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${calculateProgress(permit.status)}%"></div>
            </div>
            <div style="margin-top: 1rem; display: flex; gap: 0.5rem;">
                <button class="btn btn-primary" onclick="event.stopPropagation(); openPermitDetails(${permit.id})" style="font-size: 0.875rem; padding: 0.5rem 1rem;">View Details</button>
                <button class="btn btn-secondary" onclick="event.stopPropagation(); manageDocuments(${permit.id})" style="font-size: 0.875rem; padding: 0.5rem 1rem;">Documents</button>
            </div>
        </div>
    `;
}

// Create new permit
document.getElementById('new-permit-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const formData = {
        countyId: parseInt(document.getElementById('permit-county').value),
        name: document.getElementById('permit-name').value,
        description: document.getElementById('permit-description').value,
        address: document.getElementById('permit-address').value,
        type: document.getElementById('permit-type').value
    };
    
    if (!formData.countyId || !formData.name || !formData.description) {
        showAlert('Please fill in all required fields', 'error');
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/packages`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (response.ok) {
            showAlert('Permit package created successfully!', 'success');
            // Clear form
            document.getElementById('new-permit-form').reset();
            // Refresh permits list
            loadUserPermits();
            // Switch to permits tab
            showTab('my-permits');
        } else {
            showAlert(data.message || 'Failed to create permit package', 'error');
        }
    } catch (error) {
        console.error('Error creating permit:', error);
        showAlert('Failed to create permit package', 'error');
    }
});

// Permit details modal
async function openPermitDetails(permitId) {
    try {
        const response = await fetch(`${API_BASE}/packages/${permitId}`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            const permit = await response.json();
            currentPermit = permit;
            displayPermitDetails(permit);
            document.getElementById('permit-modal').style.display = 'block';
        } else {
            showAlert('Failed to load permit details', 'error');
        }
    } catch (error) {
        console.error('Error loading permit details:', error);
        showAlert('Error loading permit details', 'error');
    }
}

async function displayPermitDetails(permit) {
    const county = counties.find(c => c.id === permit.countyId);
    const countyName = county ? `${county.name}, ${county.state}` : 'Unknown County';
    
    // Load checklist for this county
    let checklist = [];
    try {
        const checklistResponse = await fetch(`${API_BASE}/counties/${permit.countyId}/checklist`);
        if (checklistResponse.ok) {
            checklist = await checklistResponse.json();
        }
    } catch (error) {
        console.error('Error loading checklist:', error);
    }
    
    // Load documents for this permit
    let documents = [];
    try {
        const documentsResponse = await fetch(`${API_BASE}/packages/${permit.id}/documents`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        if (documentsResponse.ok) {
            documents = await documentsResponse.json();
        }
    } catch (error) {
        console.error('Error loading documents:', error);
    }
    
    const content = document.getElementById('permit-details-content');
    content.innerHTML = `
        <h2>${permit.name}</h2>
        <div style="margin-bottom: 2rem;">
            <p><strong>County:</strong> ${countyName}</p>
            <p><strong>Description:</strong> ${permit.description}</p>
            <p><strong>Status:</strong> <span class="status-badge status-${permit.status}">${formatStatus(permit.status)}</span></p>
            <p><strong>Created:</strong> ${formatDate(permit.createdAt)}</p>
            <p><strong>Last Updated:</strong> ${formatDate(permit.updatedAt)}</p>
        </div>
        
        <div style="margin-bottom: 2rem;">
            <h3>Progress</h3>
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${calculateProgress(permit.status)}%"></div>
            </div>
            <p style="color: #64748b; margin-top: 0.5rem;">${calculateProgress(permit.status)}% Complete</p>
        </div>
        
        <div style="margin-bottom: 2rem;">
            <h3>Required Documents Checklist</h3>
            <div id="checklist-items">
                ${checklist.map(item => {
                    const hasDocument = documents.some(doc => doc.checklistItemId === item.id);
                    return `
                        <div class="checklist-item ${hasDocument ? 'completed' : ''}">
                            <input type="checkbox" ${hasDocument ? 'checked' : ''} disabled>
                            <div style="flex: 1;">
                                <strong>${item.title}</strong>
                                <p style="color: #64748b; margin: 0.25rem 0;">${item.description}</p>
                                ${item.required ? '<span style="color: #ef4444; font-size: 0.875rem;">Required</span>' : '<span style="color: #64748b; font-size: 0.875rem;">Optional</span>'}
                            </div>
                            ${!hasDocument ? `<button class="btn btn-primary" onclick="uploadDocument(${item.id})" style="font-size: 0.875rem; padding: 0.5rem 1rem;">Upload</button>` : '<span style="color: #10b981;">✓ Uploaded</span>'}
                        </div>
                    `;
                }).join('')}
            </div>
        </div>
        
        <div style="margin-bottom: 2rem;">
            <h3>Uploaded Documents</h3>
            <div id="documents-list">
                ${documents.length > 0 ? documents.map(doc => `
                    <div style="display: flex; justify-content: space-between; align-items: center; padding: 1rem; border: 1px solid #e2e8f0; border-radius: 8px; margin-bottom: 0.5rem;">
                        <div>
                            <strong>${doc.filename}</strong>
                            <p style="color: #64748b; margin: 0;">Uploaded: ${formatDate(doc.uploadedAt)}</p>
                        </div>
                        <div>
                            <button class="btn btn-secondary" onclick="downloadDocument(${doc.id})" style="font-size: 0.875rem; padding: 0.5rem 1rem; margin-right: 0.5rem;">Download</button>
                            <button class="btn btn-danger" onclick="deleteDocument(${doc.id})" style="font-size: 0.875rem; padding: 0.5rem 1rem;">Delete</button>
                        </div>
                    </div>
                `).join('') : '<p style="color: #64748b; text-align: center; padding: 2rem;">No documents uploaded yet</p>'}
            </div>
        </div>
        
        <div style="display: flex; gap: 1rem; margin-top: 2rem;">
            <button class="btn btn-primary" onclick="updatePermitStatus()">Update Status</button>
            <button class="btn btn-secondary" onclick="closePermitModal()">Close</button>
        </div>
    `;
}

function closePermitModal() {
    document.getElementById('permit-modal').style.display = 'none';
    currentPermit = null;
}

// Document management
function manageDocuments(permitId) {
    const permit = userPermits.find(p => p.id === permitId);
    if (permit) {
        currentPermit = permit;
        showTab('documents');
        loadDocumentsTab(permitId);
    }
}

async function loadDocumentsTab(permitId) {
    const documentsContent = document.getElementById('documents-content');
    documentsContent.innerHTML = '<div class="loading" style="margin: 2rem auto; display: block;"></div>';
    
    try {
        // Load permit details
        const permitResponse = await fetch(`${API_BASE}/packages/${permitId}`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (!permitResponse.ok) {
            throw new Error('Failed to load permit details');
        }
        
        const permit = await permitResponse.json();
        
        // Load checklist
        const checklistResponse = await fetch(`${API_BASE}/counties/${permit.countyId}/checklist`);
        const checklist = checklistResponse.ok ? await checklistResponse.json() : [];
        
        // Load documents
        const documentsResponse = await fetch(`${API_BASE}/packages/${permitId}/documents`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        const documents = documentsResponse.ok ? await documentsResponse.json() : [];
        
        displayDocumentsTab(permit, checklist, documents);
        
    } catch (error) {
        console.error('Error loading documents tab:', error);
        documentsContent.innerHTML = '<p style="color: #ef4444; text-align: center; padding: 2rem;">Error loading documents</p>';
    }
}

function displayDocumentsTab(permit, checklist, documents) {
    const county = counties.find(c => c.id === permit.countyId);
    const countyName = county ? `${county.name}, ${county.state}` : 'Unknown County';
    
    const documentsContent = document.getElementById('documents-content');
    documentsContent.innerHTML = `
        <div style="background: #f8fafc; padding: 1.5rem; border-radius: 8px; margin-bottom: 2rem;">
            <h3>${permit.name}</h3>
            <p><strong>County:</strong> ${countyName}</p>
            <p><strong>Status:</strong> <span class="status-badge status-${permit.status}">${formatStatus(permit.status)}</span></p>
        </div>
        
        <div style="margin-bottom: 2rem;">
            <h3>Document Requirements</h3>
            <div id="documents-checklist">
                ${checklist.map(item => {
                    const hasDocument = documents.some(doc => doc.checklistItemId === item.id);
                    return `
                        <div class="checklist-item ${hasDocument ? 'completed' : ''}">
                            <input type="checkbox" ${hasDocument ? 'checked' : ''} disabled>
                            <div style="flex: 1;">
                                <strong>${item.title}</strong>
                                <p style="color: #64748b; margin: 0.25rem 0;">${item.description}</p>
                                ${item.required ? '<span style="color: #ef4444; font-size: 0.875rem;">Required</span>' : '<span style="color: #64748b; font-size: 0.875rem;">Optional</span>'}
                            </div>
                            ${!hasDocument ? `
                                <div>
                                    <input type="file" id="file-${item.id}" style="display: none;" onchange="handleFileUpload(${item.id}, this)">
                                    <button class="btn btn-primary" onclick="document.getElementById('file-${item.id}').click()" style="font-size: 0.875rem; padding: 0.5rem 1rem;">Upload File</button>
                                </div>
                            ` : '<span style="color: #10b981;">✓ Uploaded</span>'}
                        </div>
                    `;
                }).join('')}
            </div>
        </div>
        
        <div>
            <h3>Uploaded Documents</h3>
            <div id="uploaded-documents">
                ${documents.length > 0 ? documents.map(doc => `
                    <div style="display: flex; justify-content: space-between; align-items: center; padding: 1rem; border: 1px solid #e2e8f0; border-radius: 8px; margin-bottom: 0.5rem;">
                        <div>
                            <strong>${doc.filename}</strong>
                            <p style="color: #64748b; margin: 0;">Uploaded: ${formatDate(doc.uploadedAt)}</p>
                        </div>
                        <div>
                            <button class="btn btn-secondary" onclick="downloadDocument(${doc.id})" style="font-size: 0.875rem; padding: 0.5rem 1rem; margin-right: 0.5rem;">Download</button>
                            <button class="btn btn-danger" onclick="deleteDocument(${doc.id})" style="font-size: 0.875rem; padding: 0.5rem 1rem;">Delete</button>
                        </div>
                    </div>
                `).join('') : '<p style="color: #64748b; text-align: center; padding: 2rem;">No documents uploaded yet</p>'}
            </div>
        </div>
    `;
}

// File upload handling
async function handleFileUpload(checklistItemId, fileInput) {
    const file = fileInput.files[0];
    if (!file) return;
    
    if (!currentPermit) {
        showAlert('No permit selected', 'error');
        return;
    }
    
    const formData = new FormData();
    formData.append('file', file);
    formData.append('checklistItemId', checklistItemId);
    
    try {
        const response = await fetch(`${API_BASE}/packages/${currentPermit.id}/documents`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`
            },
            body: formData
        });
        
        if (response.ok) {
            showAlert('Document uploaded successfully!', 'success');
            // Refresh the documents tab
            loadDocumentsTab(currentPermit.id);
        } else {
            const error = await response.json();
            showAlert(error.message || 'Failed to upload document', 'error');
        }
    } catch (error) {
        console.error('Error uploading document:', error);
        showAlert('Failed to upload document', 'error');
    }
}

async function deleteDocument(documentId) {
    if (!confirm('Are you sure you want to delete this document?')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/packages/${currentPermit.id}/documents/${documentId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            showAlert('Document deleted successfully!', 'success');
            // Refresh the documents tab
            loadDocumentsTab(currentPermit.id);
        } else {
            showAlert('Failed to delete document', 'error');
        }
    } catch (error) {
        console.error('Error deleting document:', error);
        showAlert('Failed to delete document', 'error');
    }
}

function downloadDocument(documentId) {
    window.open(`${API_BASE}/packages/${currentPermit.id}/documents/${documentId}/download`, '_blank');
}

// Utility functions
function formatStatus(status) {
    const statusMap = {
        'draft': 'Draft',
        'submitted': 'Submitted',
        'in_progress': 'In Progress',
        'approved': 'Approved',
        'rejected': 'Rejected'
    };
    return statusMap[status] || status;
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function calculateProgress(status) {
    const progressMap = {
        'draft': 20,
        'submitted': 40,
        'in_progress': 70,
        'approved': 100,
        'rejected': 0
    };
    return progressMap[status] || 0;
}

function showAlert(message, type) {
    const alertContainer = document.getElementById('alert-container');
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type}`;
    alertDiv.textContent = message;
    
    alertContainer.appendChild(alertDiv);
    
    // Remove alert after 5 seconds
    setTimeout(() => {
        alertDiv.remove();
    }, 5000);
}

// Close modal when clicking outside
window.onclick = function(event) {
    const modal = document.getElementById('permit-modal');
    if (event.target === modal) {
        closePermitModal();
    }
}
