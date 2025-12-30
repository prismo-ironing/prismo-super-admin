class User {
  final int id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? primaryAddress;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final int totalOrders;
  final double? customerRating;
  final bool isActive;
  final bool isVerified;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.primaryAddress,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.profileImageUrl,
    this.dateOfBirth,
    this.gender,
    required this.totalOrders,
    this.customerRating,
    required this.isActive,
    required this.isVerified,
    required this.emailVerified,
    required this.phoneVerified,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both int and Long for id
    int userId;
    if (json['id'] is int) {
      userId = json['id'] as int;
    } else if (json['id'] is num) {
      userId = (json['id'] as num).toInt();
    } else {
      userId = 0;
    }
    
    // Parse dates with better error handling
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }
    
    return User(
      id: userId,
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? 'Unknown',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone_number']?.toString() ?? '',
      primaryAddress: json['primaryAddress']?.toString() ?? json['primary_address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postalCode']?.toString() ?? json['postal_code']?.toString(),
      country: json['country']?.toString() ?? 'India',
      profileImageUrl: json['profileImageUrl']?.toString() ?? json['profile_image_url']?.toString(),
      dateOfBirth: parseDateTime(json['dateOfBirth'] ?? json['date_of_birth']),
      gender: json['gender']?.toString(),
      totalOrders: (json['totalOrders'] ?? json['total_orders'] ?? 0) is num
          ? ((json['totalOrders'] ?? json['total_orders'] ?? 0) as num).toInt()
          : 0,
      customerRating: json['customerRating'] != null || json['customer_rating'] != null
          ? ((json['customerRating'] ?? json['customer_rating']) as num?)?.toDouble()
          : null,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      emailVerified: json['emailVerified'] ?? json['email_verified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? json['phone_verified'] ?? false,
      createdAt: parseDateTime(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt'] ?? json['updated_at']),
      lastLogin: parseDateTime(json['lastLogin'] ?? json['last_login']),
    );
  }
}

