class ApiConfig {
  // Environment toggle - set to true for local development
  static const bool _isDevelopment = false;
  
  // Development URL (localhost)
  static const String _devBaseUrl = 'http://localhost:8081/api';
  
  // Production URL (GCP Cloud Run)
  static const String _prodBaseUrl = 'https://prismo-service-184530546940.us-central1.run.app/api';
  
  // Active base URL
  static String get baseUrl => _isDevelopment ? _devBaseUrl : _prodBaseUrl;
  
  // =====================================================
  // MANAGER ENDPOINTS
  // =====================================================
  
  static String get managersUrl => '$baseUrl/admin/managers';
  
  // Get all managers (GET)
  static String get allManagersUrl => managersUrl;
  
  // Get manager by ID (GET)
  static String managerByIdUrl(String managerId) => '$managersUrl/$managerId';
  
  // Assign vendor to manager (POST)
  static String assignVendorUrl(String managerId, String vendorId) => 
      '$managersUrl/$managerId/vendors/$vendorId';
  
  // Remove vendor from manager (DELETE)
  static String removeVendorUrl(String managerId, String vendorId) => 
      '$managersUrl/$managerId/vendors/$vendorId';
  
  // =====================================================
  // STORE/VENDOR ENDPOINTS
  // =====================================================
  
  static String get storesUrl => '$baseUrl/admin/inventory/stores';
  
  // =====================================================
  // VENDOR ACTIVATION & DOCUMENT ENDPOINTS
  // =====================================================
  
  // Get vendor activation status (GET)
  static String vendorActivationStatusUrl(String vendorId) => 
      '$baseUrl/vendors/activation/status/$vendorId';
  
  // Update document status (PUT)
  static String documentStatusUrl(String vendorId, int documentId) => 
      '$baseUrl/vendors/activation/$vendorId/documents/$documentId/status';
  
  // Get document download URL (GET)
  static String documentDownloadUrl(String vendorId, int documentId) => 
      '$baseUrl/vendors/activation/$vendorId/documents/$documentId/download-url';
  
  // Approve vendor activation (POST)
  static String approveVendorUrl(String vendorId) => 
      '$baseUrl/vendors/activation/$vendorId/approve';
  
  // Reject vendor activation (POST)
  static String rejectVendorUrl(String vendorId) => 
      '$baseUrl/vendors/activation/$vendorId/reject';
  
  // Get all vendors with pending documents
  static String get vendorsUrl => '$baseUrl/vendors';
  
  // Get all vendors (admin)
  static String get allVendorsUrl => '$vendorsUrl/list/all';
  
  // =====================================================
  // USER ENDPOINTS
  // =====================================================
  
  static String get usersUrl => '$baseUrl/users';
  static String get userStatsUrl => '$usersUrl/stats';
  
  // =====================================================
  // ORDER ENDPOINTS
  // =====================================================
  
  static String get ordersUrl => '$baseUrl/orders';
  
  // =====================================================
  // MEDICINE ENDPOINTS
  // =====================================================
  
  static String get medicinesUrl => '$baseUrl/medicines';
  static String get inventoryStatsUrl => '$baseUrl/admin/inventory/stats';
}

