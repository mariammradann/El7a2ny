/// تخزين مؤقت لرمز الجلسة بعد تسجيل الدخول.
/// لاحقاً: استبدل بـ `flutter_secure_storage` أو `shared_preferences`.
class AuthTokenStore {
  AuthTokenStore._();

  static String? accessToken;
  static String? refreshToken;

  static void setTokens({String? access, String? refresh}) {
    accessToken = access;
    refreshToken = refresh;
  }

  static void clear() {
    accessToken = null;
    refreshToken = null;
  }

  static bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;
}
