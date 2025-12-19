class Manager {
  final String id;
  final String name;
  final String? email;
  final String phoneNumber;
  final List<String> vendorIds;
  final String? profileImageUrl;
  final String role;
  final bool phoneVerified;
  final bool emailVerified;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  Manager({
    required this.id,
    required this.name,
    this.email,
    required this.phoneNumber,
    required this.vendorIds,
    this.profileImageUrl,
    required this.role,
    required this.phoneVerified,
    required this.emailVerified,
    required this.isActive,
    required this.isVerified,
    this.lastLogin,
    this.createdAt,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? '',
      vendorIds: List<String>.from(json['vendorIds'] ?? []),
      profileImageUrl: json['profileImageUrl'],
      role: json['role'] ?? 'STORE_MANAGER',
      phoneVerified: json['phoneVerified'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      isVerified: json['isVerified'] ?? false,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.tryParse(json['lastLogin'].toString()) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
    );
  }

  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';
}

