// // lib/services/camera_alert_service.dart

// import 'dart:async';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'api_service.dart';
// import '../models/incident_model.dart';

// class CameraAlertService {
//   static final FlutterLocalNotificationsPlugin _notif =
//       FlutterLocalNotificationsPlugin();

//   static Timer? _timer;
//   static String? _lastSeenIncidentId;

//   // Call this once in main.dart or after login
//   static Future<void> init() async {
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings();
//     await _notif.initialize(
//       const InitializationSettings(android: androidSettings, iOS: iosSettings),
//     );
//   }

//   static void startPolling() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkForAlerts());
//     print("[CameraAlertService] ✅ Polling started");
//   }

//   static void stopPolling() {
//     _timer?.cancel();
//     print("[CameraAlertService] ⛔ Polling stopped");
//   }

//   static Future<void> _checkForAlerts() async {
//     try {
//       final List<IncidentModel> incidents = await ApiService.fetchAdminIncidents(
//         status: "reported",
//       );

//       // Filter for camera stranger alerts only
//       final strangerAlerts = incidents
//           .where((i) => i.category == "stranger_detected")
//           .toList();

//       if (strangerAlerts.isEmpty) return;

//       final latest = strangerAlerts.first;

//       // Don't re-notify for the same incident
//       if (latest.id == _lastSeenIncidentId) return;
//       _lastSeenIncidentId = latest.id;

//       print("[CameraAlertService] 🚨 New stranger alert: ${latest.id}");
//       await _showNotification(latest);

//     } catch (e) {
//       print("[CameraAlertService] Error: $e");
//     }
//   }

//   static Future<void> _showNotification(IncidentModel incident) async {
//     await _notif.show(
//       incident.id.hashCode,
//       "🚨 Stranger Detected at Home!",
//       "Your camera spotted an unrecognized person. Tap to view.",
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'camera_alerts',
//           'Camera Alerts',
//           channelDescription: 'Alerts from home camera',
//           importance: Importance.max,
//           priority: Priority.high,
//           playSound: true,
//         ),
//         iOS: DarwinNotificationDetails(
//           presentAlert: true,
//           presentSound: true,
//         ),
//       ),
//     );
//   }
// }