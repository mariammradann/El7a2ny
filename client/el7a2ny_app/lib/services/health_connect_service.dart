import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/health_metric_model.dart';
import 'api_service.dart';

/// Service that manages Health Connect integration and periodic health data sync.
class HealthConnectService {
  static final HealthConnectService _instance = HealthConnectService._();
  factory HealthConnectService() => _instance;
  
  HealthConnectService._() {
    Health().configure();
  }

  static const String _lastSyncKey = 'health_last_sync_time';

  bool _isAvailable = false;
  bool _hasPermissions = false;

  bool get isAvailable => _isAvailable;
  bool get hasPermissions => _hasPermissions;

  final List<HealthDataType> _dataTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_SESSION,
  ];

  /// Check if Health Connect is available on this device.
  Future<bool> checkAvailability() async {
    try {
      _isAvailable = true; // Health() handles availability checks internally in most cases
      return _isAvailable;
    } catch (e) {
      debugPrint('❌ Health Connect not available: $e');
      _isAvailable = false;
      return false;
    }
  }

  /// Request Health Connect permissions for all required data types.
  Future<bool> requestPermissions() async {
    try {
      // Must request ACTIVITY_RECOGNITION explicitly on Android 10+ for steps
      try {
        await Permission.activityRecognition.request();
      } catch (e) {
        debugPrint('⚠️ Ignored activityRecognition request error (expected in background): $e');
      }
      
      
      final permissions = List<HealthDataAccess>.filled(_dataTypes.length, HealthDataAccess.READ);
      _hasPermissions = await Health().requestAuthorization(_dataTypes, permissions: permissions);
      return _hasPermissions;
    } catch (e) {
      debugPrint('❌ Failed to request Health Connect permissions: $e');
      _hasPermissions = false;
      return false;
    }
  }

  /// Get the last sync timestamp.
  Future<DateTime> getLastSyncTime() async {
    // FORCE reset to 3 days ago to fetch any real data you have in Health Connect
    return DateTime.now().subtract(const Duration(days: 3));
  }

  /// Update the last sync timestamp.
  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }

  /// Fetch all health data since last sync and send to backend.
  /// Returns the sync result from the backend (risk score, anomaly info).
  Future<Map<String, dynamic>?> syncAllData() async {
    try {
      if (!_hasPermissions) {
        final granted = await requestPermissions();
        if (!granted) {
          debugPrint('❌ Permission denied. Cannot sync health data.');
          return null;
        }
      }

      final lastSync = await getLastSyncTime();
      final now = DateTime.now();

      debugPrint('🔄 Health sync: fetching REAL data from $lastSync to $now');

      List<HealthDataPoint> healthDataList = await Health().getHealthDataFromTypes(
        startTime: lastSync,
        endTime: now,
        types: _dataTypes,
      );

      // Collect all metrics
      final List<HealthMetricModel> metrics = [];

      for (var point in healthDataList) {
        String metricType = '';
        double value = 0.0;
        String unit = '';

        if (point.type == HealthDataType.HEART_RATE) {
          metricType = 'heart_rate';
          value = (point.value as NumericHealthValue).numericValue.toDouble();
          unit = 'bpm';
        } else if (point.type == HealthDataType.BLOOD_OXYGEN) {
          metricType = 'spo2';
          value = (point.value as NumericHealthValue).numericValue.toDouble();
          if (value <= 1.0) value *= 100; // Sometimes SpO2 is 0.98 instead of 98
          unit = '%';
        } else if (point.type == HealthDataType.STEPS) {
          metricType = 'steps';
          value = (point.value as NumericHealthValue).numericValue.toDouble();
          unit = 'steps';
        } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          metricType = 'calories';
          value = (point.value as NumericHealthValue).numericValue.toDouble();
          unit = 'kcal';
        } else if (point.type == HealthDataType.SLEEP_SESSION) {
          metricType = 'sleep_duration';
          value = point.dateTo.difference(point.dateFrom).inMinutes.toDouble();
          unit = 'minutes';
        } else {
          continue;
        }

        metrics.add(HealthMetricModel(
          metricType: metricType,
          value: value,
          unit: unit,
          recordedAt: point.dateTo,
        ));
      }

      if (metrics.isEmpty) {
        debugPrint('ℹ️ No new real health data found in Health Connect to sync');
        return null;
      }

      debugPrint('📊 Collected ${metrics.length} real health metrics, syncing to backend...');

      // Send to backend
      final result = await ApiService.syncHealthMetrics(metrics);

      // Update last sync time
      await setLastSyncTime(now);

      debugPrint('✅ Health sync complete: ${result ?? "no response"}');
      return result;
    } catch (e) {
      debugPrint('❌ Health sync failed: $e');
      return null;
    }
  }
}
