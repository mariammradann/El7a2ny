import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_model.dart';
import '../models/alert_model.dart';
import '../models/dashboard_model.dart';
import '../models/sponsor_model.dart';
import '../data/models/emergency_contact.dart';
import '../models/user_model.dart';
import '../models/community_post_model.dart';
import '../models/admin_stats_model.dart';
import '../models/help_initiative_model.dart';
import '../models/activity_history_model.dart';


// ─────────────────────────────────────────────────────────
//  API SERVICE
//
//  ⚙️  CONFIGURATION:
//    - Change [baseUrl] to your Django server address
//    - Set [useMock] to false when backend is ready
//
//  Django endpoints expected:
//    GET  /api/sensors/              → List<SensorModel>
//    POST /api/emergency-reports/    → EmergencyReportModel
//    GET  /api/alerts/               → List<AlertModel>
//    GET  /api/dashboard/stats/      → DashboardStats
//    GET  /api/sponsors/             → List<SponsorModel>
//    GET  /api/emergency-contacts/   → List<EmergencyContact>
//    POST /api/sensors/{id}/respond/ → mark user responded (safe)
//    POST /api/alerts/{id}/respond/  → mark user joining
// ─────────────────────────────────────────────────────────

class ApiService {
  // ── Configuration ─────────────────────────────────────
  //  Android emulator → 10.0.2.2 maps to your PC's localhost
  //  Real device on same WiFi → use your PC's local IP e.g. 192.168.1.x
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  /// Set to [false] when Django backend is ready and running
  static const bool useMock = true;

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add auth header here when ready:
    // 'Authorization': 'Bearer $token',
  };

  // ── Generic helpers ────────────────────────────────────
  static Future<dynamic> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));
    _checkStatus(response);
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    _checkStatus(response);
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Request failed: ${response.statusCode}',
      );
    }
  }

  // ════════════════════════════════════════════════════════
  //  SENSORS
  // ════════════════════════════════════════════════════════

  /// GET /api/sensors/
  static Future<List<SensorModel>> fetchSensors() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return _mockSensors;
    }
    final data = await _get('/sensors/') as List;
    return data.map((e) => SensorModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/emergency-reports/
  static Future<EmergencyReportModel> reportEmergency(
      EmergencyReportModel report) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return EmergencyReportModel(
        id: 999,
        sensorId: report.sensorId,
        type: report.type,
        lat: report.lat,
        lng: report.lng,
        message: report.message,
        status: 'dispatched',
        dispatchedAt: DateTime.now(),
      );
    }
    final data = await _post('/emergency-reports/', report.toJson());
    return EmergencyReportModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /api/alerts/new/
  static Future<void> sendEmergencyAlert({
    required String type,
    required double lat,
    required double lng,
    String? description,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    await _post('/alerts/new/', {
      'type': type,
      'lat': lat,
      'lng': lng,
      'description': description,
    });
  }

  /// POST /api/sensors/{id}/respond/   (user says "I'm safe")
  static Future<void> markSensorSafe(int sensorId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }
    await _post('/sensors/$sensorId/respond/', {'status': 'safe'});
  }

  // ════════════════════════════════════════════════════════
  //  SPONSORS
  // ════════════════════════════════════════════════════════

  /// GET /api/sponsors/
  static Future<List<SponsorModel>> fetchSponsors() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockSponsorsData;
    }
    final data = await _get('/sponsors/') as List;
    return data.map((e) => SponsorModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ════════════════════════════════════════════════════════
  //  ALERTS
  // ════════════════════════════════════════════════════════

  /// GET /api/alerts/
  static Future<List<AlertModel>> fetchAlerts() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 700));
      return _mockAlerts;
    }
    final data = await _get('/alerts/') as List;
    return data.map((e) => AlertModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/alerts/{id}/join/
  static Future<void> respondToAlert(int alertId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    await _post('/alerts/$alertId/respond/', {'status': 'joining'});
  }

  // ════════════════════════════════════════════════════════
  //  DASHBOARD
  // ════════════════════════════════════════════════════════

  /// GET /api/dashboard/stats/
  static Future<DashboardStats> fetchDashboardStats() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockDashboard;
    }
    final data = await _get('/dashboard/stats/');
    return DashboardStats.fromJson(data as Map<String, dynamic>);
  }

  // ════════════════════════════════════════════════════════
  //  COMMUNITY
  // ════════════════════════════════════════════════════════

  /// GET /api/posts/
  static Future<List<CommunityPost>> fetchCommunityPosts() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return _mockPosts;
    }
    final data = await _get('/posts/') as List;
    return data.map((e) => CommunityPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/help-initiatives/
  static Future<List<HelpInitiative>> fetchHelpInitiatives() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return _mockHelpInitiatives;
    }
    final data = await _get('/help-initiatives/') as List;
    return data.map((e) => HelpInitiative.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ════════════════════════════════════════════════════════
  //  PROFILE & USERS
  // ════════════════════════════════════════════════════════

  /// GET /api/profile/ (Current User)
  static Future<UserModel> fetchUserProfile() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockCurrentUser;
    }
    final data = await _get('/profile/');
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /api/profile/update/
  static Future<void> updateUserProfile(UserModel user) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    await _post('/profile/update/', user.toJson());
  }

  /// GET /api/admin/users/
  static Future<List<UserModel>> fetchUserList() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 700));
      return _mockUsers;
    }
    final data = await _get('/admin/users/') as List;
    return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/admin/stats/
  static Future<AdminStats> fetchAdminStats() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockAdminStats;
    }
    final data = await _get('/admin/stats/');
    return AdminStats.fromJson(data as Map<String, dynamic>);
  }

  // ════════════════════════════════════════════════════════
  //  CONTACTS
  // ════════════════════════════════════════════════════════

  /// GET /api/emergency-contacts/
  static Future<List<EmergencyContact>> fetchEmergencyContacts() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _mockContacts;
    }
    final data = await _get('/emergency-contacts/') as List;
    return data.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/profile/history/
  static Future<List<ActivityHistoryModel>> fetchActivityHistory({bool isArabic = false}) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return isArabic ? _mockHistoryAr : _mockHistory;
    }
    final data = await _get('/profile/history/') as List;
    return data.map((e) => ActivityHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }


  // ════════════════════════════════════════════════════════
  //  MOCK DATA  (removed when useMock = false)

  // ════════════════════════════════════════════════════════

  static final List<SensorModel> _mockSensors = [
    SensorModel(id: 1, type: 'gas',        value: '71',  unit: 'ppm', status: 'normal', lat: 30.0444, lng: 31.2357),
    SensorModel(id: 2, type: 'heat',       value: '23',  unit: '°م',  status: 'normal', lat: 30.0444, lng: 31.2357),
    SensorModel(id: 3, type: 'smartwatch', value: '95',  unit: '%',   status: 'normal', lat: 30.0444, lng: 31.2357),
  ];

  static final List<AlertModel> _mockAlerts = [
    AlertModel(
      id: 1, type: 'fire',
      location: 'downtown',
      severity: 'high', status: 'dealing', 
      currentVolunteers: 12, totalVolunteers: 87,
      lat: 30.0500, lng: 31.2450,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      description: 'حريق في المنطقة، نحتاج لسرعة توفير متطوعين للالتحام مع فرق الطوارئ.',
      isMyAlert: false,
    ),
    AlertModel(
      id: 2, type: 'medical',
      location: 'nasrcity',
      severity: 'medium', status: 'inway', 
      currentVolunteers: 5, totalVolunteers: 15,
      lat: 30.0600, lng: 31.3000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      description: 'تم التعامل مع البلاغ وإخماده بنجاح بمساعدة متطوع واستقرار الأوضاع.',
      isMyAlert: true,
    ),
    AlertModel(
      id: 3, type: 'security',
      location: 'maadi',
      severity: 'low', status: 'resolved', 
      currentVolunteers: 2, totalVolunteers: 5,
      lat: 29.9600, lng: 31.2500,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      description: 'استقرار الحالة الأمنية في موقع البلاغ بعد تدخل سريع.',
      isMyAlert: true,
    ),
  ];

  static final List<SponsorModel> _mockSponsorsData = [
    SponsorModel(
      id: 1,
      category: SponsorCategory.cars,
      title: 'البافارية للسيارات',
      rating: '4.8',
      badgeLabel: 'مركز صيانة',
      description: 'خدمات سيارات مميزة في جميع أنحاء مصر',
      services: ['دعم الإسعاف', 'ونش طوارئ', 'فحص مجاني', 'دعم 24/7'],
      phone: '16625',
      branch: 'فرع 15',
      isFeatured: true,
    ),
    SponsorModel(
      id: 2,
      category: SponsorCategory.cars,
      title: 'غبور أوتو',
      rating: '4.7',
      badgeLabel: 'مركز صيانة',
      description: 'موزع ومقدم خدمات سيارات رائد',
      services: ['خدمة الونش', 'دعم الحوادث', 'مطالبات التأمين', 'إصلاحات طارئة'],
      phone: '16662',
      branch: 'فرع 25',
    ),
    SponsorModel(
      id: 3,
      category: SponsorCategory.insurance,
      title: 'أليانز للتأمين',
      rating: '4.9',
      badgeLabel: 'شركة تأمين',
      description: 'رائد التأمين العالمي بتغطية شاملة',
      services: ['شبكة دولية', 'تغطية طبية شاملة', 'رعاية طوارئ', 'علاج بدون نقدي'],
      phone: '16555',
      branch: 'فرع 200',
      isFeatured: true,
    ),
    SponsorModel(
      id: 4,
      category: SponsorCategory.medical,
      title: 'مستشفى السلام الدولي',
      rating: '4.7',
      badgeLabel: 'رعاية طبية',
      description: 'خدمات طبية متكاملة واستقبال طوارئ على مدار الساعة',
      services: ['طوارئ 24/7', 'أشعة وتحاليل', 'عناية مركزة', 'استشارات تخصصية'],
      phone: '16290',
      branch: 'فرع 10',
    ),
    SponsorModel(
      id: 5,
      category: SponsorCategory.medical,
      title: 'صيدليات العزبي',
      rating: '4.6',
      badgeLabel: 'صيدلية',
      description: 'توفير أدوية وخدمات توصيل سريعة',
      services: ['توصيل أدوية', 'قياس ضغط وسكر', 'مستلزمات طبية', 'دعم استشارات'],
      phone: '19600',
      branch: 'فروع متعددة',
    ),
    SponsorModel(
      id: 6,
      category: SponsorCategory.insurance,
      title: 'مصر للتأمين الصحي',
      rating: '4.5',
      badgeLabel: 'تأمين',
      description: 'شركة التأمين المصرية الموثوقة',
      services: ['تغطية محلية', 'شبكة واسعة', 'مطالبات سريعة', 'خدمة عملاء'],
      phone: '19033',
      branch: 'فرع 100',
    ),
  ];

  static const DashboardStats _mockDashboard = DashboardStats(
    responseTimeMinutes: 4,
    responseTimeSeconds: 23,
    successRate: 97,
    activeUnits: 142,
    systemHealthy: true,
  );

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
