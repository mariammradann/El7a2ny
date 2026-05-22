import 'dart:convert';
import 'dart:ui' as ui;
import '../core/localization/app_strings.dart';
import '../core/auth/auth_token_store.dart';

class AlertModel {
  final String id;
  final String type;
  final String category;
  final String location;
  final String severity; // "high" | "medium" | "low"
  final String status;
  final int currentVolunteers;
  final int totalVolunteers;
  final double lat;
  final double lng;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final String? description;
  final bool isMyAlert;
  final String? address;
  final List<String>? mediaUrls;
  final String? aiSummary;
  final String? aiInstructions;
  final Map<String, dynamic>? aiAnalysis;
  final String? reporterName;
  final String? volunteerInstructions;
  final List<String>? aiInstructionsList;
  final String? aiSummaryEn;
  final String? aiSummaryAr;
  final String? aiInstructionsEn;
  final String? aiInstructionsAr;
  final List<String>? aiInstructionsListEn;
  final List<String>? aiInstructionsListAr;
  final String? volunteerInstructionsEn;
  final String? volunteerInstructionsAr;

  const AlertModel({
    required this.id,
    required this.type,
    this.category = '',
    required this.location,
    required this.severity,
    required this.status,
    required this.currentVolunteers,
    required this.totalVolunteers,
    required this.lat,
    required this.lng,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.description,
    this.isMyAlert = false,
    this.address,
    this.mediaUrls,
    this.aiSummary,
    this.aiInstructions,
    this.aiAnalysis,
    this.reporterName,
    this.volunteerInstructions,
    this.aiInstructionsList,
    this.aiSummaryEn,
    this.aiSummaryAr,
    this.aiInstructionsEn,
    this.aiInstructionsAr,
    this.aiInstructionsListEn,
    this.aiInstructionsListAr,
    this.volunteerInstructionsEn,
    this.volunteerInstructionsAr,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final currentUserId = AuthTokenStore.userId;
    final alertOwnerId = json['user']?.toString();
    
    // Parse media files
    List<String>? mediaUrls;
    if (json['media_files'] != null) {
      if (json['media_files'] is List) {
        mediaUrls = List<String>.from(json['media_files']);
      }
    }

    final isAr = ui.PlatformDispatcher.instance.locale.languageCode == 'ar';

    // Helper helper to get localized value from a bilingual json structure
    String? getBilingualString(dynamic value, bool preferAr) {
      if (value == null) return null;
      if (value is Map) {
        return (preferAr ? value['ar'] ?? value['en'] : value['en'] ?? value['ar'])?.toString();
      }
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          try {
            final parsed = jsonDecode(trimmed);
            if (parsed is Map) {
              return (preferAr ? parsed['ar'] ?? parsed['en'] : parsed['en'] ?? parsed['ar'])?.toString();
            }
          } catch (_) {}
        }
        return value;
      }
      return value.toString();
    }

