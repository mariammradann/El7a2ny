import 'package:flutter/foundation.dart';

/// إعدادات الاتصال بخادم Django.
///
/// - للتخصيص: `flutter run --dart-define=API_BASE_URL=https://api.example.com`
/// - عند عدم التخصيص:
///   - Android emulator => `10.0.2.2`
///   - باقي المنصات المحلية => `127.0.0.1`
abstract final class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// بادئة مسارات الـ REST (مثال: `/api/v1` كما في Django DRF).
  static const String apiPrefix = String.fromEnvironment(
    'API_PREFIX',
    defaultValue: '/api/v1',
  );
}
