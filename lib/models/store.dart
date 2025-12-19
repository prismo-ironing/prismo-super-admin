class Store {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final bool isActive;

  Store({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.isActive = true,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? json['vendorId'] ?? '',
      name: json['name'] ?? json['vendorName'] ?? 'Unknown Store',
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      isActive: json['isActive'] ?? true,
    );
  }

  String get displayLocation {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.isEmpty ? 'Location N/A' : parts.join(', ');
  }
}

