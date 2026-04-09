/// إعدادات الاتصال بخادم Django.
///
/// عند التشغيل: `flutter run --dart-define=API_BASE_URL=https://api.example.com`
/// أو غيّري [defaultValue] أثناء التطوير المحلي.
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// بادئة مسارات الـ REST (مثال: `/api/v1` كما في Django DRF).
  static const String apiPrefix = String.fromEnvironment(
    'API_PREFIX',
    defaultValue: '/api/v1',
  );
}
