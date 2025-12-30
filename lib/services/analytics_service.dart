import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/analytics.dart';
import '../models/store.dart';
import '../models/manager.dart';
import 'api_service.dart';

class AnalyticsService {
  static const Duration _timeout = Duration(seconds: 30);

  /// Get comprehensive analytics overview by aggregating data from existing APIs
  static Future<AnalyticsOverview?> getAnalyticsOverview() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _getVendorStats(),
        _getUserStats(),
        _getOrderStats(),
        _getMedicineStats(),
        _getDocumentStats(),
        _getManagerStats(),
      ]);

      final vendorStats = results[0] as VendorStats;
      final userStats = results[1] as UserStats;
      final orderStats = results[2] as OrderStats;
      final medicineStats = results[3] as MedicineStats;
      final documentStats = results[4] as DocumentStats;
      final managerStats = results[5] as ManagerStats;

      // Calculate revenue from orders
      final revenueStats = await _getRevenueStats();

      return AnalyticsOverview(
        vendors: vendorStats,
        users: userStats,
        revenue: revenueStats,
        orders: orderStats,
        medicines: medicineStats,
        documents: documentStats,
        managers: managerStats,
      );
    } catch (e) {
      print('Error fetching analytics: $e');
      return null;
    }
  }

  static Future<VendorStats> _getVendorStats() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.allVendorsUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> vendors = json.decode(response.body);
        
        int total = vendors.length;
        int approved = 0;
        int pending = 0;
        int rejected = 0;
        int verified = 0;
        int open = 0;

        for (var vendor in vendors) {
          final activationStatus = vendor['activationStatus'] as String?;
          final isVerified = vendor['isVerified'] as bool? ?? false;
          final isOpen = vendor['isOpen'] as bool? ?? false;

          if (activationStatus == 'APPROVED') approved++;
          if (activationStatus == 'UNDER_REVIEW' || activationStatus == 'DOCUMENTS_SUBMITTED') pending++;
          if (activationStatus == 'REJECTED') rejected++;
          if (isVerified) verified++;
          if (isOpen) open++;
        }

        return VendorStats(
          total: total,
          approved: approved,
          pending: pending,
          rejected: rejected,
          verified: verified,
          open: open,
          closed: total - open,
        );
      }
    } catch (e) {
      print('Error fetching vendor stats: $e');
    }
    return VendorStats(total: 0, approved: 0, pending: 0, rejected: 0, verified: 0, open: 0, closed: 0);
  }

  static Future<UserStats> _getUserStats() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.userStatsUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totalUsers = (data['totalUsers'] as num?)?.toInt() ?? 0;
        final activeUsers = (data['activeUsers'] as num?)?.toInt() ?? 0;
        final verifiedUsers = (data['verifiedUsers'] as num?)?.toInt() ?? 0;

        return UserStats(
          total: totalUsers,
          active: activeUsers,
          verified: verifiedUsers,
          inactive: totalUsers - activeUsers,
        );
      }
    } catch (e) {
      print('Error fetching user stats: $e');
    }
    return UserStats(total: 0, active: 0, verified: 0, inactive: 0);
  }

  static Future<OrderStats> _getOrderStats() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.ordersUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> orders = json.decode(response.body);
        
        int total = orders.length;
        int completed = 0;
        int pending = 0;
        int cancelled = 0;
        int inProgress = 0;
        int today = 0;

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        for (var order in orders) {
          final status = order['status'] as String?;
          final createdAt = order['createdAt'] as String?;

          if (status == 'ORDER_COMPLETED') completed++;
          if (status == 'ORDER_PLACED') pending++;
          if (status == 'ORDER_CANCELLED') cancelled++;
          if (status == 'ORDER_CONFIRMED' || status == 'OUT_FOR_DELIVERY') inProgress++;

          if (createdAt != null) {
            try {
              final orderDate = DateTime.parse(createdAt);
              if (orderDate.isAfter(todayStart)) {
                today++;
              }
            } catch (e) {
              // Ignore parse errors
            }
          }
        }

        return OrderStats(
          total: total,
          completed: completed,
          pending: pending,
          cancelled: cancelled,
          inProgress: inProgress,
          today: today,
        );
      }
    } catch (e) {
      print('Error fetching order stats: $e');
    }
    return OrderStats(total: 0, completed: 0, pending: 0, cancelled: 0, inProgress: 0, today: 0);
  }

  static Future<RevenueStats> _getRevenueStats() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.ordersUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> orders = json.decode(response.body);
        
        double totalRevenue = 0;
        double thisMonthRevenue = 0;
        double todayRevenue = 0;

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final monthStart = DateTime(now.year, now.month, 1);

        for (var order in orders) {
          final status = order['status'] as String?;
          if (status != 'ORDER_COMPLETED') continue;

          final totalAmount = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final createdAt = order['createdAt'] as String?;

          totalRevenue += totalAmount;

          if (createdAt != null) {
            try {
              final orderDate = DateTime.parse(createdAt);
              if (orderDate.isAfter(monthStart)) {
                thisMonthRevenue += totalAmount;
              }
              if (orderDate.isAfter(todayStart)) {
                todayRevenue += totalAmount;
              }
            } catch (e) {
              // Ignore parse errors
            }
          }
        }

        return RevenueStats(
          total: totalRevenue,
          thisMonth: thisMonthRevenue,
          today: todayRevenue,
        );
      }
    } catch (e) {
      print('Error fetching revenue stats: $e');
    }
    return RevenueStats(total: 0, thisMonth: 0, today: 0);
  }

  static Future<MedicineStats> _getMedicineStats() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.inventoryStatsUrl))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totalMedicines = (data['totalMedicinesInCatalog'] as num?)?.toInt() ?? 0;
        final inventoryItems = (data['totalInventoryRecords'] as num?)?.toInt() ?? 0;

        // Get active medicines count by fetching first page
        try {
          final medicinesResponse = await http
              .get(Uri.parse('${ApiConfig.medicinesUrl}?page=0&size=1'))
              .timeout(_timeout);
          
          if (medicinesResponse.statusCode == 200) {
            final medicinesData = json.decode(medicinesResponse.body);
            final activeMedicines = (medicinesData['totalCount'] as num?)?.toInt() ?? 0;
            
            return MedicineStats(
              total: totalMedicines,
              active: activeMedicines,
              inactive: totalMedicines - activeMedicines,
              inventoryItems: inventoryItems,
            );
          }
        } catch (e) {
          print('Error fetching active medicines: $e');
        }

        return MedicineStats(
          total: totalMedicines,
          active: totalMedicines, // Assume all are active if we can't fetch
          inactive: 0,
          inventoryItems: inventoryItems,
        );
      }
    } catch (e) {
      print('Error fetching medicine stats: $e');
    }
    return MedicineStats(total: 0, active: 0, inactive: 0, inventoryItems: 0);
  }

  static Future<DocumentStats> _getDocumentStats() async {
    try {
      // Get all stores and check their document status
      final stores = await ApiService.getAllStores();
      
      int totalDocuments = 0;
      int approvedDocuments = 0;
      int pendingDocuments = 0;
      int rejectedDocuments = 0;

      // Sample a few stores to get document stats (to avoid too many API calls)
      // In production, you might want to limit this or cache results
      final sampleStores = stores.take(50).toList();
      
      for (var store in sampleStores) {
        try {
          final status = await ApiService.getVendorActivationStatus(store.id);
          if (status != null) {
            totalDocuments += status.documents.length;
            for (var doc in status.documents) {
              if (doc.isApproved) approvedDocuments++;
              else if (doc.isRejected) rejectedDocuments++;
              else pendingDocuments++;
            }
          }
        } catch (e) {
          // Continue with next store if one fails
        }
      }

      // Extrapolate based on sample (rough estimate)
      if (sampleStores.isNotEmpty && stores.length > sampleStores.length) {
        final ratio = stores.length / sampleStores.length;
        totalDocuments = (totalDocuments * ratio).round();
        approvedDocuments = (approvedDocuments * ratio).round();
        pendingDocuments = (pendingDocuments * ratio).round();
        rejectedDocuments = (rejectedDocuments * ratio).round();
      }

      return DocumentStats(
        total: totalDocuments,
        approved: approvedDocuments,
        pending: pendingDocuments,
        rejected: rejectedDocuments,
      );
    } catch (e) {
      print('Error fetching document stats: $e');
    }
    return DocumentStats(total: 0, approved: 0, pending: 0, rejected: 0);
  }

  static Future<ManagerStats> _getManagerStats() async {
    try {
      final managers = await ApiService.getAllManagers();
      
      int total = managers.length;
      int active = managers.where((m) => m.isActive).length;

      return ManagerStats(
        total: total,
        active: active,
        inactive: total - active,
      );
    } catch (e) {
      print('Error fetching manager stats: $e');
    }
    return ManagerStats(total: 0, active: 0, inactive: 0);
  }
}
