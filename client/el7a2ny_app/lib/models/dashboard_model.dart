// ─────────────────────────────────────────────────────────
//  DASHBOARD MODEL — matches Django REST Framework response
//
//  Expected Django endpoint: GET /api/dashboard/stats/
//  Expected JSON:
//  {
//    "response_time_minutes": 4,
//    "response_time_seconds": 23,
//    "success_rate": 97,
//    "active_units": 142,
//    "system_healthy": true
//  }
// ─────────────────────────────────────────────────────────

class DashboardStats {
  final int responseTimeMinutes;
  final int responseTimeSeconds;
  final int successRate;
  final int activeUnits;
  final bool systemHealthy;

  const DashboardStats({
    required this.responseTimeMinutes,
    required this.responseTimeSeconds,
    required this.successRate,
    required this.activeUnits,
    required this.systemHealthy,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      responseTimeMinutes: json['response_time_minutes'] as int,
      responseTimeSeconds: json['response_time_seconds'] as int,
      successRate: json['success_rate'] as int,
      activeUnits: json['active_units'] as int,
      systemHealthy: json['system_healthy'] as bool,
    );
  }

  String get responseTimeDisplay =>
      '$responseTimeMinutes:${responseTimeSeconds.toString().padLeft(2, '0')}';
}
