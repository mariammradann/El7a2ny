// lib/services/admin_profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:el7a2ny_app/models/admin_profile_model.dart';
import 'package:el7a2ny_app/core/auth/auth_token_store.dart';
import 'package:el7a2ny_app/core/config/api_config.dart';

class AdminProfileService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api';

  static Future<AdminProfile> fetchProfile(String adminId) async {
    final token = AuthTokenStore.accessToken;
    final response = await http.get(
      Uri.parse('$_baseUrl/profile/$adminId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return AdminProfile.fromJson(data);
    } else {
      throw Exception('Failed to load admin profile (status ${response.statusCode})');
    }
  }
}
