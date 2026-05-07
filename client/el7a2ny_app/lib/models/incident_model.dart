class IncidentModel {
  final String? id;
  final String userId;
  final double latitude;
  final double longitude;
  final String category;
  final String? description;
  final String status;
  final String? address;

  IncidentModel({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.description,
    this.status = 'reported',
    this.address,
  });

  // ✅ Add this
  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'reported',
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
    'description': description,
    'status': status,
  };
}