class StoreStatistics {
  final String storeId;
  final String storeName;
  
  // Order Statistics
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final int acceptedOrders;
  final int rejectedOrders;
  
  // Revenue Statistics
  final double totalRevenue;
  final double thisMonthRevenue;
  final double todayRevenue;
  final double averageOrderValue;
  final double chargesPerOrder;
  
  // Rating Statistics
  final double averageRating;
  final int totalRatings;
  final double averageDeliveryRating;
  final double averageProductRating;
  
  // Acceptance/Rejection Rates
  final double acceptanceRate; // Percentage of orders accepted
  final double rejectionRate; // Percentage of orders rejected
  final double completionRate; // Percentage of orders completed
  
  // Additional Metrics
  final int thisMonthOrders;
  final int todayOrders;
  final double weeklyIncome;
  final double monthlyIncome;

  StoreStatistics({
    required this.storeId,
    required this.storeName,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.acceptedOrders,
    required this.rejectedOrders,
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.todayRevenue,
    required this.averageOrderValue,
    required this.chargesPerOrder,
    required this.averageRating,
    required this.totalRatings,
    required this.averageDeliveryRating,
    required this.averageProductRating,
    required this.acceptanceRate,
    required this.rejectionRate,
    required this.completionRate,
    required this.thisMonthOrders,
    required this.todayOrders,
    required this.weeklyIncome,
    required this.monthlyIncome,
  });

  factory StoreStatistics.fromJson(Map<String, dynamic> json) {
    // Safely extract values with null checks
    final totalOrders = _safeInt(json, 'totalOrders');
    final completedOrders = _safeInt(json, 'completedOrders');
    final pendingOrders = _safeInt(json, 'pendingOrders');
    final cancelledOrders = _safeInt(json, 'cancelledOrders');
    final acceptedOrders = _safeInt(json, 'acceptedOrders');
    final rejectedOrders = _safeInt(json, 'rejectedOrders');
    
    final totalRevenue = _safeDouble(json, 'totalRevenue');
    final thisMonthRevenue = _safeDouble(json, 'thisMonthRevenue');
    final todayRevenue = _safeDouble(json, 'todayRevenue');
    final weeklyIncome = _safeDouble(json, 'weeklyIncome');
    final monthlyIncome = _safeDouble(json, 'monthlyIncome');
    
    final averageRating = _safeDouble(json, 'averageRating');
    final totalRatings = _safeInt(json, 'totalRatings');
    final averageDeliveryRating = _safeDouble(json, 'averageDeliveryRating');
    final averageProductRating = _safeDouble(json, 'averageProductRating');
    
    // Calculate rates
    final acceptanceRate = totalOrders > 0 
        ? (acceptedOrders / totalOrders) * 100 
        : 0.0;
    final rejectionRate = totalOrders > 0 
        ? (rejectedOrders / totalOrders) * 100 
        : 0.0;
    final completionRate = totalOrders > 0 
        ? (completedOrders / totalOrders) * 100 
        : 0.0;
    
    // Calculate average order value
    final averageOrderValue = completedOrders > 0 
        ? totalRevenue / completedOrders 
        : 0.0;
    
    // Calculate charges per order (assuming platform fee is a percentage or fixed amount)
    // For now, we'll use a simple calculation - can be enhanced based on actual business logic
    final chargesPerOrder = completedOrders > 0 
        ? (totalRevenue * 0.1) / completedOrders // Assuming 10% platform fee
        : 0.0;

    // Safely extract store ID and name
    final storeId = _safeString(json, 'storeId') ?? 
                    _safeString(json, 'vendorId') ?? 
                    '';
    final storeName = _safeString(json, 'storeName') ?? 
                      _safeString(json, 'vendorName') ?? 
                      _safeString(json, 'name') ??
                      'Unknown Store';

    return StoreStatistics(
      storeId: storeId,
      storeName: storeName,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      pendingOrders: pendingOrders,
      cancelledOrders: cancelledOrders,
      acceptedOrders: acceptedOrders,
      rejectedOrders: rejectedOrders,
      totalRevenue: totalRevenue,
      thisMonthRevenue: thisMonthRevenue,
      todayRevenue: todayRevenue,
      averageOrderValue: averageOrderValue,
      chargesPerOrder: chargesPerOrder,
      averageRating: averageRating,
      totalRatings: totalRatings,
      averageDeliveryRating: averageDeliveryRating,
      averageProductRating: averageProductRating,
      acceptanceRate: acceptanceRate,
      rejectionRate: rejectionRate,
      completionRate: completionRate,
      thisMonthOrders: _safeInt(json, 'thisMonthOrders'),
      todayOrders: _safeInt(json, 'todayOrders'),
      weeklyIncome: weeklyIncome,
      monthlyIncome: monthlyIncome,
    );
  }

  // Helper methods for safe extraction
  static int _safeInt(Map<String, dynamic> json, String key) {
    try {
      final value = json[key];
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static double _safeDouble(Map<String, dynamic> json, String key) {
    try {
      final value = json[key];
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static String? _safeString(Map<String, dynamic> json, String key) {
    try {
      final value = json[key];
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'pendingOrders': pendingOrders,
      'cancelledOrders': cancelledOrders,
      'acceptedOrders': acceptedOrders,
      'rejectedOrders': rejectedOrders,
      'totalRevenue': totalRevenue,
      'thisMonthRevenue': thisMonthRevenue,
      'todayRevenue': todayRevenue,
      'averageOrderValue': averageOrderValue,
      'chargesPerOrder': chargesPerOrder,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'averageDeliveryRating': averageDeliveryRating,
      'averageProductRating': averageProductRating,
      'acceptanceRate': acceptanceRate,
      'rejectionRate': rejectionRate,
      'completionRate': completionRate,
      'thisMonthOrders': thisMonthOrders,
      'todayOrders': todayOrders,
      'weeklyIncome': weeklyIncome,
      'monthlyIncome': monthlyIncome,
    };
  }
}

