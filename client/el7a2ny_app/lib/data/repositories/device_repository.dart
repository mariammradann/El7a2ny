import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../models/device_status.dart';

/// مسارات افتراضية — عدّليها لتطابق `urls.py` في Django.
class DeviceRepository {
  DeviceRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// مثال: `GET /api/v1/devices/status/`
  Future<DeviceStatus> fetchDeviceStatus() async {
    final raw = await _client.get('devices/status/');
    if (raw is Map<String, dynamic>) {
      return DeviceStatus.fromJson(raw);
    }
    throw ApiException(500, 'شكل الاستجابة غير متوقع من الخادم');
  }
}
