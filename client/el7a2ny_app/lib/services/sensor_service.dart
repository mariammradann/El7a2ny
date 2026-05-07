import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SensorMonitorService extends ChangeNotifier {
  static final SensorMonitorService _instance = SensorMonitorService._internal();
  factory SensorMonitorService() => _instance;
  SensorMonitorService._internal();

  Timer? _timer;
  double? lastTemperature;
  double? lastHumidity;
  bool lastIsAlert = false;
  bool _isSensorConnected = false;
  List<String> _activeSensorAlerts = [];

  bool get isSensorConnected => _isSensorConnected;
  List<String> get activeSensorAlerts => _activeSensorAlerts;

  // Callbacks the UI can listen to
  VoidCallback? onAlert;
  VoidCallback? onUpdate;

  /// Call this once from main.dart or after login
  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final data = await ApiService.getLatestSensorReading(userId);
      lastTemperature = (data['temperature'] as num).toDouble();
      lastHumidity    = (data['humidity'] as num?)?.toDouble();
      final wasAlert = lastIsAlert;
      lastIsAlert     = data['is_alert'] ?? false;

      // Update sensor connection status
      _isSensorConnected = true;
      
      // Update alert status
      if (lastIsAlert) {
        if (!_activeSensorAlerts.contains('temperature_humidity')) {
          _activeSensorAlerts.add('temperature_humidity');
        }
      } else {
        _activeSensorAlerts.remove('temperature_humidity');
      }

      notifyListeners();
      onUpdate?.call();
      if (lastIsAlert && !wasAlert) onAlert?.call();
    } catch (_) {
      _isSensorConnected = false;
      notifyListeners();
    }
  }

  /// Manually set sensor disconnected (e.g., when user logs out or app loses connection)
  void setSensorDisconnected() {
    _isSensorConnected = false;
    _activeSensorAlerts.clear();
    notifyListeners();
  }
}