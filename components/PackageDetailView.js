'use client';

import { useState } from 'react';
import { Card, CardHeader, CardContent, Button, Badge, Modal, Input } from './ui';
import { ArrowLeft, Upload, Download, FileText, Calendar, MapPin, User } from 'lucide-react';
import { apiService } from '../lib/api';
import PermitChecklist from './PermitChecklist';

export default function PackageDetailView({ 
  packageData, 
  onBack, 
  onUpdate 
}) {

  const [loading, setLoading] = useState(false);

  const handleStatusChange = async (newStatus) => {
    setLoading(true);
    try {
      await apiService.updatePackageStatus(packageData.id, newStatus);
      onUpdate({ ...packageData, status: newStatus });
    } catch (error) {
      console.error('Failed to update status:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadAll = async () => {
    if (!packageData.documents || packageData.documents.length === 0) {
      alert('No documents to download');
      return;
    }

    setLoading(true);
    try {
      // Create a zip file name based on package info
      const zipFileName = `${packageData.customerName.replace(/\s+/g, '_')}_${packageData.permitNumber || packageData.id}_Documents.zip`;
      
      // In a real implementation, you would call an API endpoint that creates a zip file
      // For now, we'll simulate the download
      const response = await fetch(`http://localhost:3001/api/permits/${packageData.id}/download-all`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('permitpro_token')}`
        }
      });

      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = zipFileName;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      } else {
        throw new Error('Failed to download documents');
      }
    } catch (error) {
      console.error('Download error:', error);
      alert('Failed to download documents. Please try again.');
    } finally {
      setLoading(false);
    }
  };



  const getStatusVariant = (status) => {
    const variants = {
      'Draft': 'draft',
      'Submitted': 'submitted',
      'Completed': 'completed'
    };
    return variants[status] || 'default';
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center h-16">
            <Button variant="outline" onClick={onBack} className="mr-4">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Dashboard
            </Button>
            <h1 className="text-2xl font-bold text-gray-900">Package Details</h1>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Package Information */}
            <Card>
              <CardHeader>
                <div className="flex justify-between items-center">
                  <h2 className="text-lg font-semibold text-gray-900">Package Information</h2>
                  <Badge variant={getStatusVariant(packageData.status)}>
                    {packageData.status}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="flex items-start space-x-3">
                    <User className="h-5 w-5 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Customer Name</p>
                      <p className="text-base text-gray-900">{packageData.customerName}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start space-x-3">
                    <MapPin className="h-5 w-5 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Property Address</p>
                      <p className="text-base text-gray-900">{packageData.propertyAddress}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start space-x-3">
                    <div className="h-5 w-5 bg-primary-100 rounded mt-0.5 flex items-center justify-center">
                      <div className="h-2 w-2 bg-primary-600 rounded"></div>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-500">County</p>
                      <p className="text-base text-gray-900">{packageData.county}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start space-x-3">
                    <Calendar className="h-5 w-5 text-gray-400 mt-0.5" />
                    <div>
                      <p className="text-sm font-medium text-gray-500">Created Date</p>
                      <p className="text-base text-gray-900">
                        {new Date(packageData.createdAt).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Permit Checklist */}
            <PermitChecklist 
              packageData={packageData} 
              onUpdate={onUpdate}
            />
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Status Management */}
            <Card>
              <CardHeader>
                <h3 className="text-lg font-semibold text-gray-900">Status Management</h3>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {['Draft', 'Submitted', 'Completed'].map((status) => (
                    <Button
                      key={status}
                      variant={packageData.status === status ? 'primary' : 'outline'}
                      className="w-full justify-start"
                      onClick={() => handleStatusChange(status)}
                      disabled={loading}
                    >
                      {status}
                    </Button>
                  ))}
                </div>
              </CardContent>
            </Card>

            {/* Quick Actions */}
            <Card>
              <CardHeader>
                <h3 className="text-lg font-semibold text-gray-900">Quick Actions</h3>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <Button variant="outline" className="w-full justify-start">
                    Generate Report
                  </Button>
                  <Button variant="outline" className="w-full justify-start">
                    Send Notification
                  </Button>
                  <Button variant="outline" className="w-full justify-start">
                    Export Data
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>


    </div>
  );
}
