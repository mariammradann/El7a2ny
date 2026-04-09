import '../../core/api/api_client.dart';

/// إرسال بلاغ طوارئ — الحقول تُرسل كـ JSON يطابق الـ Django view / serializer.
class EmergencyReportRepository {
  EmergencyReportRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> submitReport(Map<String, dynamic> body) async {
    await _client.post('emergency/reports/', body);
  }
}
