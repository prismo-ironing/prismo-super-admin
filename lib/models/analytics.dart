class AnalyticsOverview {
  final VendorStats vendors;
  final UserStats users;
  final RevenueStats revenue;
  final OrderStats orders;
  final MedicineStats medicines;
  final DocumentStats documents;
  final ManagerStats managers;

  AnalyticsOverview({
    required this.vendors,
    required this.users,
    required this.revenue,
    required this.orders,
    required this.medicines,
    required this.documents,
    required this.managers,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      vendors: VendorStats.fromJson(json['vendors'] as Map<String, dynamic>),
      users: UserStats.fromJson(json['users'] as Map<String, dynamic>),
      revenue: RevenueStats.fromJson(json['revenue'] as Map<String, dynamic>),
      orders: OrderStats.fromJson(json['orders'] as Map<String, dynamic>),
      medicines: MedicineStats.fromJson(json['medicines'] as Map<String, dynamic>),
      documents: DocumentStats.fromJson(json['documents'] as Map<String, dynamic>),
      managers: ManagerStats.fromJson(json['managers'] as Map<String, dynamic>),
    );
  }
}

class VendorStats {
  final int total;
  final int approved;
  final int pending;
  final int rejected;
  final int verified;
  final int open;
  final int closed;

  VendorStats({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.verified,
    required this.open,
    required this.closed,
  });

  factory VendorStats.fromJson(Map<String, dynamic> json) {
    return VendorStats(
      total: (json['total'] as num).toInt(),
      approved: (json['approved'] as num).toInt(),
      pending: (json['pending'] as num).toInt(),
      rejected: (json['rejected'] as num).toInt(),
      verified: (json['verified'] as num).toInt(),
      open: (json['open'] as num).toInt(),
      closed: (json['closed'] as num).toInt(),
    );
  }
}

class UserStats {
  final int total;
  final int active;
  final int verified;
  final int inactive;

  UserStats({
    required this.total,
    required this.active,
    required this.verified,
    required this.inactive,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: (json['total'] as num).toInt(),
      active: (json['active'] as num).toInt(),
      verified: (json['verified'] as num).toInt(),
      inactive: (json['inactive'] as num).toInt(),
    );
  }
}

class RevenueStats {
  final double total;
  final double thisMonth;
  final double today;

  RevenueStats({
    required this.total,
    required this.thisMonth,
    required this.today,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      total: (json['total'] as num).toDouble(),
      thisMonth: (json['thisMonth'] as num).toDouble(),
      today: (json['today'] as num).toDouble(),
    );
  }
}

class OrderStats {
  final int total;
  final int completed;
  final int pending;
  final int cancelled;
  final int inProgress;
  final int today;

  OrderStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.cancelled,
    required this.inProgress,
    required this.today,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      total: (json['total'] as num).toInt(),
      completed: (json['completed'] as num).toInt(),
      pending: (json['pending'] as num).toInt(),
      cancelled: (json['cancelled'] as num).toInt(),
      inProgress: (json['inProgress'] as num).toInt(),
      today: (json['today'] as num).toInt(),
    );
  }
}

class MedicineStats {
  final int total;
  final int active;
  final int inactive;
  final int inventoryItems;

  MedicineStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.inventoryItems,
  });

  factory MedicineStats.fromJson(Map<String, dynamic> json) {
    return MedicineStats(
      total: (json['total'] as num).toInt(),
      active: (json['active'] as num).toInt(),
      inactive: (json['inactive'] as num).toInt(),
      inventoryItems: (json['inventoryItems'] as num).toInt(),
    );
  }
}

class DocumentStats {
  final int total;
  final int approved;
  final int pending;
  final int rejected;

  DocumentStats({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  factory DocumentStats.fromJson(Map<String, dynamic> json) {
    return DocumentStats(
      total: (json['total'] as num).toInt(),
      approved: (json['approved'] as num).toInt(),
      pending: (json['pending'] as num).toInt(),
      rejected: (json['rejected'] as num).toInt(),
    );
  }
}

class ManagerStats {
  final int total;
  final int active;
  final int inactive;

  ManagerStats({
    required this.total,
    required this.active,
    required this.inactive,
  });

  factory ManagerStats.fromJson(Map<String, dynamic> json) {
    return ManagerStats(
      total: (json['total'] as num).toInt(),
      active: (json['active'] as num).toInt(),
      inactive: (json['inactive'] as num).toInt(),
    );
  }
}

