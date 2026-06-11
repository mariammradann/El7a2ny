import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'health_connect_service.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background Task Executing: $task');
    try {
      if (task == 'syncHealthData') {
        final service = HealthConnectService();
        await service.syncAllData();
        return Future.value(true);
      }
    } catch (err) {
      debugPrint('❌ Background Task Failed: $err');
      return Future.value(false);
    }
    return Future.value(true);
  });
}

/// Service to orchestrate the personalized health system:
/// - Manages WorkManager registration for background sync
/// - Handles in-app alerts for anomalies
class HealthMonitorService {
  static final HealthMonitorService _instance = HealthMonitorService._();
  factory HealthMonitorService() => _instance;
  HealthMonitorService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Register periodic sync (15 minutes is minimum on Android)
      await Workmanager().registerPeriodicTask(
        'healthSyncTask',
        'syncHealthData',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

      _isInitialized = true;
      debugPrint('✅ HealthMonitorService initialized and background sync registered');
    } catch (e) {
      debugPrint('❌ Error initializing HealthMonitorService: $e');
    }
  }

  /// Triggers a manual sync and handles any resulting anomalies
  Future<void> manualSync() async {
    final result = await HealthConnectService().syncAllData();
    if (result != null && result['anomalies'] != null) {
      // In a real app, you would show a local notification or an in-app dialog
      // here if an anomaly was detected during manual sync.
      debugPrint('🚨 Anomalies detected during sync: ${result['anomalies']}');
    }
  }
}
