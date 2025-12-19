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
}

