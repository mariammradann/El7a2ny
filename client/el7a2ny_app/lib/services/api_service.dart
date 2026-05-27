import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/help_initiative_model.dart';
import '../models/sponsor_model.dart';
import '../models/sensor_model.dart';
import '../data/models/emergency_contact.dart';
import '../models/alert_model.dart';
import '../models/incident_model.dart';
import '../models/activity_history_model.dart';
import '../models/course_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint; // Needed for kIsWeb
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Needed for MediaType
import 'package:cross_file/cross_file.dart'; // Usually comes with image_picker
import '../core/config/api_config.dart';
import '../core/auth/auth_token_store.dart';
import 'session_service.dart'; // adjust path if needed

// ─────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────

class ApiService {
  // استخدم IP جهازك بدل localhost لو بتجرب من موبايل حقيقي (مثلاً 192.168.1.5)
  // الـ 10.0.2.2 مخصصة للأندرويد إيموليتور للوصول للسيرفر المحلي
  static String get baseUrl => ApiConfig.baseUrl;
  static bool useMock = false;

  // --- 1. نظام جلب البروفايل (الديناميكي) ---
  static Future<UserModel> fetchUserProfile([String? userId]) async {
    String? idToUse = userId;

    // محاولة جلب الـ ID من التخزين لو متبعنش للدالة
    if (idToUse == null) {
      final prefs = await SharedPreferences.getInstance();
      idToUse = prefs.getString('user_id');
      print("🔎 Fetched User ID from Prefs: $idToUse");
    }

    if (idToUse == null || idToUse.isEmpty) {
      print("🚨 Error: No user_id found in SharedPreferences!");
      throw Exception("Authentication required: Please login again.");
    }

    final url = Uri.parse("$baseUrl/api/profile/$idToUse/");
    print("🌐 Requesting Profile from: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else if (response.statusCode == 404) {
        print("🚨 Django returned 404: User $idToUse not found in DB.");
        throw Exception("User profile not found in database.");
      } else {
        print("🚨 Server Error: ${response.statusCode} - ${response.body}");
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 Network Error: $e");
      rethrow;
    }
  }

  // --- 2. إرسال استغاثة (Emergency Alert) ---
  static Future<void> sendEmergencyAlert({
    required String userId,
    required String type,
    required double lat,
    required double lng,
    String? description,
  }) async {
    double formattedLat = double.parse(lat.toStringAsFixed(7));
    double formattedLng = double.parse(lng.toStringAsFixed(7));

    final response = await http.post(
      Uri.parse("$baseUrl/api/incidents/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "category": type,
        "latitude": formattedLat,
        "longitude": formattedLng,
        "address": "Current Location",
        "description": description ?? "",
      }),
    );