    List<String>? getBilingualList(dynamic value, bool preferAr) {
      if (value == null) return null;
      if (value is Map) {
        final list = preferAr ? value['ar'] ?? value['en'] : value['en'] ?? value['ar'];
        if (list is List) {
          return List<String>.from(list.map((item) => getBilingualString(item, preferAr) ?? ''));
        }
      }
      if (value is List) {
        return List<String>.from(value.map((item) => getBilingualString(item, preferAr) ?? ''));
      }
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          try {
            final parsed = jsonDecode(trimmed);
            if (parsed is Map) {
              final list = preferAr ? parsed['ar'] ?? parsed['en'] : parsed['en'] ?? parsed['ar'];
              if (list is List) {
                return List<String>.from(list.map((item) => getBilingualString(item, preferAr) ?? ''));
              }
            }
          } catch (_) {}
        }
      }
      return null;
    }

    final aiAnalysisMap = json['ai_analysis'] is Map
        ? Map<String, dynamic>.from(json['ai_analysis'])
        : null;

    final rawSummary = json['ai_summary'] ?? (aiAnalysisMap != null ? aiAnalysisMap['summary'] : null);
    final summaryEn = getBilingualString(rawSummary, false);
    final summaryAr = getBilingualString(rawSummary, true);

    final rawInstructions = aiAnalysisMap != null ? aiAnalysisMap['instructions'] : null;
    final instructionsListEn = getBilingualList(rawInstructions, false);
    final instructionsListAr = getBilingualList(rawInstructions, true);

    final instructionsEn = json['ai_instructions'] ?? (instructionsListEn != null ? instructionsListEn.join('\n') : null);
    final instructionsAr = json['ai_instructions'] ?? (instructionsListAr != null ? instructionsListAr.join('\n') : null);
    
    final rawVolunteerInstructions = aiAnalysisMap != null ? aiAnalysisMap['responder_briefing'] : null;
    final volunteerInstructionsEn = getBilingualString(rawVolunteerInstructions, false);
    final volunteerInstructionsAr = getBilingualString(rawVolunteerInstructions, true);

    return AlertModel(
      id: (json['incident_id'] ?? json['id'] ?? '').toString(),
      status: json['status'] ?? 'reported',
      severity: json['severity'] ?? 'medium',
      totalVolunteers: json['total_volunteers'] ?? 0,
      currentVolunteers: json['current_volunteers'] ?? 0,
      type: json['category'] ?? json['type'] ?? 'emergency',
      category: json['category'] ?? json['type'] ?? 'emergency',
      description: json['description'] ?? '',
      location: json['location_name'] ?? json['city'] ?? 'Unknown Location',
      address: json['address'], // ✅ Critical fix for the UI update
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      latitude: json['lat'] != null ? (json['lat']).toDouble() : null,
      longitude: json['lng'] != null ? (json['lng']).toDouble() : null,
      createdAt: json['created_at'] != null
      
    ? DateTime.parse(json['created_at'].toString().split('+')[0] + 'Z').toLocal()
    : DateTime.now(),
          
      isMyAlert: currentUserId != null && alertOwnerId == currentUserId,
      mediaUrls: mediaUrls,
      aiSummary: isAr ? summaryAr : summaryEn,
      aiInstructions: isAr ? instructionsAr : instructionsEn,
      aiAnalysis: aiAnalysisMap,
      reporterName: json['reporter_name'],
      volunteerInstructions: isAr ? volunteerInstructionsAr : volunteerInstructionsEn,
      aiInstructionsList: isAr ? instructionsListAr : instructionsListEn,
      aiSummaryEn: summaryEn,
      aiSummaryAr: summaryAr,
      aiInstructionsEn: instructionsEn,
      aiInstructionsAr: instructionsAr,
      aiInstructionsListEn: instructionsListEn,
      aiInstructionsListAr: instructionsListAr,
      volunteerInstructionsEn: volunteerInstructionsEn,
      volunteerInstructionsAr: volunteerInstructionsAr,
    );
  }

  String? getSummary(bool isAr) => isAr ? aiSummaryAr ?? aiSummary : aiSummaryEn ?? aiSummary;
  String? getInstructions(bool isAr) => isAr ? aiInstructionsAr ?? aiInstructions : aiInstructionsEn ?? aiInstructions;
  List<String>? getInstructionsList(bool isAr) => isAr ? aiInstructionsListAr ?? aiInstructionsList : aiInstructionsListEn ?? aiInstructionsList;
  String? getVolunteerInstructions(bool isAr) => isAr ? volunteerInstructionsAr ?? volunteerInstructions : volunteerInstructionsEn ?? volunteerInstructions;

  // --- Helper Methods ---

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

String timeAgoLocalized(AppStrings loc) {
  if (createdAt == null) return '';
  
  // BOTH must be UTC for the subtraction to work
  final now = DateTime.now().toUtc(); 
  final diff = now.difference(createdAt!);
  
  final isAr = loc.isAr;
  final minutes = diff.inMinutes; // Remove .abs() for a second to see if it's negative

  if (minutes < 1) return isAr ? 'الآن' : 'Just now';
  if (minutes < 60) return isAr ? 'من $minutes دقيقة' : '${minutes}m ago';
  
  final hours = diff.inHours;
  if (hours < 24) return isAr ? 'من $hours ساعة' : '${hours}h ago';
  
  final days = diff.inDays;
  return isAr ? 'من $days يوم' : '${days}d ago';
}
} 