// lib/models/admin_profile_model.dart
import 'dart:convert';

class AdminProfile {
  final String adminId;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String avatarUrl;
  final bool isOnline;
  final String roleLevel;
  final bool twoFactorEnabled;
  final String lastLogin;
  final int totalUsers;
  final int actionsToday;
  final int pendingRequests;
  final int emergencyReports;
  final List<RecentAction> recentActions;

  AdminProfile({
    required this.adminId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.avatarUrl,
    required this.isOnline,
    required this.roleLevel,
    required this.twoFactorEnabled,
    required this.lastLogin,
    required this.totalUsers,
    required this.actionsToday,
    required this.pendingRequests,
    required this.emergencyReports,
    required this.recentActions,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      adminId: json['admin_id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      isOnline: json['is_online'] ?? false,
      roleLevel: json['role_level'] ?? '',
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      lastLogin: json['last_login'] ?? '',
      totalUsers: json['total_users'] ?? 0,
      actionsToday: json['actions_today'] ?? 0,
      pendingRequests: json['pending_requests'] ?? 0,
      emergencyReports: json['emergency_reports'] ?? 0,
      recentActions: (json['recent_actions'] as List<dynamic>? ?? [])
          .map((e) => RecentAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecentAction {
  final String action;
  final String timestamp;

  RecentAction({required this.action, required this.timestamp});

  factory RecentAction.fromJson(Map<String, dynamic> json) => RecentAction(
        action: json['action'] ?? '',
        timestamp: json['timestamp'] ?? '',
      );
}