    if (response.statusCode != 201) {
      print("🚨 SOS Error: ${response.body}");
      throw Exception("Failed to send emergency alert");
    }
  }

  // --- 2b. إرسال استغاثة مع الملفات (Emergency Alert with Media) ---

  // ... other imports ...

  static Future<Map<String, dynamic>> sendEmergencyAlertWithMedia({
    required String userId,
    required String type,
    required double lat,
    required double lng,
    String? description,
    required int totalVolunteers,
    required List<Map<String, String>> evidenceItems,
    bool isForMe = true,
  }) async {
    double formattedLat = double.parse(lat.toStringAsFixed(7));
    double formattedLng = double.parse(lng.toStringAsFixed(7));

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/api/incidents/"),
    );

    // 1. Add Basic Fields
    request.fields['user_id'] = userId;
    request.fields['category'] = type;
    request.fields['description'] = description ?? "";
    request.fields['latitude'] = formattedLat.toString();
    request.fields['longitude'] = formattedLng.toString();
    request.fields['address'] = "Current Location";
    request.fields['total_volunteers'] = totalVolunteers.toString();
    request.fields['is_for_me'] = isForMe.toString();

    // 2. Add Media Files
    print("📸 Processing ${evidenceItems.length} evidence items...");

    for (int i = 0; i < evidenceItems.length; i++) {
      final item = evidenceItems[i];
      final filePath = item['path'] ?? '';
      final fileType = item['type'] ?? 'image';

      if (filePath.isEmpty || filePath.startsWith('mock_')) continue;

      try {
        if (kIsWeb) {
          // --- WEB FIX: Use XFile to read bytes ---
          final xFile = XFile(filePath);
          final bytes = await xFile.readAsBytes();

          request.files.add(
            http.MultipartFile.fromBytes(
              'media_files', // Must match Django key
              bytes,
              filename: xFile.name.isEmpty ? 'upload_$i.jpg' : xFile.name,
              contentType: MediaType(
                fileType,
                fileType == 'video' ? 'mp4' : 'jpeg',
              ),
            ),
          );
          print("✅ Added file via bytes (Web)");
        } else {
          // --- MOBILE/DESKTOP: Normal Path Logic ---
          final file = File(filePath);
          if (await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'media_files',
                filePath,
                contentType: MediaType(
                  fileType,
                  fileType == 'video' ? 'mp4' : 'jpeg',
                ),
              ),
            );
            print("✅ Added file via path (Mobile)");
          }
        }
      } catch (e) {
        print("❌ Error processing file [$i]: $e");
      }
    }

    print("📸 Final files in request: ${request.files.length}");

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📤 Response Status: ${response.statusCode}");
      print("📤 Response Body: ${response.body}");

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          "Failed to send alert (Status: ${response.statusCode})",
        );
      }
      print("✅ Emergency alert sent successfully");
      return json.decode(response.body);
    } catch (e) {
      print("🚨 Network Error: $e");
      rethrow;
    }
  }

  // --- 3. جلب البيانات العامة (Lists) ---
  static Future<List<AlertModel>> fetchAlerts({String? userId, bool all = false}) async {
    try {
      final url = userId != null
          ? "$baseUrl/api/incidents/?user_id=$userId"
          : (all ? "$baseUrl/api/incidents/?all=true" : "$baseUrl/api/incidents/");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => AlertModel.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching alerts: $e");
    }
    return [];
  }

  static Future<AlertModel?> fetchAlertDetails(String alertId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/incidents/$alertId/"),
      );
      if (response.statusCode == 200) {
        return AlertModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("Error fetching alert details: $e");
    }
    return null;
  }

  static Future<List<SensorModel>> fetchSensors() async {
    List<SensorModel> serverSensors = [];
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/sensors/"));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        serverSensors = data.map((item) => SensorModel.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching sensors from server: $e");
    }

    final localSensors = await getLocalSensors();
    final List<SensorModel> allSensors = [...serverSensors];
    for (var local in localSensors) {
      if (!allSensors.any((s) => s.id == local.id)) {
        allSensors.add(local);
      }
    }
    return allSensors;
  }

  static Future<List<SensorModel>> getLocalSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('local_sensors');
      if (raw == null || raw.isEmpty) return [];
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => SensorModel.fromJson(item)).toList();
    } catch (e) {
      print("Error reading local sensors: $e");
      return [];
    }
  }

  static Future<void> saveLocalSensor(SensorModel sensor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<SensorModel> current = await getLocalSensors();
      
      int newId = sensor.id;
      if (newId <= 0) {
        int maxId = 1000;
        for (var s in current) {
          if (s.id > maxId) maxId = s.id;
        }
        newId = maxId + 1;
      }
      
      final updatedSensor = SensorModel(
        id: newId,
        type: sensor.type,
        value: sensor.value,
        unit: sensor.unit,
        status: sensor.status,
        lat: sensor.lat,
        lng: sensor.lng,
        alertLevel: sensor.alertLevel,
        alertLabel: sensor.alertLabel,
        isAlert: sensor.isAlert,
        humidity: sensor.humidity,
        userId: sensor.userId,
        userName: sensor.userName,
        updatedAt: sensor.updatedAt,
      );

      current.add(updatedSensor);
      final String encoded = jsonEncode(current.map((s) => s.toJson()).toList());
      await prefs.setString('local_sensors', encoded);
    } catch (e) {
      print("Error saving local sensor: $e");
    }
  }

  /// Fetch all sensors and filter for fire alerts (ALERT or CRITICAL status)
  static Future<List<SensorModel>> fetchFireAlerts() async {
    try {
      final sensors = await fetchSensors();
      // Filter for fire sensors (heat type) with ALERT or CRITICAL status
      return sensors
          .where((s) =>
              s.type == 'heat' &&
              (s.status == 'danger' || s.status == 'critical') &&
              (s.alertLevel == 'ALERT' || s.alertLevel == 'CRITICAL'))
          .toList();
    } catch (e) {
      print('Error fetching fire alerts: $e');
      return [];
    }
  }

  static Future<List<HelpInitiative>> fetchHelpInitiatives() async {
    final response = await http.get(Uri.parse("$baseUrl/api/initiatives/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => HelpInitiative.fromJson(item)).toList();
    }
    return [];
  }

  static Future<bool> createHelpInitiative(HelpInitiative initiative) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/initiatives/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(initiative.toJson()),
      );
      print(
        "📤 Post Initiative Response: ${response.statusCode} - ${response.body}",
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("🚨 Error creating initiative: $e");
      return false;
    }
  }

  static Future<bool> deleteHelpInitiative(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/initiatives/$id/"),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print("🚨 Error deleting initiative: $e");
      return false;
    }
  }

  static Future<bool> updateHelpInitiative(HelpInitiative initiative) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/initiatives/${initiative.id}/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(initiative.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("🚨 Error updating initiative: $e");
      return false;
    }
  }

  static Future<List<SponsorModel>> fetchSponsors({
    bool isArabic = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/sponsors/?lang=${isArabic ? 'ar' : 'en'}"),
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => SponsorModel.fromJson(item)).toList();
      }
    } catch (e) {
      print("🚨 Error fetching sponsors: $e");
    }
    return [];
  }

  static Future<bool> submitSponsorRequest({
    required String companyName,
    required String contactPerson,
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final response = await http.post(
        Uri.parse("$baseUrl/api/sponsors/apply/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_name": companyName,
          "contact_person": contactPerson,
          "phone_number": phoneNumber,
          "message": message,
          "user_id": userId,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("🚨 Error submitting sponsor request: $e");
      return false;
    }
  }

  static Future<List<dynamic>> fetchSponsorRequests() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/admin/sponsors/requests/"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print("🚨 Error fetching sponsor requests: $e");
    }
    return [];
  }

  static Future<bool> respondToSponsorRequest(
    String requestId,
    String action,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/admin/sponsors/requests/$requestId/respond/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": action}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("🚨 Error responding to sponsor request: $e");
      return false;
    }
  }

  static Future<bool> reportFakeIncident(String incidentId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/incidents/$incidentId/report-fake/"),
        headers: {"Content-Type": "application/json"},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("🚨 Error reporting fake incident: $e");
      return false;
    }
  }

  static Future<List<dynamic>> fetchAdminLogs() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/admin/logs/"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print("🚨 Error fetching admin logs: $e");
    }
    return [];
  }

  static Future<List<EmergencyContact>> fetchEmergencyContacts() async {
    final response = await http.get(Uri.parse("$baseUrl/api/contacts/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => EmergencyContact.fromJson(item)).toList();
    }
    return [];
  }

  // --- 4. إحصائيات الأدمن والمستخدمين ---
  static Future<dynamic> fetchAdminStats() async {
    final response = await http.get(Uri.parse("$baseUrl/api/admin/stats/"));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to fetch admin stats");
  }

  /// GET /api/profile/history/
  static Future<List<ActivityHistoryModel>> fetchActivityHistory({
    bool isArabic = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return [];

    final url =
        "$baseUrl/api/profile/history/?user_id=$userId&lang=${isArabic ? 'ar' : 'en'}";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data
          .map((e) => ActivityHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<dynamic> fetchDashboardStats() async {
    final response = await http.get(Uri.parse("$baseUrl/api/dashboard/stats/"));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to fetch dashboard stats");
  }

  static Future<List<UserModel>> fetchUserList() async {
    final response = await http.get(Uri.parse("$baseUrl/api/admin/users/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => UserModel.fromJson(item)).toList();
    }
    return [];
  }

  // --- 5. عمليات التحديث والاستجابة ---
  static Future<void> updateUserProfile(UserModel user) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/profile/update/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );
    if (response.statusCode != 200) throw Exception("Failed to update profile");
  }

  static Future<void> respondToAlert(
    String alertId, {
    double? lat,
    double? lng,
    int responseSeconds = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    final response = await http.post(
      Uri.parse('$baseUrl/alerts/$alertId/respond/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'response_seconds': responseSeconds,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      }),
    );

    if (response.statusCode == 409) throw Exception('Already responded');
    if (response.statusCode != 201) throw Exception('Failed to respond');
  }

  static Future<void> updateResponderLocation(
    String incidentId,
    double lat,
    double lng,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    await http.patch(
      Uri.parse('$baseUrl/alerts/$incidentId/responders/location/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'lat': lat, 'lng': lng}),
    );
  }

  static Future<void> updateAlertStatus(
    String alertId,
    String newStatus,
  ) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/api/incidents/$alertId/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": newStatus}),
    );
    if (response.statusCode != 200 &&
        response.statusCode != 204 &&
        response.statusCode != 201) {
      throw Exception("Failed to update alert status");
    }
  }

  static final List<EmergencyContact> _mockContacts = [
    EmergencyContact(
      name: 'أحمد (الأب)',
      phone: '+20 10 123 4567',
      relationship: 'أب',
    ),
    EmergencyContact(
      name: 'فاطمة (الأم)',
      phone: '+20 11 987 6543',
      relationship: 'أم',
    ),
    EmergencyContact(
      name: 'د. محمد (طبيب العائلة)',
      phone: '+20 12 555 7777',
      relationship: 'طبيب',
    ),
  ];

  static final List<ActivityHistoryModel> _mockHistory = [
    ActivityHistoryModel(
      id: 1,
      title: 'Emergency Reported',
      description: 'Reported a Fire Emergency in Downtown.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: 'emergency',
    ),
    ActivityHistoryModel(
      id: 2,
      title: 'Volunteer Action',
      description: 'Joined the Medical Alert response team in Nasr City.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: 'volunteer',
    ),
    ActivityHistoryModel(
      id: 3,
      title: 'Profile Updated',
      description: 'Updated your personal information and emergency contacts.',
      date: DateTime.now().subtract(const Duration(days: 10)),
      type: 'account',
    ),
    ActivityHistoryModel(
      id: 4,
      title: 'Subscription Renewed',
      description: 'Your Premium Safety plan was successfully renewed.',
      date: DateTime.now().subtract(const Duration(days: 30)),
      type: 'account',
    ),
  ];

  static final List<ActivityHistoryModel> _mockHistoryAr = [
    ActivityHistoryModel(
      id: 1,
      title: 'تم الإبلاغ عن حالة طوارئ',
      description: 'تم الإبلاغ عن حريق في وسط المدينة.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: 'emergency',
    ),
    ActivityHistoryModel(
      id: 2,
      title: 'مشاركة تطوعية',
      description: 'انضممت إلى فريق الاستجابة للطوارئ الطبية في مدينة نصر.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: 'volunteer',
    ),
    ActivityHistoryModel(
      id: 3,
      title: 'تحديث الملف الشخصي',
      description: 'قمت بتحديث معلوماتك الشخصية وجهات اتصال الطوارئ.',
      date: DateTime.now().subtract(const Duration(days: 10)),
      type: 'account',
    ),
    ActivityHistoryModel(
      id: 4,
      title: 'تجديد الاشتراك',
      description: 'تم تجديد خطة الاشتراك المميزة بنجاح.',
      date: DateTime.now().subtract(const Duration(days: 30)),
      type: 'account',
    ),
  ];

  // ========== ADMIN METHODS ==========

  /// Update user by admin
  static Future<UserModel> adminUpdateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/admin/users/$userId/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to update user: ${response.statusCode}");
    } catch (e) {
      print("Error updating user: $e");
      rethrow;
    }
  }

  /// Delete/deactivate user by admin
  static Future<void> adminDeleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/admin/users/$userId/delete/"),
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to delete user: ${response.statusCode}");
      }
    } catch (e) {
      print("Error deleting user: $e");
      rethrow;
    }
  }

  /// Verify user by admin
  static Future<void> adminVerifyUser(String userId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/admin/users/$userId/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"verification_status": "verified"}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to verify user: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Error verifying user: $e");
      rethrow;
    }
  }

  /// Suspend user by admin
  static Future<void> adminSuspendUser(String userId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/admin/users/$userId/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": "inactive"}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to suspend user: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Error suspending user: $e");
      rethrow;
    }
  }

  /// Fetch all incidents for admin
  static Future<List<IncidentModel>> fetchAdminIncidents({
    String? status,
    String? userId,
  }) async {
    try {
      String url = "$baseUrl/api/admin/incidents/";
      final params = <String>[];

      if (status != null && status.isNotEmpty) {
        params.add("status=$status");
      }
      if (userId != null && userId.isNotEmpty) {
        params.add("user_id=$userId");
      }

      if (params.isNotEmpty) {
        url += "?${params.join('&')}";
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => IncidentModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching incidents: $e");
      return [];
    }
  }

  /// Search users with admin filter
  static Future<List<UserModel>> adminSearchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/admin/users/?search=$query"),
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => UserModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  /// Filter users by status
  static Future<List<UserModel>> adminFilterUsersByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/admin/users/?status=$status"),
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => UserModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Error filtering users: $e");
      return [];
    }
  }

  /// Admin: update incident status (action: monitor | cancel | resolve)
  static Future<void> adminUpdateIncident(
    String incidentId,
    String action,
  ) async {
    try {
      final userId = AuthTokenStore.userId;
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      final response = await http.patch(
        Uri.parse("$baseUrl/api/admin/incidents/$incidentId/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": action, "user_id": userId}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to update incident: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Error updating incident: $e");
      rethrow;
    }
  }

  /// Admin: delete (soft-delete) incident
static Future<void> adminDeleteIncident(String incidentId) async {
  try {
    final userId = SessionService().userId; // ← instance access
    
    final uri = Uri.parse("$baseUrl/api/admin/incidents/$incidentId/")
        .replace(queryParameters: {'user_id': userId});
    
    final response = await http.delete(uri);
    
    if (response.statusCode != 200) {
      throw Exception(
        "Failed to delete incident: ${response.statusCode} - ${response.body}",
      );
    }
  } catch (e) {
    print("Error deleting incident: $e");
    rethrow;
  }
}

  // ========== SUBSCRIPTION METHODS ==========

  /// Get user's subscription status
  static Future<Map<String, dynamic>> getUserSubscription(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/subscription/$userId/"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        "is_plus": false,
        "plan_type": null,
        "subscription_date": null,
        "renewal_date": null,
      };
    } catch (e) {
      print("Error fetching subscription: $e");
      return {
        "is_plus": false,
        "plan_type": null,
        "subscription_date": null,
        "renewal_date": null,
      };
    }
  }

  /// Subscribe or upgrade user plan
  static Future<Map<String, dynamic>> subscribeUser(
    String userId,
    String planType,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/subscription/subscribe/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "plan_type": planType, // 'monthly' or 'yearly'
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception(
        "Failed to subscribe: ${response.statusCode} - ${response.body}",
      );
    } catch (e) {
      print("Error subscribing user: $e");
      rethrow;
    }
  }

  /// Cancel user's subscription
  static Future<void> cancelSubscription(String userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/subscription/cancel/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to cancel: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Error cancelling subscription: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getLatestSensorReading(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/sensor/latest/?user_id=$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch sensor reading');
  }

  // ========== RATING METHODS ==========

  static Future<bool> submitUserRating(Map<String, dynamic> ratingData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      final dataToSend = Map<String, dynamic>.from(ratingData);
      if (userId != null) {
        dataToSend['user_id'] = userId;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/ratings/user/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(dataToSend),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error submitting user rating: $e");
      return false;
    }
  }

  static Future<bool> submitVolunteerRating(
    Map<String, dynamic> ratingData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      final dataToSend = Map<String, dynamic>.from(ratingData);
      if (userId != null) {
        dataToSend['user_id'] = userId;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/ratings/volunteer/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(dataToSend),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error submitting volunteer rating: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchIncidentResponders(
    String incidentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/alerts/$incidentId/responders/'),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ========== CHAT ENDPOINTS ==========

  static Future<List<Map<String, dynamic>>> fetchChatMessages(
    String incidentId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alerts/$incidentId/chat/'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['messages'] as List;
        return messages.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching chat messages: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> sendChatMessage({
    required String incidentId,
    required String senderId,
    required String senderName,
    required String text,
    String senderType = 'user',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/alerts/$incidentId/chat/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'sender_id': senderId,
          'sender_name': senderName,
          'sender_type': senderType,
          'text': text,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error sending chat message: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> pollChatMessages(
    String incidentId,
    String since,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alerts/$incidentId/chat/poll/?since=$since'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['messages'] as List;
        return messages.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error polling chat messages: $e');
      return [];
    }
  }

  // --- 14. فصول التدريب (Training Classes) ---
  static Future<List<CourseModel>> fetchCourses({String? userId}) async {
    try {
      final url = userId != null
          ? '$baseUrl/api/training/courses/?user_id=$userId'
          : '$baseUrl/api/training/courses/';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        return decoded.map((item) => CourseModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching training courses: $e');
      return [];
    }
  }

  static Future<bool> enrollInCourse(String courseId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/training/courses/$courseId/enroll/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error enrolling in course $courseId: $e');
      return false;
    }
  }

  static Future<bool> completeCourse(String courseId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/training/courses/$courseId/complete/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error completing course $courseId: $e');
      return false;
    }
  }

  /// Fetch all training badges earned by a user
  static Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/training/badges/$userId/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List badges = data['badges'] ?? [];
        return badges.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching user badges: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  ADMIN — EXTENDED MANAGEMENT METHODS
  // ═══════════════════════════════════════════════════════════

  /// Hard-delete an incident permanently
  static Future<void> adminHardDeleteIncident(
    String incidentId,
    String adminUserId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/incidents/$incidentId/hard-delete/?admin_user_id=$adminUserId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete incident: ${response.statusCode}');
    }
  }

  /// Fetch all community initiatives (admin)
  static Future<List<Map<String, dynamic>>> adminFetchInitiatives(
    String adminUserId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/initiatives/?admin_user_id=$adminUserId'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching admin initiatives: $e');
      return [];
    }
  }

  /// Delete a community initiative (admin)
  static Future<void> adminDeleteInitiative(
    int initiativeId,
    String adminUserId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/initiatives/$initiativeId/?admin_user_id=$adminUserId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete initiative: ${response.statusCode}');
    }
  }

  /// Fetch all training courses (admin view)
  static Future<List<Map<String, dynamic>>> adminFetchCourses(
    String adminUserId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/courses/?admin_user_id=$adminUserId'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching admin courses: $e');
      return [];
    }
  }

  /// Delete a training course (admin)
  static Future<void> adminDeleteCourse(
    String courseId,
    String adminUserId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/courses/$courseId/?admin_user_id=$adminUserId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete course: ${response.statusCode}');
    }
  }

  /// Admin creates a new training course
  static Future<Map<String, dynamic>> adminCreateCourse(
    Map<String, dynamic> courseData,
    String adminUserId,
  ) async {
    final body = {...courseData, 'admin_user_id': adminUserId};
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/courses/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create course: ${response.statusCode} ${response.body}');
  }

  /// Admin edits a training course (price, name, etc.)
  static Future<Map<String, dynamic>> adminEditCourse(
    String courseId,
    Map<String, dynamic> updates,
    String adminUserId,
  ) async {
    final body = {...updates, 'admin_user_id': adminUserId};
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/courses/$courseId/edit/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to edit course: ${response.statusCode} ${response.body}');
  }

  /// Fetch all active Plus subscriptions (admin)
  static Future<Map<String, dynamic>> adminFetchSubscriptions(
    String adminUserId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/subscriptions/?admin_user_id=$adminUserId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'subscriptions': [], 'total': 0};
    } catch (e) {
      debugPrint('Error fetching subscriptions: $e');
      return {'subscriptions': [], 'total': 0};
    }
  }

  /// Admin cancels a user's Plus subscription
  static Future<void> adminCancelSubscription(
    String userId,
    String adminUserId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/subscriptions/$userId/cancel/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'admin_user_id': adminUserId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel subscription: ${response.statusCode}');
    }
  }
}

