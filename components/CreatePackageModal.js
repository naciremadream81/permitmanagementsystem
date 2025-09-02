import { useState, useEffect } from 'react';
import { Modal, Input, Button } from './ui';
import { apiService } from '../lib/api';

export default function CreatePackageModal({ isOpen, onClose, onPackageCreated }) {
  const [permitTypes, setPermitTypes] = useState([]);
  const [formData, setFormData] = useState({
    // Customer Information
    customerName: '',
    customerPhone: '',
    customerEmail: '',
    customerAddress: '',
    // Property Information
    propertyAddress: '',
    propertyParcelId: '',
    propertyZoning: '',
    // Contractor Information
    contractorName: '',
    contractorLicense: '',
    contractorPhone: '',
    contractorEmail: '',
    // Permit Details
    county: '',
    permitType: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const FLORIDA_COUNTIES = [
    'Alachua', 'Baker', 'Bay', 'Bradford', 'Brevard', 'Broward', 'Calhoun',
    'Charlotte', 'Citrus', 'Clay', 'Collier', 'Columbia', 'DeSoto', 'Dixie',
    'Duval', 'Escambia', 'Flagler', 'Franklin', 'Gadsden', 'Gilchrist',
    'Glades', 'Gulf', 'Hamilton', 'Hardee', 'Hendry', 'Hernando', 'Highlands',
    'Hillsborough', 'Holmes', 'Indian River', 'Jackson', 'Jefferson', 'Lafayette',
    'Lake', 'Lee', 'Leon', 'Levy', 'Liberty', 'Madison', 'Manatee', 'Marion',
    'Martin', 'Miami-Dade', 'Monroe', 'Nassau', 'Okaloosa', 'Okeechobee',
    'Orange', 'Osceola', 'Palm Beach', 'Pasco', 'Pinellas', 'Polk', 'Putnam',
    'St. Johns', 'St. Lucie', 'Santa Rosa', 'Sarasota', 'Seminole', 'Sumter',
    'Suwannee', 'Taylor', 'Union', 'Volusia', 'Wakulla', 'Walton', 'Washington'
  ];

  useEffect(() => {
    if (isOpen) {
      loadPermitTypes();
    }
  }, [isOpen]);

  const loadPermitTypes = async () => {
    try {
      const types = await fetch('http://localhost:3001/api/permit-types').then(r => r.json());
      setPermitTypes(types);
    } catch (error) {
      console.error('Failed to load permit types:', error);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const newPackage = await apiService.createPermit(formData);
      onPackageCreated(newPackage);
      onClose();
      setFormData({
        customerName: '', customerPhone: '', customerEmail: '', customerAddress: '',
        propertyAddress: '', propertyParcelId: '', propertyZoning: '',
        contractorName: '', contractorLicense: '', contractorPhone: '', contractorEmail: '',
        county: '', permitType: ''
      });
    } catch (error) {
      setError(error.message || 'Failed to create permit package');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <Modal onClose={onClose}>
      <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Create New Permit Package</h2>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}

          {/* Customer Information */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Customer Information</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                label="Customer Name"
                name="customerName"
                value={formData.customerName}
                onChange={handleInputChange}
                required
              />
              <Input
                label="Phone Number"
                name="customerPhone"
                type="tel"
                value={formData.customerPhone}
                onChange={handleInputChange}
                required
              />
              <Input
                label="Email Address"
                name="customerEmail"
                type="email"
                value={formData.customerEmail}
                onChange={handleInputChange}
                required
              />
              <Input
                label="Customer Address"
                name="customerAddress"
                value={formData.customerAddress}
                onChange={handleInputChange}
                required
              />
            </div>
          </div>

          {/* Property Information */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Property Information</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                label="Property Address"
                name="propertyAddress"
                value={formData.propertyAddress}
                onChange={handleInputChange}
                required
              />
              <Input
                label="Parcel ID"
                name="propertyParcelId"
                value={formData.propertyParcelId}
                onChange={handleInputChange}
              />
              <Input
                label="Zoning"
                name="propertyZoning"
                value={formData.propertyZoning}
                onChange={handleInputChange}
                placeholder="e.g., R-1 Residential"
              />
            </div>
          </div>

          {/* Contractor Information */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Primary Contractor Information</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                label="Contractor Name"
                name="contractorName"
                value={formData.contractorName}
                onChange={handleInputChange}
                required
              />
              <Input
                label="License Number"
                name="contractorLicense"
                value={formData.contractorLicense}
                onChange={handleInputChange}
                required
              />
              <Input
                label="Phone Number"
                name="contractorPhone"
                type="tel"
                value={formData.contractorPhone}
                onChange={handleInputChange}
                required
              />
              <Input
                label="Email Address"
                name="contractorEmail"
                type="email"
                value={formData.contractorEmail}
                onChange={handleInputChange}
                required
              />
            </div>
          </div>

          {/* Permit Details */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4">Permit Details</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  County
                </label>
                <select
                  name="county"
                  value={formData.county}
                  onChange={handleInputChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select County</option>
                  {FLORIDA_COUNTIES.map(county => (
                    <option key={county} value={county}>{county}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Permit Type
                </label>
                <select
                  name="permitType"
                  value={formData.permitType}
                  onChange={handleInputChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Select Permit Type</option>
                  {permitTypes.map(type => (
                    <option key={type.value} value={type.value}>{type.label}</option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          <div className="flex justify-end space-x-3 pt-4 border-t border-gray-200">
            <Button
              type="button"
              variant="secondary"
              onClick={onClose}
              disabled={loading}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={loading}
            >
              {loading ? 'Creating...' : 'Create Permit Package'}
            </Button>
          </div>
        </form>
      </div>
    </Modal>
  );
}
