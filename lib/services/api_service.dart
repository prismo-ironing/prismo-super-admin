import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/manager.dart';
import '../models/store.dart';

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
}

