import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/manager.dart';
import '../models/store.dart';
import '../models/vendor_document.dart';
import '../models/user.dart';
import '../models/store_statistics.dart';

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

  // =====================================================
  // USER MANAGEMENT
  // =====================================================

  /// Get all users with pagination
  static Future<Map<String, dynamic>> getAllUsers({
    int page = 0,
    int size = 50,
    String sortBy = 'createdAt',
    bool sortAsc = true,
    String? search,
  }) async {
    try {
      http.Response response;
      
      // If search is provided, use search endpoint
      if (search != null && search.trim().isNotEmpty) {
        final url = '${ApiConfig.usersUrl}/search?name=${Uri.encodeComponent(search.trim())}';
        response = await http.get(Uri.parse(url)).timeout(_timeout);
        
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final users = data.map((u) {
            try {
              return User.fromJson(u as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing user from search: $e, User data: $u');
              rethrow;
            }
          }).toList();
          return {
            'users': users,
            'totalElements': users.length,
            'totalPages': 1,
            'currentPage': 0,
            'pageSize': users.length,
          };
        }
      } else {
        // Backend only supports sortBy, not direction - we'll sort client-side if needed
        final url = '${ApiConfig.usersUrl}?page=$page&size=$size&sortBy=$sortBy';
        response = await http.get(Uri.parse(url)).timeout(_timeout);
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final contentList = data['content'] as List;
          final usersList = <User>[];
          
          for (int i = 0; i < contentList.length; i++) {
            try {
              final userJson = contentList[i] as Map<String, dynamic>;
              // Debug: print first user to see structure
              if (i == 0) {
                print('First User JSON: $userJson');
              }
              usersList.add(User.fromJson(userJson));
            } catch (e) {
              print('Error parsing user at index $i: $e, User data: ${contentList[i]}');
              // Continue with next user instead of failing completely
            }
          }
          
          // Backend returns descending by default, reverse if ascending is requested
          final sortedUsers = sortAsc ? usersList.reversed.toList() : usersList;
          
          return {
            'users': sortedUsers,
            'totalElements': data['totalElements'] ?? 0,
            'totalPages': data['totalPages'] ?? 0,
            'currentPage': data['page'] ?? 0,
            'pageSize': data['size'] ?? size,
          };
        }
      }
      
      throw Exception('Failed to load users: ${response.statusCode}');
    } catch (e) {
      print('Error fetching users: $e');
      rethrow;
    }
  }

  /// Get all orders and count by user email
  /// Also accepts a map of userId -> email for matching numeric IDs
  static Future<Map<String, int>> getUserOrderCounts(
    List<String> userEmails, {
    Map<String, String>? userIdToEmailMap,
  }) async {
    final Map<String, int> counts = {};
    
    // Initialize all user counts to 0
    for (final email in userEmails) {
      counts[email] = 0;
    }
    
    try {
      // Fetch all orders (endpoint returns List directly, not paginated)
      final response = await http
          .get(Uri.parse(ApiConfig.ordersUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> orders = json.decode(response.body);
        
        print('Fetched ${orders.length} orders for counting');
        
        // Create reverse lookup: email -> all possible identifiers
        final emailToIdentifiers = <String, Set<String>>{};
        for (final email in userEmails) {
          emailToIdentifiers[email] = {email, email.toLowerCase()};
        }
        if (userIdToEmailMap != null) {
          for (final entry in userIdToEmailMap.entries) {
            final email = entry.value;
            if (emailToIdentifiers.containsKey(email)) {
              emailToIdentifiers[email]!.add(entry.key);
            }
          }
        }
        
        // Count orders per user
        for (final order in orders) {
          final orderUserId = order['userId']?.toString() ?? 
                             order['user_id']?.toString() ?? 
                             order['customerId']?.toString() ??
                             order['customer_id']?.toString();
          
          if (orderUserId != null) {
            // Try to find matching email
            String? matchedEmail;
            
            // Direct match
            if (counts.containsKey(orderUserId)) {
              matchedEmail = orderUserId;
            } else {
              // Case-insensitive match
              final lowerOrderUserId = orderUserId.toLowerCase();
              for (final email in userEmails) {
                if (email.toLowerCase() == lowerOrderUserId) {
                  matchedEmail = email;
                  break;
                }
              }
              
              // Try numeric ID match if we have the map
              if (matchedEmail == null && userIdToEmailMap != null) {
                matchedEmail = userIdToEmailMap[orderUserId];
              }
            }
            
            if (matchedEmail != null && counts.containsKey(matchedEmail)) {
              counts[matchedEmail] = (counts[matchedEmail] ?? 0) + 1;
            }
          }
        }
        
        print('Order counts calculated: $counts');
      } else {
        print('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders for counting: $e');
      // Return empty counts, will fall back to cached totalOrders
    }
    
    return counts;
  }

  // =====================================================
  // STORE STATISTICS
  // =====================================================

  /// Get comprehensive store statistics
  static Future<StoreStatistics?> getStoreStatistics(String storeId) async {
    try {
      // Fetch vendor statistics first (required)
      final statsData = await _getVendorStatistics(storeId);
      
      if (statsData == null) {
        print('Failed to fetch vendor statistics for store: $storeId');
        return null;
      }

      // Fetch orders and ratings in parallel (optional - don't fail if these fail)
      List<dynamic> orders = [];
      List<dynamic> ratings = [];
      
      try {
        final results = await Future.wait([
          _getVendorOrders(storeId),
          _getVendorRatings(storeId),
        ]);
        orders = results[0] as List<dynamic>? ?? [];
        ratings = results[1] as List<dynamic>? ?? [];
      } catch (e) {
        print('Warning: Failed to fetch orders/ratings, continuing with basic stats: $e');
        // Continue with empty lists - we'll still show basic statistics
      }

      // Calculate acceptance/rejection rates from orders
      int acceptedOrders = 0;
      int rejectedOrders = 0;
      
      for (var order in orders) {
        if (order is! Map<String, dynamic>) continue;
        
        final status = order['status'] as String?;
        if (status == null) continue;
        
        // Orders that are confirmed, approved, or in delivery are considered accepted by vendor
        if (status == 'ORDER_CONFIRMED' || 
            status == 'PRESCRIPTION_APPROVED' ||
            status == 'VENDOR_ASSIGNED' ||
            status == 'OUT_FOR_DELIVERY' || 
            status == 'DELIVERED' ||
            status == 'ORDER_COMPLETED') {
          acceptedOrders++;
        }
        // Orders rejected by vendor
        if (status == 'PRESCRIPTION_REJECTED' || 
            status == 'FULFILLMENT_FAILED') {
          rejectedOrders++;
        }
      }

      // Calculate rating statistics
      double averageRating = 0.0;
      double averageDeliveryRating = 0.0;
      double averageProductRating = 0.0;
      int totalRatings = ratings.length;

      if (ratings.isNotEmpty) {
        double totalRating = 0.0;
        double totalDeliveryRating = 0.0;
        double totalProductRating = 0.0;
        int deliveryRatingCount = 0;
        int productRatingCount = 0;

        for (var rating in ratings) {
          if (rating is! Map<String, dynamic>) continue;
          
          final ratingValue = (rating['rating'] as num?)?.toDouble();
          final deliveryRatingValue = (rating['deliveryRating'] as num?)?.toDouble();
          final productRatingValue = (rating['productRating'] as num?)?.toDouble();

          if (ratingValue != null && ratingValue > 0) {
            totalRating += ratingValue;
          }
          if (deliveryRatingValue != null && deliveryRatingValue > 0) {
            totalDeliveryRating += deliveryRatingValue;
            deliveryRatingCount++;
          }
          if (productRatingValue != null && productRatingValue > 0) {
            totalProductRating += productRatingValue;
            productRatingCount++;
          }
        }

        if (totalRatings > 0 && totalRating > 0) {
          averageRating = totalRating / totalRatings;
        }
        if (deliveryRatingCount > 0) {
          averageDeliveryRating = totalDeliveryRating / deliveryRatingCount;
        }
        if (productRatingCount > 0) {
          averageProductRating = totalProductRating / productRatingCount;
        }
      }

      // Get store name from stats or use fallback
      final storeName = statsData['vendorName'] as String? ?? 
                       statsData['storeName'] as String? ?? 
                       statsData['name'] as String? ?? 
                       'Unknown Store';

      // Combine all statistics with proper null safety
      final combinedStats = <String, dynamic>{
        ...statsData,
        'storeId': storeId,
        'storeName': storeName,
        'acceptedOrders': acceptedOrders,
        'rejectedOrders': rejectedOrders,
        'averageRating': averageRating,
        'totalRatings': totalRatings,
        'averageDeliveryRating': averageDeliveryRating,
        'averageProductRating': averageProductRating,
      };

      return StoreStatistics.fromJson(combinedStats);
    } catch (e, stackTrace) {
      print('Error fetching store statistics: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get vendor statistics from backend
  static Future<Map<String, dynamic>?> _getVendorStatistics(String vendorId) async {
    try {
      final url = '${ApiConfig.baseUrl}/vendors/profile/$vendorId/statistics';
      print('Fetching vendor statistics from: $url');
      
      final response = await http
          .get(Uri.parse(url))
          .timeout(_timeout);

      print('Vendor statistics response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        print('Unexpected response format: ${data.runtimeType}');
        return null;
      } else {
        print('Failed to fetch vendor statistics: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error fetching vendor statistics: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get all orders for a vendor
  static Future<List<dynamic>> _getVendorOrders(String vendorId) async {
    try {
      // Use vendor-specific orders endpoint
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/vendors/profile/$vendorId/orders'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Response might be a list or an object with orders array
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('orders')) {
          return data['orders'] as List<dynamic>;
        } else if (data is Map && data.containsKey('content')) {
          return data['content'] as List<dynamic>;
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error fetching vendor orders: $e');
      return [];
    }
  }

  /// Get all ratings for a vendor
  static Future<List<dynamic>> _getVendorRatings(String vendorId) async {
    try {
      // Since there's no direct endpoint for vendor ratings, we'll fetch all orders
      // and then get ratings for completed orders only (ratings are only for completed orders)
      final orders = await _getVendorOrders(vendorId);
      final ratings = <dynamic>[];

      if (orders.isEmpty) {
        return ratings;
      }

      // Filter to only completed orders (ratings are typically only for completed orders)
      final completedOrderIds = orders
          .where((o) {
            if (o is! Map<String, dynamic>) return false;
            final status = o['status'] as String?;
            return status == 'ORDER_COMPLETED' || status == 'DELIVERED';
          })
          .take(30) // Limit to 30 most recent completed orders to avoid too many API calls
          .map((o) {
            if (o is Map<String, dynamic>) {
              return o['id'] ?? o['orderId'] ?? o['order_id'];
            }
            return null;
          })
          .whereType<String>()
          .toList();
      
      if (completedOrderIds.isEmpty) {
        return ratings;
      }
      
      // Fetch ratings sequentially to avoid overwhelming the server (404s are expected)
      for (var orderId in completedOrderIds) {
        try {
          final ratingResponse = await http
              .get(Uri.parse(ApiConfig.getOrderRatingUrl(orderId)))
              .timeout(const Duration(seconds: 3));

          if (ratingResponse.statusCode == 200) {
            final rating = json.decode(ratingResponse.body);
            if (rating is Map<String, dynamic> && 
                (rating['vendorId'] == vendorId || rating['vendor_id'] == vendorId)) {
              ratings.add(rating);
            }
          }
          // Silently ignore 404s - they're expected for orders without ratings
        } catch (e) {
          // Silently continue if rating doesn't exist (404 is expected for orders without ratings)
          // Only log if it's not a 404
          if (e.toString().contains('404') == false) {
            // Don't log 404s, they're expected
          }
        }
      }

      return ratings;
    } catch (e) {
      print('Error fetching vendor ratings: $e');
      return [];
    }
  }
}

