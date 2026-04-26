class IncidentModel {
  final String? id;
  final String userId;
  final double latitude;
  final double longitude;
  final String category;
  final String? description;
  final String status;

  IncidentModel({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.description,
    this.status = 'reported',
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
    'description': description,
    'status': status,
  };
}