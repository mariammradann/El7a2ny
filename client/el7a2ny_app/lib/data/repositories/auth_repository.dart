import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_token_store.dart';

/// مصادقة واستعادة كلمة السر و OTP — اضبطي المسارات مع Django.
class AuthRepository {
  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// يتوقع استجابة تحتوي `access` / `refresh` (JWT) أو `token` حسب إعداد الخادم.
  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final raw = await _client.post('auth/login/', {
      'email': email,
      'password': password,
      'remember_me': rememberMe,
    });
    if (raw is! Map<String, dynamic>) {
      throw ApiException(500, 'استجابة غير صالحة');
    }
    final access = raw['access'] as String? ?? raw['token'] as String?;
    final refresh = raw['refresh'] as String?;
    if (access == null || access.isEmpty) {
      throw ApiException(401, 'لم يُرجع الخادم رمز الدخول');
    }
    AuthTokenStore.setTokens(access: access, refresh: refresh);
  }

  Future<void> logout() async {
    try {
      await _client.post('auth/logout/', {});
    } catch (_) {
      // حتى لو فشل الخادم نمسح المحلياً
    } finally {
      AuthTokenStore.clear();
    }
  }

  Future<void> register(Map<String, dynamic> body) async {
    await _client.post('auth/register/', body);
  }

  Future<void> requestPasswordReset({required String contact, required bool isEmail}) async {
    await _client.post('auth/password/reset/request/', {
      isEmail ? 'email' : 'phone': contact,
    });
  }

  Future<void> verifyOtp({
    required String contact,
    required bool isEmail,
    required String code,
  }) async {
    await _client.post('auth/password/reset/verify/', {
      isEmail ? 'email' : 'phone': contact,
      'code': code,
    });
  }

  Future<void> resendOtp({required String contact, required bool isEmail}) async {
    await _client.post('auth/password/reset/resend/', {
      isEmail ? 'email' : 'phone': contact,
    });
  }

  Future<void> validateCurrentPassword(String password) async {
    // يتوقع الخادم مساراً للتحقق من كلمة السر الحالية
    await _client.post('auth/password/verify/', {
      'password': password,
    });
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    // يتوقع الخادم مساراً لتغيير كلمة السر (يأخذ القديمة والجديدة لزيادة الأمان)
    await _client.post('auth/password/change/', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}
