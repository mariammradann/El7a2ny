import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/help_initiative_model.dart';
import '../models/sponsor_model.dart';
import '../models/sensor_model.dart';
import '../data/models/emergency_contact.dart';
import '../models/alert_model.dart';
import '../models/incident_model.dart';

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
}