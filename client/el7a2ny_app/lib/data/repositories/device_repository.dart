import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_token_store.dart';
import '../models/device_status.dart';

class DeviceRepository {
  DeviceRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<DeviceStatus> fetchDeviceStatus() async {
    try {
      final userId = AuthTokenStore.userId;
      final endpoint = userId != null && userId.isNotEmpty
          ? 'devices/status/?user_id=$userId'
          : 'devices/status/';

      final raw = await _client.get(endpoint);
      if (raw is Map<String, dynamic>) {
        return DeviceStatus.fromJson(raw);
      }
      throw ApiException(500, 'شكل الاستجابة غير متوقع من الخادم');
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        return const DeviceStatus(
          smartwatchConnected: false,
          homeSensorConnected: false,
        );
      }
      rethrow;
    } catch (_) {
      return const DeviceStatus(
        smartwatchConnected: false,
        homeSensorConnected: false,
      );
    }
  }
}
