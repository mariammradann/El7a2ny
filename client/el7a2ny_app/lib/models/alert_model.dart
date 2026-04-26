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
import '../services/session_service.dart';
import '../core/auth/auth_token_store.dart';

class AlertModel {
  final String id;
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
    // ✅ التعديل 1: شيلنا toString() لأن الموديل مستني int
    // وحولنا الـ ID لـ int بشكل صريح
    id: (json['incident_id'] ?? json['id'] ?? '').toString(), 

    status: json['status'] ?? 'active',
    severity: json['severity'] ?? 'medium',
    totalVolunteers: json['total_volunteers'] ?? 0,
    currentVolunteers: json['current_volunteers'] ?? 0,
    type: json['category'] ?? json['type'] ?? 'emergency',
    description: json['description'] ?? '',
    location: json['location_name'] ?? json['city'] ?? 'Unknown Location',
    
    // تأكد إن الإحداثيات double
    lat: (json['lat'] ?? 0.0).toDouble(),
    lng: (json['lng'] ?? 0.0).toDouble(),
    
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),

    // ✅ التعديل 2: قارن الـ user_id بتاع البلاغ مع الـ user_id بتاع اليوزر اللي مسجل دخول
    isMyAlert: (json['user']?.toString() == AuthTokenStore.userId), 
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
