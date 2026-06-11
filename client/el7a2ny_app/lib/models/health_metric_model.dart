/// Health monitoring data models for the personalized health system.
///
/// Maps to the Django backend models:
/// - HealthMetric, HealthBaseline, HealthRiskScore, HealthAnomaly, HealthEmergencyReport

class HealthMetricModel {
  final String? metricId;
  final String metricType; // heart_rate, spo2, steps, calories, sleep_duration, exercise
  final double value;
  final String unit;
  final String source;
  final DateTime recordedAt;
  final DateTime? syncedAt;
  final Map<String, dynamic> metadata;

  HealthMetricModel({
    this.metricId,
    required this.metricType,
    required this.value,
    required this.unit,
    this.source = 'health_connect',
    required this.recordedAt,
    this.syncedAt,
    this.metadata = const {},
  });

  factory HealthMetricModel.fromJson(Map<String, dynamic> json) {
    return HealthMetricModel(
      metricId: json['metric_id'],
      metricType: json['metric_type'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] ?? '',
      source: json['source'] ?? 'health_connect',
      recordedAt: DateTime.parse(json['recorded_at']),
      syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at']) : null,
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : {},
    );
  }

  Map<String, dynamic> toJson() => {
    if (metricId != null) 'metric_id': metricId,
    'metric_type': metricType,
    'value': value,
    'unit': unit,
    'source': source,
    'recorded_at': recordedAt.toIso8601String(),
    'metadata': metadata,
  };
}


class HealthBaselineModel {
  final String? baselineId;
  final String metricType;
  final double meanValue;
  final double stdValue;
  final double? minValue;
  final double? maxValue;
  final int sampleCount;
  final bool isMature;
  final DateTime? lastUpdated;

  HealthBaselineModel({
    this.baselineId,
    required this.metricType,
    required this.meanValue,
    this.stdValue = 0,
    this.minValue,
    this.maxValue,
    this.sampleCount = 0,
    this.isMature = false,
    this.lastUpdated,
  });

  factory HealthBaselineModel.fromJson(Map<String, dynamic> json) {
    return HealthBaselineModel(
      baselineId: json['baseline_id'],
      metricType: json['metric_type'] ?? '',
      meanValue: (json['mean_value'] as num?)?.toDouble() ?? 0,
      stdValue: (json['std_value'] as num?)?.toDouble() ?? 0,
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      sampleCount: json['sample_count'] ?? 0,
      isMature: json['is_mature'] ?? false,
      lastUpdated: json['last_updated'] != null ? DateTime.parse(json['last_updated']) : null,
    );
  }
}


class HealthRiskScoreModel {
  final String? scoreId;
  final int score; // 0-100
  final String riskLevel; // normal, low, medium, high
  final List<dynamic> factors;
  final String? explanation;
  final DateTime? computedAt;

  HealthRiskScoreModel({
    this.scoreId,
    required this.score,
    required this.riskLevel,
    this.factors = const [],
    this.explanation,
    this.computedAt,
  });

  factory HealthRiskScoreModel.fromJson(Map<String, dynamic> json) {
    return HealthRiskScoreModel(
      scoreId: json['score_id'],
      score: json['score'] ?? 0,
      riskLevel: json['risk_level'] ?? 'normal',
      factors: json['factors'] is List ? json['factors'] : [],
      explanation: json['explanation'],
      computedAt: json['computed_at'] != null ? DateTime.parse(json['computed_at']) : null,
    );
  }

  /// Color based on risk level
  String get riskColor {
    switch (riskLevel) {
      case 'normal': return '#10B981'; // green
      case 'low': return '#FBBF24'; // yellow
      case 'medium': return '#F97316'; // orange
      case 'high': return '#EF4444'; // red
      default: return '#6B7280'; // gray
    }
  }

  String get riskLabel {
    switch (riskLevel) {
      case 'normal': return 'Normal';
      case 'low': return 'Low Risk';
      case 'medium': return 'Medium Risk';
      case 'high': return 'High Risk';
      default: return 'Unknown';
    }
  }
}


class HealthAnomalyModel {
  final String anomalyId;
  final int riskScore;
  final Map<String, dynamic> currentMetrics;
  final Map<String, dynamic> baselineComparison;
  final List<dynamic> factors;
  final String explanation;
  final String status; // active, acknowledged, resolved, false_alarm
  final String? userResponse; // ok, help, no_response
  final DateTime? respondedAt;
  final DateTime createdAt;

  HealthAnomalyModel({
    required this.anomalyId,
    required this.riskScore,
    required this.currentMetrics,
    required this.baselineComparison,
    required this.factors,
    required this.explanation,
    required this.status,
    this.userResponse,
    this.respondedAt,
    required this.createdAt,
  });

