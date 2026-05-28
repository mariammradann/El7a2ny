import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/global_fab_overlay.dart';
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
  Function(Map<String, dynamic>)? onCameraAlert;
  String? _lastCameraAlertId;

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
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    // 1) Poll sensor readings
    try {
      final data = await ApiService.getLatestSensorReading(userId);
      lastTemperature = (data['temperature'] as num).toDouble();
      lastHumidity    = (data['humidity'] as num?)?.toDouble();
      final wasAlert = lastIsAlert;
      lastIsAlert     = data['is_alert'] ?? false;

      _isSensorConnected = true;
      
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
    } catch (e) {
      debugPrint('Sensor poll error: $e');
      _isSensorConnected = false;
      notifyListeners();
    }

    // 2) Poll camera alerts — runs even if sensor poll fails
    try {
      final cameraAlert = await ApiService.getPendingCameraAlert(userId);
      debugPrint('📹 Camera alert poll: has_alert=${cameraAlert['has_alert']}');
      if (cameraAlert['has_alert'] == true) {
        final alertId = cameraAlert['alert_id'] as String;
        if (alertId != _lastCameraAlertId) {
          _lastCameraAlertId = alertId;
          debugPrint('🚨 NEW camera alert detected! ID: $alertId');
          _showGlobalCameraDialog(cameraAlert);
          onCameraAlert?.call(cameraAlert);
        }
      }
    } catch (e) {
      debugPrint('Camera alert poll error: $e');
    }
  }

  void _showGlobalCameraDialog(Map<String, dynamic> alertData) {
    final context = GlobalFabController.navigatorKey.currentContext;
    if (context == null) return;

    final String alertId = alertData['alert_id'];
    final String? imageUrl = alertData['image_url'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 16,
          backgroundColor: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFE61717).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE61717), size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alert: Camera Detected a Stranger!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFE61717)),
                ),
                const SizedBox(height: 12),
                
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[800],
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 50)),
                      ),
                    ),
                  ),
                  
                const SizedBox(height: 20),
                const Text(
                  'Is this person safe and familiar to you?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ApiService.respondToCameraAlert(alertId, 'reject');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Safe (Ignore)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ApiService.respondToCameraAlert(alertId, 'accept');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE61717),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Stranger (Report)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  /// Manually set sensor disconnected (e.g., when user logs out or app loses connection)
  void setSensorDisconnected() {
    _isSensorConnected = false;
    _activeSensorAlerts.clear();
    notifyListeners();
  }
}