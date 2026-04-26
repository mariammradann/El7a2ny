// ─────────────────────────────────────────────────────────
//  ALERT MODEL — matches Django REST Framework response
//
//  Expected Django endpoint: GET /api/alerts/
//  Expected JSON:
//  [
//    {
//      "id": 1,
//      "type": "حريق",
//      "location": "وسط البلد، شارع طلعت حرب",
//      "severity": "high",   // "high" | "medium" | "low"
//      "status": "جاري التعامل",
//      "current_volunteers": 12,
//      "total_volunteers": 87,
//      "lat": 30.044,
//      "lng": 31.235,
//      "created_at": "2024-01-01T12:00:00Z"
//    }, ...
//  ]
// ─────────────────────────────────────────────────────────

import '../core/localization/app_strings.dart';
import '../core/auth/auth_token_store.dart';

class AlertModel {
  final int id;
  final String type;
  final String location;
  final String severity;   // "high" | "medium" | "low"
  final String status;
  final int currentVolunteers;
  final int totalVolunteers;
  final double lat;
  final double lng;
  final DateTime? createdAt;

  const AlertModel({
    required this.id,
    required this.type,
    required this.location,
    required this.severity,
    required this.status,
    required this.currentVolunteers,
    required this.totalVolunteers,
    required this.lat,
    required this.lng,
    this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int,
      type: json['type'] as String,
      location: json['location'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      currentVolunteers: json['current_volunteers'] as int? ?? 0,
      totalVolunteers: json['total_volunteers'] as int? ?? 50,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Returns a human-readable time string like "من 5 دقايق"
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'دلوقتي';
    if (diff.inMinutes < 60) return 'من ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'من ${diff.inHours} ساعة';
    return 'من ${diff.inDays} يوم';
  }
}
