'use client';

import { useState, useEffect } from 'react';
import { Card, CardHeader, CardContent, Button, Badge, Modal, Input, Progress } from './ui';
import { Upload, CheckCircle, Circle, FileText, AlertCircle, Download, Eye } from 'lucide-react';
import { apiService } from '../lib/api';

export default function PermitChecklist({ 
  packageData, 
  onUpdate 
}) {
  const [checklist, setChecklist] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const [uploadData, setUploadData] = useState({ name: '', file: null });
  const [uploading, setUploading] = useState(false);

  // Load checklist when component mounts or package changes
  useEffect(() => {
    loadChecklist();
  }, [packageData.county, packageData.permitType]);

  const loadChecklist = async () => {
    setLoading(true);
    try {
      // Get county-specific checklist with permit type
      const permitType = packageData.permitType || 'Building';
      const response = await apiService.getChecklist(packageData.countyId || 1, permitType);
      let checklistItems = response.data || [];

      // If no data from API, use local customization
      if (!checklistItems || checklistItems.length === 0) {
        checklistItems = customizeChecklistForPermitType([], permitType);
      }

      // Add existing documents to checklist items
      const checklistWithDocuments = checklistItems.map(item => {
        const existingDocs = (packageData.documents || []).filter(doc => 
          doc.checklistItemId === item.id
        );
        return {
          ...item,
          documents: existingDocs,
          completed: existingDocs.length > 0,
          progress: existingDocs.length > 0 ? 100 : 0
        };
      });

      setChecklist(checklistWithDocuments);
    } catch (error) {
      console.error('Failed to load checklist:', error);
      // Fallback to default checklist
      setChecklist(getDefaultChecklist());
    } finally {
      setLoading(false);
    }
  };

  const customizeChecklistForPermitType = (baseChecklist, permitType) => {
    const permitTypeConfigs = {
      'Building': [
        { name: 'Building Permit Application', required: true, description: 'Complete building permit application form' },
        { name: 'Site Plan', required: true, description: 'Detailed site plan showing property boundaries and proposed construction' },
        { name: 'Structural Plans', required: true, description: 'Architectural and structural engineering plans' },
        { name: 'Electrical Plans', required: true, description: 'Electrical system design and layout plans' },
        { name: 'Plumbing Plans', required: true, description: 'Plumbing system design and layout plans' },
        { name: 'HVAC Plans', required: false, description: 'Heating, ventilation, and air conditioning plans' },
        { name: 'Fire Safety Plans', required: true, description: 'Fire safety and emergency exit plans' },
        { name: 'Environmental Impact Assessment', required: false, description: 'Environmental impact study if required' }
      ],
      'Electrical': [
        { name: 'Electrical Permit Application', required: true, description: 'Complete electrical permit application form' },
        { name: 'Electrical Load Calculation', required: true, description: 'Electrical load calculations and panel schedules' },
        { name: 'Electrical Plans', required: true, description: 'Detailed electrical system plans and schematics' },
        { name: 'Equipment Specifications', required: true, description: 'Specifications for electrical equipment and fixtures' },
        { name: 'Grounding Plan', required: true, description: 'Electrical grounding and bonding plan' }
      ],
      'Plumbing': [
        { name: 'Plumbing Permit Application', required: true, description: 'Complete plumbing permit application form' },
        { name: 'Plumbing Plans', required: true, description: 'Detailed plumbing system plans and layouts' },
        { name: 'Fixture Schedule', required: true, description: 'Schedule of all plumbing fixtures and equipment' },
        { name: 'Water Supply Plan', required: true, description: 'Water supply and distribution plan' },
        { name: 'Drainage Plan', required: true, description: 'Waste and drainage system plan' }
      ],
      'Demolition': [
        { name: 'Demolition Permit Application', required: true, description: 'Complete demolition permit application form' },
        { name: 'Asbestos Survey', required: true, description: 'Asbestos inspection and abatement plan' },
        { name: 'Demolition Plan', required: true, description: 'Detailed demolition sequence and safety plan' },
        { name: 'Environmental Assessment', required: true, description: 'Environmental impact assessment for demolition' },
        { name: 'Utility Disconnection Plan', required: true, description: 'Plan for disconnecting utilities' }
      ]
    };

    const config = permitTypeConfigs[permitType] || permitTypeConfigs['Building'];
    return config.map((item, index) => ({
      id: index + 1,
      name: item.name,
      required: item.required,
      description: item.description,
      permitType: permitType
    }));
  };

  const getDefaultChecklist = () => {
    return [
      { id: 1, name: 'Building Permit Application', required: true, description: 'Complete building permit application form', documents: [], completed: false, progress: 0 },
      { id: 2, name: 'Site Plan', required: true, description: 'Detailed site plan showing property boundaries', documents: [], completed: false, progress: 0 },
      { id: 3, name: 'Structural Plans', required: true, description: 'Architectural and structural engineering plans', documents: [], completed: false, progress: 0 },
      { id: 4, name: 'Electrical Plans', required: false, description: 'Electrical system design and layout plans', documents: [], completed: false, progress: 0 },
      { id: 5, name: 'Plumbing Plans', required: false, description: 'Plumbing system design and layout plans', documents: [], completed: false, progress: 0 }
    ];
  };

  const handleUploadDocument = async (e) => {
    e.preventDefault();
    if (!uploadData.file || !selectedItem) return;

    setUploading(true);
    try {
      const documentData = {
        name: uploadData.name || uploadData.file.name,
        filename: uploadData.file.name,
        size: uploadData.file.size,
        checklistItemId: selectedItem.id,
        checklistItemName: selectedItem.name,
        packageId: packageData.id,
        uploadedAt: new Date().toISOString()
      };
      
      await apiService.uploadChecklistDocument(packageData.id, documentData);
      
      // Update local state
      const updatedChecklist = checklist.map(item => {
        if (item.id === selectedItem.id) {
          const newDocuments = [...(item.documents || []), documentData];
          return {
            ...item,
            documents: newDocuments,
            completed: newDocuments.length > 0,
            progress: 100
          };
        }
        return item;
      });
      
      setChecklist(updatedChecklist);
      
      // Update package data
      const updatedPackage = {
        ...packageData,
        documents: [...(packageData.documents || []), documentData]
      };
      onUpdate(updatedPackage);
      
      setShowUploadModal(false);
      setSelectedItem(null);
      setUploadData({ name: '', file: null });
    } catch (error) {
      console.error('Failed to upload document:', error);
      alert('Failed to upload document. Please try again.');
    } finally {
      setUploading(false);
    }
  };

  const openUploadModal = (item) => {
    setSelectedItem(item);
    setShowUploadModal(true);
  };

  const getProgressPercentage = () => {
    if (checklist.length === 0) return 0;
    const completedItems = checklist.filter(item => item.completed).length;
    return Math.round((completedItems / checklist.length) * 100);
  };

  const getRequiredItemsProgress = () => {
    const requiredItems = checklist.filter(item => item.required);
    if (requiredItems.length === 0) return 100;
    const completedRequired = requiredItems.filter(item => item.completed).length;
    return Math.round((completedRequired / requiredItems.length) * 100);
  };

  const canSubmit = () => {
    const requiredItems = checklist.filter(item => item.required);
    return requiredItems.every(item => item.completed);
  };

  const getStatusVariant = (item) => {
    if (item.completed) return 'completed';
    if (item.required) return 'required';
    return 'optional';
  };

  if (loading) {
    return (
      <Card>
        <CardContent>
          <div className="flex items-center justify-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <span className="ml-2 text-gray-600">Loading checklist...</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Progress Overview */}
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <h2 className="text-lg font-semibold text-gray-900">Permit Checklist Progress</h2>
            <Badge variant={canSubmit() ? 'completed' : 'draft'}>
              {canSubmit() ? 'Ready to Submit' : 'In Progress'}
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-sm text-gray-600 mb-1">
                <span>Overall Progress</span>
                <span>{getProgressPercentage()}%</span>
              </div>
              <Progress value={getProgressPercentage()} className="h-2" />
            </div>
            
            <div>
              <div className="flex justify-between text-sm text-gray-600 mb-1">
                <span>Required Items</span>
                <span>{getRequiredItemsProgress()}%</span>
              </div>
              <Progress value={getRequiredItemsProgress()} className="h-2" />
            </div>
            
            <div className="text-sm text-gray-500">
              {checklist.filter(item => item.completed).length} of {checklist.length} items completed
              {checklist.filter(item => item.required && !item.completed).length > 0 && (
                <span className="text-red-600 ml-2">
                  ({checklist.filter(item => item.required && !item.completed).length} required items remaining)
                </span>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Checklist Items */}
      <Card>
        <CardHeader>
          <h2 className="text-lg font-semibold text-gray-900">
            Required Documents
            {packageData.permitType && (
              <span className="text-sm font-normal text-gray-500 ml-2">
                for {packageData.permitType} Permit
              </span>
            )}
          </h2>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {checklist.map((item) => (
              <div key={item.id} className="border border-gray-200 rounded-lg p-4">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      {item.completed ? (
                        <CheckCircle className="h-5 w-5 text-green-600" />
                      ) : (
                        <Circle className="h-5 w-5 text-gray-400" />
                      )}
                      <h3 className="text-base font-medium text-gray-900">{item.name}</h3>
                      <Badge variant={getStatusVariant(item)}>
                        {item.required ? 'Required' : 'Optional'}
                      </Badge>
                    </div>
                    <p className="text-sm text-gray-600 mb-3">{item.description}</p>
                    
                    {/* Documents for this item */}
                    {item.documents && item.documents.length > 0 && (
                      <div className="space-y-2">
                        <p className="text-sm font-medium text-gray-700">Uploaded Documents:</p>
                        {item.documents.map((doc, index) => (
                          <div key={index} className="flex items-center justify-between bg-green-50 p-2 rounded">
                            <div className="flex items-center space-x-2">
                              <FileText className="h-4 w-4 text-green-600" />
                              <span className="text-sm text-green-800">{doc.name}</span>
                              <span className="text-xs text-green-600">
                                ({new Date(doc.uploadedAt).toLocaleDateString()})
                              </span>
                            </div>
                            <div className="flex space-x-1">
                              <Button variant="outline" size="sm">
                                <Eye className="h-3 w-3" />
                              </Button>
                              <Button variant="outline" size="sm">
                                <Download className="h-3 w-3" />
                              </Button>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                  
                  <div className="ml-4">
                    <Button
                      onClick={() => openUploadModal(item)}
                      variant={item.completed ? "outline" : "primary"}
                      size="sm"
                    >
                      <Upload className="h-4 w-4 mr-2" />
                      {item.completed ? 'Add More' : 'Upload'}
                    </Button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Upload Modal */}
      {showUploadModal && selectedItem && (
        <Modal onClose={() => setShowUploadModal(false)}>
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Upload Document</h3>
              <p className="text-sm text-gray-600 mt-1">
                For: <span className="font-medium">{selectedItem.name}</span>
              </p>
            </div>
            <form onSubmit={handleUploadDocument} className="p-6 space-y-4">
              <Input
                label="Document Name"
                value={uploadData.name}
                onChange={(e) => setUploadData(prev => ({ ...prev, name: e.target.value }))}
                placeholder="Enter document name"
              />
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Select File
                </label>
                <input
                  type="file"
                  onChange={(e) => setUploadData(prev => ({ ...prev, file: e.target.files[0] }))}
                  className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-medium file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100"
                  required
                />
              </div>

              <div className="flex justify-end space-x-3 pt-4">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setShowUploadModal(false)}
                >
                  Cancel
                </Button>
                <Button type="submit" disabled={uploading}>
                  {uploading ? 'Uploading...' : 'Upload'}
                </Button>
              </div>
            </form>
          </div>
        </Modal>
      )}
    </div>
  );
}
