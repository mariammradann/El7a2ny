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

// ─────────────────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────────────────


class ApiService {
  // استخدم IP جهازك بدل localhost لو بتجرب من موبايل حقيقي (مثلاً 192.168.1.5)
  // الـ 10.0.2.2 مخصصة للأندرويد إيموليتور للوصول للسيرفر المحلي
  static const String baseUrl = "http://127.0.0.1:8000"; 
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
        "location_data": {
          "latitude": formattedLat,
          "longitude": formattedLng,
          "address": "Current Location",
        },
        "description": description ?? "",
      }),
    );

    if (response.statusCode != 201) {
      print("🚨 SOS Error: ${response.body}");
      throw Exception("Failed to send emergency alert");
    }
  }

  // --- 2b. إرسال استغاثة مع الملفات (Emergency Alert with Media) ---
  static Future<void> sendEmergencyAlertWithMedia({
    required String userId,
    required String type,
    required double lat,
    required double lng,
    String? description,
    required List<Map<String, String>> evidenceItems, // List of {path, type}
  }) async {
    double formattedLat = double.parse(lat.toStringAsFixed(7));
    double formattedLng = double.parse(lng.toStringAsFixed(7));

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/api/incidents/"),
    );

    // إضافة الحقول الأساسية
    request.fields['user_id'] = userId;
    request.fields['category'] = type;
    request.fields['description'] = description ?? "";
    request.fields['latitude'] = formattedLat.toString();
    request.fields['longitude'] = formattedLng.toString();
    request.fields['address'] = "Current Location";

    // إضافة الملفات
    for (int i = 0; i < evidenceItems.length; i++) {
      final item = evidenceItems[i];
      final filePath = item['path'] ?? '';
      final fileType = item['type'] ?? 'image';
      
      if (filePath.isNotEmpty && !filePath.startsWith('mock_')) {
        try {
          final file = File(filePath);
          if (file.existsSync()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'media_files', // اسم الحقل في Django
                filePath,
              ),
            );
          }
        } catch (e) {
          print("⚠️ Error adding file: $e");
        }
      }
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print("📤 Response Status: ${response.statusCode}");
      print("📤 Response Body: $responseBody");
      
      if (response.statusCode != 201 && response.statusCode != 200) {
        print("🚨 Emergency Alert with Media Error (${response.statusCode}): $responseBody");
        throw Exception("Failed to send emergency alert with media (Status: ${response.statusCode})");
      }
      print("✅ Emergency alert with media sent successfully");
    } catch (e) {
      print("🚨 Error sending emergency alert with media: $e");
      rethrow;
    }
  }

  // --- 3. جلب البيانات العامة (Lists) ---
  static Future<List<AlertModel>> fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/incidents/"));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => AlertModel.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching alerts: $e");
    }
    return [];
  }

  static Future<List<SensorModel>> fetchSensors() async {
    final response = await http.get(Uri.parse("$baseUrl/api/sensors/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => SensorModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<List<HelpInitiative>> fetchHelpInitiatives() async {
    final response = await http.get(Uri.parse("$baseUrl/api/initiatives/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => HelpInitiative.fromJson(item)).toList();
    }
    return [];
  }

  static Future<List<SponsorModel>> fetchSponsors() async {
    final response = await http.get(Uri.parse("$baseUrl/api/sponsors/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => SponsorModel.fromJson(item)).toList();
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
  static Future<List<ActivityHistoryModel>> fetchActivityHistory({bool isArabic = false}) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return isArabic ? _mockHistoryAr : _mockHistory;
    }
    // Using direct fetch if _get helper is missing
    final response = await http.get(Uri.parse("$baseUrl/api/profile/history/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => ActivityHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
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

  static Future<void> respondToAlert(int alertId) async {
    final response = await http.post(Uri.parse("$baseUrl/api/alerts/$alertId/respond/"));
    if (response.statusCode != 200) throw Exception("Failed to respond");
  }

  static Future<void> updateAlertStatus(String alertId, String newStatus) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/api/incidents/$alertId/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": newStatus}),
    );
    if (response.statusCode != 200 && response.statusCode != 204 && response.statusCode != 201) {
      throw Exception("Failed to update alert status");
    }
  }

  static final List<EmergencyContact> _mockContacts = [
    EmergencyContact(name: 'أحمد (الأب)', phone: '+20 10 123 4567', relationship: 'أب'),
    EmergencyContact(name: 'فاطمة (الأم)', phone: '+20 11 987 6543', relationship: 'أم'),
    EmergencyContact(name: 'د. محمد (طبيب العائلة)', phone: '+20 12 555 7777', relationship: 'طبيب'),
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
}

