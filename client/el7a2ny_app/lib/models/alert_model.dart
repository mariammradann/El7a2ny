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
  final String? description;
  final bool isMyAlert;

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
    this.description,
    this.isMyAlert = false,
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
      description: json['description'] as String?,
      isMyAlert: json['is_my_alert'] as bool? ?? false,
    );
  }

  String getLocalizedType(AppStrings loc) {
    switch (type.toLowerCase()) {
      case 'fire': return loc.typeFire;
      case 'medical': return loc.typeMedical;
      case 'security': return loc.typeSecurity;
      default: return type;
    }
  }

  String getLocalizedStatus(AppStrings loc) {
    switch (status.toLowerCase()) {
      case 'active': return loc.statusActive;
      case 'dealing': return loc.statusDealing;
      case 'inway': return loc.statusInWay;
      case 'resolved': return loc.statusResolved;
      default: return status;
    }
  }

  String getLocalizedLocation(AppStrings loc) {
    switch (location.toLowerCase()) {
      case 'downtown': return loc.locDowntown;
      case 'nasrcity': return loc.locNasrCity;
      case 'maadi': return loc.locMaadi;
      default: return location;
    }
  }

  String getLocalizedSeverity(AppStrings loc) {
    switch (severity.toLowerCase()) {
      case 'high': return loc.severityHigh;
      case 'medium': return loc.severityMedium;
      case 'low': return loc.severityLow;
      default: return severity;
    }
  }

  /// Returns a human-readable time string localized
  String timeAgoLocalized(AppStrings loc) {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    final isAr = loc.isAr;
    
    if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) return isAr ? 'من ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isAr ? 'من ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    return isAr ? 'من ${diff.inDays} يوم' : '${diff.inDays}d ago';
  }
}
