import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_token_store.dart';

class AuthRepository {
  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  Future<void> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    final raw = await _client.post('users/check_user/', {
      'email': identifier,
      'password': password,
    });

    if (raw is! Map<String, dynamic>) {
      throw ApiException(500, 'استجابة غير صالحة من السيرفر');
    }

    // 1. استخراج التوكن (حتى لو فاضية)
    final access = raw['access']?.toString() ?? raw['token']?.toString() ?? "";
    final refresh = raw['refresh']?.toString() ?? "";
    AuthTokenStore.setTokens(access: access, refresh: refresh);

    // 2. استخراج بيانات اليوزر (Django بيبعت user_id)
    if (raw['user_id'] != null) {
      AuthTokenStore.saveUserData(
        id: raw['user_id'].toString(),
        name: raw['name']?.toString(),
        email: raw['email']?.toString(),
      );
    } else {
       throw ApiException(401, 'بيانات المستخدم غير مكتملة في الرد');
    }
  }

  Future<void> register(Map<String, dynamic> body) async {
    await _client.post('users/', body);
  }

  Future<void> logout() async {
    AuthTokenStore.clear();
  }

  // --- ميثودز الـ Password Reset و OTP ---
  Future<void> requestPasswordReset({required String contact, required bool isEmail}) async {
    await _client.post('auth/password/reset/request/', {isEmail ? 'email' : 'phone': contact});
  }

  Future<void> verifyOtp({required String contact, required bool isEmail, required String code}) async {
    await _client.post('auth/password/reset/verify/', {isEmail ? 'email' : 'phone': contact, 'code': code});
  }

  Future<void> resendOtp({required String contact, required bool isEmail}) async {
    await _client.post('auth/password/reset/resend/', {isEmail ? 'email' : 'phone': contact});
  }

  Future<void> validateCurrentPassword(String password) async {
    await _client.post('auth/password/verify/', {'password': password});
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    await _client.post('auth/password/change/', {'old_password': oldPassword, 'new_password': newPassword});
  }
}