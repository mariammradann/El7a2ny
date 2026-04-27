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

<<<<<<< HEAD
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
}
=======
  static final List<EmergencyContact> _mockContacts = [
    EmergencyContact(name: 'أحمد (الأب)', phone: '+20 10 123 4567', relationship: 'أب'),
    EmergencyContact(name: 'فاطمة (الأم)', phone: '+20 11 987 6543', relationship: 'أم'),
    EmergencyContact(name: 'د. محمد (طبيب العائلة)', phone: '+20 12 555 7777', relationship: 'طبيب'),
  ];

  static final List<CommunityPost> _mockPosts = [
    CommunityPost(
      id: 1, authorName: 'Ahmed Kamal', authorRole: 'volunteer',
      content: 'شكراً جداً للمسعفين اللي ساعدوا في حادثة طريق الجلاء النهاردة. الاستجابة كانت سريعة جداً.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    CommunityPost(
      id: 2, authorName: 'Mona El-Sayed', authorRole: 'citizen',
      content: 'متاح أجهزة أكسجين للمساعدة في حالات الطوارئ بمنطقة المعادي. اللي محتاج يتواصل معايا.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      hasAction: true, actionLabel: 'تواصل الآن',
    ),
    CommunityPost(
      id: 3, authorName: 'El7a2ny System', authorRole: 'system',
      content: 'تم تحديث خريطة وحدات الإسعاف لتشمل المناطق الجديدة في التجمع الخامس.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final UserModel _mockCurrentUser = UserModel(
    id: 1,
    firstName: 'Adnan',
    lastName: 'El7a2ny',
    email: 'adnan@el7a2ny.com',
    phone: '+20 100 000 0000',
    role: 'citizen',
    status: 'active',
    nationalId: '29001011234567',
    birthDate: '1990-01-01',
    gender: 'male',
    bloodType: 'O+',
    hasVehicle: true,
    volunteerEnabled: true,
    skills: 'CPR, First Aid, Firefighting',
    smartWatchModel: 'Apple Watch Series 9',
    sensorModel: 'Pulse Oximeter',
    emergencyContacts: _mockContacts,
    isPlus: false,
    planType: null,
    subscriptionDate: null,
    renewalDate: null,
  );

  static final List<UserModel> _mockUsers = [
    UserModel(
      id: 1,
      firstName: 'Ahmed',
      lastName: 'Ali',
      email: 'ahmed@example.com',
      role: 'citizen',
      status: 'active',
      phone: '0101234567',
      nationalId: '29501011234567',
      birthDate: '1995-05-12',
      gender: 'male',
      bloodType: 'A+',
      emergencyContacts: [_mockContacts[0]],
    ),
    UserModel(
      id: 2,
      firstName: 'Sara',
      lastName: 'Mohamed',
      email: 'sara@example.com',
      role: 'volunteer',
      status: 'pending',
      phone: '0111234567',
      nationalId: '29805051234567',
      birthDate: '1998-08-20',
      gender: 'female',
      bloodType: 'B-',
      volunteerEnabled: true,
      skills: 'Nursing, Emergency Response',
      emergencyContacts: [_mockContacts[1]],
    ),
  ];

  static final AdminStats _mockAdminStats = AdminStats(
    totalUsers: 1240,
    activeAlerts: 42,
    avgResponseTime: "3:45",
    successRate: 0.98,
    weeklyEfficiency: [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.3],
  );

  static final List<HelpInitiative> _mockHelpInitiatives = [
    HelpInitiative(
      id: 1,
      title: 'وجبات مجانية للأسر المحتاجة',
      description: 'نقوم بتوزيع وجبات ساخنة يومياً للأسر المحتاجة في منطقة مدينة نصر. نحتاج متطوعين للمساعدة في الطبخ والتوزيع.',
      authorName: 'أحمد محمد',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      authorRole: 'volunteer',
      category: HelpCategory.food,
      location: 'مدينة نصر، القاهرة',
      latitude: 30.0444,
      longitude: 31.2357,
      contactInfo: ['01012345678', 'ahmed@help.org'],
      participantsCount: 15,
    ),
    HelpInitiative(
      id: 2,
      title: 'ملابس شتوية للأطفال',
      description: 'جمع تبرعات ملابس شتوية للأطفال في المناطق الشعبية. نقبل التبرعات من جميع الأحجام.',
      authorName: 'فاطمة أحمد',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      authorRole: 'citizen',
      category: HelpCategory.clothing,
      location: 'حلوان، القاهرة',
      latitude: 29.8414,
      longitude: 31.3008,
      contactInfo: ['01198765432'],
      participantsCount: 8,
    ),
    HelpInitiative(
      id: 3,
      title: 'دعم مالي للطلاب الجامعيين',
      description: 'صندوق لمساعدة الطلاب الجامعيين من الأسر ذات الدخل المحدود. نساعد في دفع المصاريف الدراسية.',
      authorName: 'محمد علي',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      authorRole: 'volunteer',
      category: HelpCategory.financial,
      location: 'الجيزة، القاهرة',
      latitude: 30.0131,
      longitude: 31.2089,
      contactInfo: ['01234567890', 'support@studentshelp.eg'],
      participantsCount: 23,
    ),
    HelpInitiative(
      id: 4,
      title: 'عيادة طبية متنقلة',
      description: 'فريق طبي يقدم خدمات طبية مجانية في القرى النائية. نحتاج أطباء وممرضين متطوعين.',
      authorName: 'د. سارة محمود',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      authorRole: 'volunteer',
      category: HelpCategory.medical,
      location: 'بني سويف',
      latitude: 29.0661,
      longitude: 31.0994,
      contactInfo: ['01555555555'],
      participantsCount: 12,
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
}



// ─────────────────────────────────────────────────────────
//  EXCEPTION
// ─────────────────────────────────────────────────────────
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}
>>>>>>> origin/flutter
