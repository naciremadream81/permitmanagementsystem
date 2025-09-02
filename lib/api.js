// API service for permit management
class ApiService {
  constructor() {
    this.baseURL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';
  }

  getToken() {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('permitpro_token');
    }
    return null;
  }

  setToken(token) {
    if (typeof window !== 'undefined') {
      localStorage.setItem('permitpro_token', token);
    }
  }

  removeToken() {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('permitpro_token');
    }
  }

  async request(endpoint, options = {}) {
    const token = this.getToken();
    
    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers,
      },
      ...options,
    };

    const response = await fetch(`${this.baseURL}${endpoint}`, config);
    
    if (!response.ok) {
      throw new Error(`API Error: ${response.statusText}`);
    }
    
    return response.json();
  }

  // Authentication
  async login(email, password) {
    const response = await this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    
    if (response.data && response.data.token) {
      this.setToken(response.data.token);
    }
    
    return response;
  }

  async logout() {
    this.removeToken();
  }

  // Permit packages
  async getPermits() {
    const response = await this.request('/packages');
    return {
      packages: response.data || [],
      user: response.user || { name: 'User' }
    };
  }

  async createPermit(packageData) {
    return this.request('/packages', {
      method: 'POST',
      body: JSON.stringify(packageData),
    });
  }

  async updatePackageStatus(packageId, status) {
    return this.request(`/packages/${packageId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  }

  async uploadDocument(packageId, documentData) {
    return this.request(`/packages/${packageId}/documents`, {
      method: 'POST',
      body: JSON.stringify(documentData),
    });
  }

  async uploadChecklistDocument(packageId, documentData) {
    return this.request(`/packages/${packageId}/checklist-documents`, {
      method: 'POST',
      body: JSON.stringify(documentData),
    });
  }

  // Additional endpoints for your Kotlin backend
  async getCounties() {
    return this.request('/counties');
  }

  async getChecklist(countyId, permitType = 'Building') {
    return this.request(`/checklists/${countyId}?permitType=${permitType}`);
  }
}

export const apiService = new ApiService();
