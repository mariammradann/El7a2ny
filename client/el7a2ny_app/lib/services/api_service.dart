import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/incident_model.dart';
import '../models/help_initiative_model.dart';
import '../models/sponsor_model.dart';
import '../models/sensor_model.dart';
import '../data/models/emergency_contact.dart';
import '../models/alert_model.dart'; // تأكد من وجود هذا الـ import

class ApiService {
  static const String baseUrl = "http://localhost:8000";
  static bool useMock = false; 

  // 1. جلب بيانات البروفايل (كانت ناقصة في الكود الأخير)
  static Future<UserModel> fetchUserProfile() async {
    final response = await http.get(Uri.parse("$baseUrl/api/profile/"));
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to load profile");
  }

  // 2. إرسال استغاثة
  static Future<void> sendEmergencyAlert({
    required String userId,
    required String type,
    required double lat,
    required double lng,
    String? description,
  }) async {
    await http.post(
      Uri.parse("$baseUrl/api/incidents/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "category": type,
        "latitude": lat,
        "longitude": lng,
        "description": description ?? "",
      }),
    );
  }

  // 3. جلب البلاغات مع تحويلها لـ AlertModel (عشان صفحة alerts_tab)
  static Future<List<AlertModel>> fetchAlerts() async {
    final response = await http.get(Uri.parse("$baseUrl/api/incidents/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      // بنحول الـ JSON لـ AlertModel مباشرة عشان الـ UI مستنيه
      return data.map((item) => AlertModel.fromJson(item)).toList();
    }
    return [];
  }

  // 4. دالة الاستجابة للبلاغ (كانت مفقودة)
  static Future<void> respondToAlert(int alertId) async {
    await http.post(Uri.parse("$baseUrl/api/alerts/$alertId/respond/"));
  }

  // 5. جلب إحصائيات الأدمن (كانت مفقودة)
  static Future<dynamic> fetchAdminStats() async {
    final response = await http.get(Uri.parse("$baseUrl/api/admin/stats/"));
    return jsonDecode(response.body);
  }

  // 6. جلب إحصائيات الداشبورد (كانت مفقودة)
  static Future<dynamic> fetchDashboardStats() async {
    final response = await http.get(Uri.parse("$baseUrl/api/dashboard/stats/"));
    return jsonDecode(response.body);
  }

  // 7. تحديث البروفايل
  static Future<void> updateUserProfile(UserModel user) async {
    await http.put(
      Uri.parse("$baseUrl/api/profile/update/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );
  }

  // 8. جلب المبادرات
  static Future<List<HelpInitiative>> fetchHelpInitiatives() async {
    final response = await http.get(Uri.parse("$baseUrl/api/initiatives/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => HelpInitiative.fromJson(item)).toList();
    }
    return [];
  }

  // 9. جلب المستخدمين
  static Future<List<UserModel>> fetchUserList() async {
    final response = await http.get(Uri.parse("$baseUrl/api/admin/users/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => UserModel.fromJson(item)).toList();
    }
    return [];
  }

  // 10. جلب الحساسات
  static Future<List<SensorModel>> fetchSensors() async {
    final response = await http.get(Uri.parse("$baseUrl/api/sensors/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => SensorModel.fromJson(item)).toList();
    }
    return [];
  }

  // 11. جهات الاتصال
  static Future<List<EmergencyContact>> fetchEmergencyContacts() async {
    final response = await http.get(Uri.parse("$baseUrl/api/contacts/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => EmergencyContact.fromJson(item)).toList();
    }
    return [];
  }

  // 12. الرعاة
  static Future<List<SponsorModel>> fetchSponsors() async {
    final response = await http.get(Uri.parse("$baseUrl/api/sponsors/"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => SponsorModel.fromJson(item)).toList();
    }
    return [];
  }
}