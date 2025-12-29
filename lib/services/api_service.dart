import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/manager.dart';
import '../models/store.dart';
import '../models/vendor_document.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  /// Get all managers
  static Future<List<Manager>> getAllManagers() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.allManagersUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['managers'] as List)
              .map((m) => Manager.fromJson(m as Map<String, dynamic>))
              .toList();
        }
      }
      throw Exception('Failed to load managers: ${response.statusCode}');
    } catch (e) {
      print('Error fetching managers: $e');
      rethrow;
    }
  }

  /// Get all stores
  static Future<List<Store>> getAllStores() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.storesUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['stores'] as List)
              .map((s) => Store.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      }
      throw Exception('Failed to load stores: ${response.statusCode}');
    } catch (e) {
      print('Error fetching stores: $e');
      rethrow;
    }
  }

  /// Assign store to manager
  static Future<bool> assignStoreToManager(String managerId, String storeId) async {
    try {
      final response = await http
          .post(Uri.parse(ApiConfig.assignVendorUrl(managerId, storeId)))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error assigning store: $e');
      return false;
    }
  }

  /// Remove store from manager
  static Future<bool> removeStoreFromManager(String managerId, String storeId) async {
    try {
      final response = await http
          .delete(Uri.parse(ApiConfig.removeVendorUrl(managerId, storeId)))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error removing store: $e');
      return false;
    }
  }

  // =====================================================
  // VENDOR DOCUMENT MANAGEMENT
  // =====================================================

  /// Get vendor activation status with documents
  static Future<VendorActivationStatus?> getVendorActivationStatus(String vendorId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.vendorActivationStatusUrl(vendorId)))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VendorActivationStatus.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching vendor activation status: $e');
      return null;
    }
  }

  /// Approve a document
  static Future<bool> approveDocument(String vendorId, int documentId, {String? comments}) async {
    try {
      final response = await http
          .put(
            Uri.parse(ApiConfig.documentStatusUrl(vendorId, documentId)),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'status': 'APPROVED',
              'comments': comments ?? 'Document verified and approved',
            }),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error approving document: $e');
      return false;
    }
  }

  /// Reject a document
  static Future<bool> rejectDocument(String vendorId, int documentId, {String? comments}) async {
    try {
      final response = await http
          .put(
            Uri.parse(ApiConfig.documentStatusUrl(vendorId, documentId)),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'status': 'REJECTED',
              'comments': comments ?? 'Document rejected',
            }),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error rejecting document: $e');
      return false;
    }
  }

  /// Approve vendor activation (after all documents are approved)
  static Future<bool> approveVendorActivation(String vendorId) async {
    try {
      final response = await http
          .post(Uri.parse(ApiConfig.approveVendorUrl(vendorId)))
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error approving vendor: $e');
      return false;
    }
  }

  /// Reject vendor activation
  static Future<bool> rejectVendorActivation(String vendorId, {String? reason}) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.rejectVendorUrl(vendorId)),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'reason': reason ?? 'Vendor activation rejected by Super Admin',
            }),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error rejecting vendor: $e');
      return false;
    }
  }

  /// Get signed download URL for a document
  static Future<String?> getDocumentDownloadUrl(String vendorId, int documentId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.documentDownloadUrl(vendorId, documentId)))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['downloadUrl'];
      }
      return null;
    } catch (e) {
      print('Error getting document download URL: $e');
      return null;
    }
  }
}

