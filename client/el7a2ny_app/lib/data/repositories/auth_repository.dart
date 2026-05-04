import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ضيف الـ import ده
import 'dart:convert'; // <--- السطر ده هو اللي ناقصك


class AuthRepository {
  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

// ... باقي الـ imports

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

    final access = raw['access']?.toString() ?? raw['token']?.toString() ?? "";
    final refresh = raw['refresh']?.toString() ?? "";
    AuthTokenStore.setTokens(access: access, refresh: refresh);

    if (raw['user_id'] != null) {
      String userId = raw['user_id'].toString();
      
      // ✅ التعديل الجوهري: احفظ الـ user_id في الـ SharedPreferences فوراً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId); 
      print("✅ User ID $userId saved to SharedPreferences");

      AuthTokenStore.saveUserData(
        id: userId,
        name: raw['name']?.toString(),
        email: raw['email']?.toString(),
        userType: raw['user_type']?.toString(),
      );
    } else {
       throw ApiException(401, 'بيانات المستخدم غير مكتملة في الرد');
    }
  }

Future<void> register(Map<String, dynamic> body) async {
  try {
    // تأكد إن الـ body مطبوع هنا عشان تشوفه في الـ Console قبل ما يتبعت
    print("Sending Body: ${jsonEncode(body)}"); 
    
    final response = await _client.post('register/', body);
    print("✅ Register Success: $response");
  } on ApiException catch (e) {
    // لو الـ e.message لسه غامضة، اطبع الـ e نفسه
    print("🚨 Register Error: ${e.message}");
    rethrow;
  }
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
    final userId = AuthTokenStore.userId;
    await _client.post('auth/password/verify/', {
      'user_id': userId,
      'password': password,
    });
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    final userId = AuthTokenStore.userId;
    await _client.post('auth/password/change/', {
      'user_id': userId,
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<void> confirmPasswordReset({
    required String contact,
    required bool isEmail,
    required String code,
    required String newPassword,
  }) async {
    await _client.post('auth/password/reset/confirm/', {
      isEmail ? 'email' : 'phone': contact,
      'code': code,
      'new_password': newPassword,
    });
  }
}