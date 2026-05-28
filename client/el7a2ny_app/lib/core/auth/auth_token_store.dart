import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/session_service.dart';

class AuthTokenStore {
  static String? _userId;
  static String? _accessToken;
  static String? _userType;

  // --- Getters عشان الصفحات التانية تشوف المتغيرات ---
  static String? get userId => _userId;
  static String? get accessToken => _accessToken;
  static String? get userType => _userType;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _accessToken = prefs.getString('access_token');
    _userType = prefs.getString('user_type');
    debugPrint("📥 AuthTokenStore Initialized: ID=$_userId, Type=$_userType");
    
    if (_userId != null) {
      SessionService().setUserId(_userId);
    }
    
    if (_userType != null) {
      final userTypeStr = _userType!.toLowerCase();
      if (userTypeStr.contains("admin")) {
        SessionService().setRole(UserRole.admin);
      } else if (userTypeStr.contains("volunteer")) {
        SessionService().setRole(UserRole.volunteer);
      } else {
        SessionService().setRole(UserRole.citizen);
      }
    }
  }

  // حفظ بيانات اليوزر بشكل دائم
  static Future<void> saveUserData({
    required String id,
    String? name,
    String? email,
    String? userType,
  }) async {
    _userId = id;
    _userType = userType;
    SessionService().setUserId(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
    if (name != null) await prefs.setString('user_name', name);
    if (email != null) await prefs.setString('user_email', email);
    if (userType != null) await prefs.setString('user_type', userType);
    
    debugPrint("✅ User Data Persisted: ID=$id, Type=$userType");
  }

  // حفظ التوكنز بشكل دائم
  static Future<void> setTokens({required String access, required String refresh}) async {
    _accessToken = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
    
    debugPrint("✅ Tokens Persisted: Access Present");
  }

  // مسح البيانات عند تسجيل الخروج
  static Future<void> clear() async {
    _userId = null;
    _accessToken = null;
    _userType = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("🗑️ Auth Store Cleared");
  }
}