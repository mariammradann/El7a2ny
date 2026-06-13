import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:el7a2ny_app/pages/sensors_page.dart';
import 'package:el7a2ny_app/core/localization/locale_provider.dart';

void main() {
  testWidgets('Sensors Page Dynamic State Alert Test', (WidgetTester tester) async {
    // 1. Inject a critical temperature value (e.g., 125°C) to test the high-alert threshold via SharedPreferences
    SharedPreferences.setMockInitialValues({
      'flutter.local_sensors': jsonEncode([
        {
          'id': 1,
          'type': 'heat',
          'value': '125',
          'unit': '°C',
          'status': 'danger',
          'alert_level': 'CRITICAL',
          'alert_label': '🔥 CRITICAL',
          'is_alert': true,
          'lat': 30.0444,
          'lng': 31.2357,
        }
      ]),
    });

    final configNotifier = AppConfigNotifier()..isArabic = false; // Run in English

    // 2. Build the widget inside the test environment wrapped in AppConfigProvider
    await tester.pumpWidget(
      AppConfigProvider(
        notifier: configNotifier,
        child: const MaterialApp(
          home: SensorsPage(),
        ),
      ),
    );
    await tester.pump(); // Initial build
    await tester.pump(const Duration(seconds: 1)); // Allow async fetchSensors future to complete
    await tester.pump(); // Build with loaded sensors list

    // 3. Verify that the application UI changes its state to reflect the hazard danger
    expect(find.text('Emergency Alert!'), findsOneWidget); 
  });
}
