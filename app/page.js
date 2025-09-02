'use client';

import { useState, useEffect } from 'react';
import LoginPage from '../components/LoginPage';
import Dashboard from '../components/Dashboard';
import PackageDetailView from '../components/PackageDetailView';
import CreatePackageModal from '../components/CreatePackageModal';
import { apiService } from '../lib/api';

export default function App() {
  const [user, setUser] = useState(null);
  const [packages, setPackages] = useState([]);
  const [selectedPackage, setSelectedPackage] = useState(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadPackages();
  }, []);

  const loadPackages = async () => {
    try {
      if (typeof window === 'undefined') {
        setLoading(false);
        return;
      }

      const token = localStorage.getItem('permitpro_token');
      if (!token) {
        setLoading(false);
        return;
      }

      const data = await apiService.getPermits();
      setPackages(data.packages || []);
      setUser(data.user || { name: 'User' });
    } catch (error) {
      console.error('Failed to load packages:', error);
      if (typeof window !== 'undefined') {
        localStorage.removeItem('permitpro_token');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = (userData) => {
    setUser(userData);
    loadPackages();
  };

  const handleLogout = () => {
    apiService.logout();
    setUser(null);
    setPackages([]);
    setSelectedPackage(null);
  };

  const handlePackageCreate = (newPackage) => {
    setPackages(prev => [newPackage, ...prev]);
  };

  const handlePackageUpdate = (updatedPackage) => {
    setPackages(prev => 
      prev.map(pkg => 
        pkg.id === updatedPackage.id ? updatedPackage : pkg
      )
    );
    setSelectedPackage(updatedPackage);
  };

  const handleSelectPackage = (packageData) => {
    setSelectedPackage(packageData);
  };

  const handleBackToDashboard = () => {
    setSelectedPackage(null);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading PermitPro...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <LoginPage onLogin={handleLogin} />;
  }

  if (selectedPackage) {
    return (
      <PackageDetailView
        packageData={selectedPackage}
        onBack={handleBackToDashboard}
        onUpdate={handlePackageUpdate}
      />
    );
  }

  return (
    <>
      <Dashboard
        packages={packages}
        onCreatePackage={() => setShowCreateModal(true)}
        onSelectPackage={handleSelectPackage}
        onLogout={handleLogout}
      />
      
      <CreatePackageModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onPackageCreated={handlePackageCreate}
      />
    </>
  );
}
