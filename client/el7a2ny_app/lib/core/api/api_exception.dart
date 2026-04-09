/// خطأ من الخادم أو الشبكة — مناسب لعرض رسالة للمستخدم أو للـ logging.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
