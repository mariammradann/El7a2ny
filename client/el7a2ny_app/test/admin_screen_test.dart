import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:el7a2ny_app/pages/admin_screen.dart';
import 'package:el7a2ny_app/core/localization/locale_provider.dart';

void main() {
  testWidgets('Admin Dashboard Structural Layout Elements Test', (WidgetTester tester) async {
    // 1. Build the Admin Screen inside the test environment wrapped in AppConfigProvider
    final configNotifier = AppConfigNotifier()..isArabic = false; // Run in English

    await tester.pumpWidget(
      AppConfigProvider(
        notifier: configNotifier,
        child: const MaterialApp(
          home: AdminScreen(),
        ),
      ),
    );

    await tester.pump(); // Start loading
    await tester.pump(const Duration(seconds: 1)); // Wait for async API tasks to finish
    await tester.pump(); // Render state update

    // 2. Verify that general admin structural components are present
    expect(find.text('Admin Dashboard'), findsOneWidget); // AppBar Title
    expect(find.text('Dashboard'), findsOneWidget); // Tab Label
    expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget); // Tab Icon
  });
}