  factory HealthAnomalyModel.fromJson(Map<String, dynamic> json) {
    return HealthAnomalyModel(
      anomalyId: json['anomaly_id'] ?? '',
      riskScore: json['risk_score'] ?? 0,
      currentMetrics: json['current_metrics'] is Map ? Map<String, dynamic>.from(json['current_metrics']) : {},
      baselineComparison: json['baseline_comparison'] is Map ? Map<String, dynamic>.from(json['baseline_comparison']) : {},
      factors: json['factors'] is List ? json['factors'] : [],
      explanation: json['explanation'] ?? '',
      status: json['status'] ?? 'active',
      userResponse: json['user_response'],
      respondedAt: json['responded_at'] != null ? DateTime.parse(json['responded_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isActive => status == 'active';
}


class HealthEmergencyReportModel {
  final String reportId;
  final String? anomalyId;
  final int riskScore;
  final Map<String, dynamic> metricsSnapshot;
  final double? locationLat;
  final double? locationLng;
  final List<dynamic> emergencyContactsNotified;
  final String status;
  final DateTime createdAt;

  HealthEmergencyReportModel({
    required this.reportId,
    this.anomalyId,
    required this.riskScore,
    required this.metricsSnapshot,
    this.locationLat,
    this.locationLng,
    this.emergencyContactsNotified = const [],
    required this.status,
    required this.createdAt,
  });

  factory HealthEmergencyReportModel.fromJson(Map<String, dynamic> json) {
    return HealthEmergencyReportModel(
      reportId: json['report_id'] ?? '',
      anomalyId: json['anomaly_id'],
      riskScore: json['risk_score'] ?? 0,
      metricsSnapshot: json['metrics_snapshot'] is Map ? Map<String, dynamic>.from(json['metrics_snapshot']) : {},
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      emergencyContactsNotified: json['emergency_contacts_notified'] is List ? json['emergency_contacts_notified'] : [],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}


class ProfileMaturityModel {
  final int daysCollected;
  final bool isMature;
  final int progressPct;

  ProfileMaturityModel({
    required this.daysCollected,
    required this.isMature,
    required this.progressPct,
  });

  factory ProfileMaturityModel.fromJson(Map<String, dynamic> json) {
    return ProfileMaturityModel(
      daysCollected: json['days_collected'] ?? 0,
      isMature: json['is_mature'] ?? false,
      progressPct: json['progress_pct'] ?? 0,
    );
  }
}


class HealthDashboardModel {
  final Map<String, dynamic> latestMetrics;
  final List<HealthBaselineModel> baselines;
  final HealthRiskScoreModel? currentRiskScore;
  final List<HealthRiskScoreModel> riskScoreHistory;
  final List<HealthAnomalyModel> recentAnomalies;
  final List<HealthEmergencyReportModel> recentEmergencyReports;
  final ProfileMaturityModel profileMaturity;

  HealthDashboardModel({
    required this.latestMetrics,
    required this.baselines,
    this.currentRiskScore,
    required this.riskScoreHistory,
    required this.recentAnomalies,
    required this.recentEmergencyReports,
    required this.profileMaturity,
  });

  factory HealthDashboardModel.fromJson(Map<String, dynamic> json) {
    return HealthDashboardModel(
      latestMetrics: json['latest_metrics'] is Map
          ? Map<String, dynamic>.from(json['latest_metrics'])
          : {},
      baselines: (json['baselines'] as List?)
          ?.map((b) => HealthBaselineModel.fromJson(b))
          .toList() ?? [],
      currentRiskScore: json['current_risk_score'] != null
          ? HealthRiskScoreModel.fromJson(json['current_risk_score'])
          : null,
      riskScoreHistory: (json['risk_score_history'] as List?)
          ?.map((s) => HealthRiskScoreModel.fromJson(s))
          .toList() ?? [],
      recentAnomalies: (json['recent_anomalies'] as List?)
          ?.map((a) => HealthAnomalyModel.fromJson(a))
          .toList() ?? [],
      recentEmergencyReports: (json['recent_emergency_reports'] as List?)
          ?.map((r) => HealthEmergencyReportModel.fromJson(r))
          .toList() ?? [],
      profileMaturity: ProfileMaturityModel.fromJson(
        json['profile_maturity'] is Map
            ? Map<String, dynamic>.from(json['profile_maturity'])
            : {},
      ),
    );
  }

  // ── Convenience getters for the dashboard UI ──
  double? get latestHeartRate => _metricValue('heart_rate');
  double? get latestSpO2 => _metricValue('spo2');
  double? get latestSteps => _metricValue('steps');
  double? get latestCalories => _metricValue('calories');
  double? get latestSleepDuration => _metricValue('sleep_duration');

  double? _metricValue(String type) {
    final m = latestMetrics[type];
    if (m is Map) return (m['value'] as num?)?.toDouble();
    return null;
  }

  String? _metricUnit(String type) {
    final m = latestMetrics[type];
    if (m is Map) return m['unit'] as String?;
    return null;
  }

  HealthBaselineModel? baselineFor(String type) {
    try {
      return baselines.firstWhere((b) => b.metricType == type);
    } catch (_) {
      return null;
    }
  }
}
