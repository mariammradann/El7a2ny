class AdminStats {
  final int totalUsers;
  final int activeAlerts;
  final String avgResponseTime; // e.g. "3:45"
  final double successRate; // e.g. 0.98
  final List<double> weeklyEfficiency; // 7 values for the chart

  AdminStats({
    required this.totalUsers,
    required this.activeAlerts,
    required this.avgResponseTime,
    required this.successRate,
    required this.weeklyEfficiency,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: json['total_users'] ?? 0,
        activeAlerts: json['active_alerts'] ?? 0,
        avgResponseTime: json['avg_response_time'] ?? '0:00',
        successRate: (json['success_rate'] ?? 0.0).toDouble(),
        weeklyEfficiency: json['weekly_efficiency'] != null 
            ? List<double>.from(json['weekly_efficiency']) 
            : [0.1, 0.2, 0.1, 0.4, 0.3, 0.2, 0.1],
      );
}
