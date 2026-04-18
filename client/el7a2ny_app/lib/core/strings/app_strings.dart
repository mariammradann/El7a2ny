/// نصوص واجهة عامة — ليست بيانات مستخدم.
abstract final class AppStrings {
  /// تلميح تنسيق رقم (بدون رقم وهمي ثابت).
  static const String phoneFormatHint = '01xxxxxxxxx';

  static String userMessage(Object error) {
    if (error is Exception) return error.toString();
    return error.toString();
  }
}
