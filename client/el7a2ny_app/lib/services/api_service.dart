import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_model.dart';
import '../models/alert_model.dart';
import '../models/dashboard_model.dart';

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
//    POST /api/sensors/{id}/respond/ → mark user responded (safe)
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

  /// POST /api/sensors/{id}/respond/   (user says "I'm safe")
  static Future<void> markSensorSafe(int sensorId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }
    await _post('/sensors/$sensorId/respond/', {'status': 'safe'});
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
  //  MOCK DATA  (removed when useMock = false)
  // ════════════════════════════════════════════════════════

  static final List<SensorModel> _mockSensors = [
    SensorModel(id: 1, type: 'gas',        value: '71',  unit: 'ppm', status: 'normal', lat: 30.0444, lng: 31.2357),
    SensorModel(id: 2, type: 'heat',       value: '23',  unit: '°م',  status: 'normal', lat: 30.0444, lng: 31.2357),
    SensorModel(id: 3, type: 'smartwatch', value: '95',  unit: '%',   status: 'normal', lat: 30.0444, lng: 31.2357),
  ];

  static final List<AlertModel> _mockAlerts = [
    AlertModel(
      id: 1, type: 'حريق',
      location: 'وسط البلد، شارع طلعت حرب',
      severity: 'high', status: 'جاري التعامل', 
      currentVolunteers: 12, totalVolunteers: 87,
      lat: 30.0500, lng: 31.2450,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    AlertModel(
      id: 2, type: 'حالة طبية',
      location: 'مدينة نصر، شارع عباس العقاد',
      severity: 'medium', status: 'في الطريق', 
      currentVolunteers: 5, totalVolunteers: 15,
      lat: 30.0600, lng: 31.3000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    AlertModel(
      id: 3, type: 'أمن',
      location: 'المعادي، كورنيش النيل',
      severity: 'low', status: 'تم الحل', 
      currentVolunteers: 2, totalVolunteers: 5,
      lat: 29.9600, lng: 31.2500,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];

  static const DashboardStats _mockDashboard = DashboardStats(
    responseTimeMinutes: 4,
    responseTimeSeconds: 23,
    successRate: 97,
    activeUnits: 142,
    systemHealthy: true,
  );
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
