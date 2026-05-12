import 'package:http/http.dart' as http;
import '../../core/api/api_client.dart';

/// إرسال بلاغ طوارئ — الحقول تُرسل كـ JSON يطابق الـ Django view / serializer.
class EmergencyReportRepository {
  EmergencyReportRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<dynamic> submitReport(Map<String, dynamic> body, {dynamic mediaFile}) async {
    final Map<String, String> fields = {};
    body.forEach((key, value) {
      fields[key] = value.toString();
    });

    final List<http.MultipartFile> files = [];
    if (mediaFile != null) {
      final bytes = await mediaFile.readAsBytes();
      files.add(http.MultipartFile.fromBytes(
        'media_files',
        bytes,
        filename: mediaFile.name,
      ));
    }

    return await _client.postMultipart('emergency/reports/', fields, files);
  }
}
