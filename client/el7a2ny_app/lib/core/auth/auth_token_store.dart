import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStore {
  static String? _userId;
  static String? _accessToken;

  // --- Getters عشان الصفحات التانية تشوف المتغيرات ---
  static String? get userId => _userId;
  static String? get accessToken => _accessToken;

  // دالة لتحميل البيانات من الذاكرة عند بداية تشغيل التطبيق (مهمة جداً)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _accessToken = prefs.getString('access_token');
    debugPrint("📥 AuthTokenStore Initialized: ID=$_userId");
  }

  // حفظ بيانات اليوزر بشكل دائم
  static Future<void> saveUserData({
    required String id,
    String? name,
    String? email,
  }) async {
    _userId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
    if (name != null) await prefs.setString('user_name', name);
    if (email != null) await prefs.setString('user_email', email);
    
    debugPrint("✅ User Data Persisted: ID=$id");
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("🗑️ Auth Store Cleared");
  }
}