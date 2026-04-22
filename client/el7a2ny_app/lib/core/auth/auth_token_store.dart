import 'package:flutter/material.dart';

class AuthTokenStore {
  static String? userId;
  static String? userName;
  static String? userEmail;
  static String? accessToken;
  static String? refreshToken;

  static void saveUserData({
    required String id,
    String? name,
    String? email,
  }) {
    userId = id;
    userName = name;
    userEmail = email;
    debugPrint("✅ User Data Saved Local: ID=$id, Name=$name");
  }

  static void setTokens({required String access, required String refresh}) {
    accessToken = access;
    refreshToken = refresh;
    debugPrint("✅ Tokens stored: ${access.isNotEmpty ? 'Access Present' : 'Access Empty'}");
  }

  static void clear() {
    userId = null;
    userName = null;
    userEmail = null;
    accessToken = null;
    refreshToken = null;
    debugPrint("🗑️ Auth Store Cleared");
  }
}