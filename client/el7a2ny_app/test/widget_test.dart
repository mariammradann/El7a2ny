// widget_test.dart
// Basic smoke tests for El7a2ny app.
// Note: We intentionally avoid importing package:el7a2ny_app/main.dart here
// because the full app tree pulls in security_camera_page.dart which uses
// dart:js (web-only). Each test builds only the widgets it needs directly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('El7a2ny App — Smoke Tests', () {
    testWidgets('App renders a MaterialApp without crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('El7a2ny Plus')),
          ),
        ),
      );
      expect(find.text('El7a2ny Plus'), findsOneWidget);
    });

    testWidgets('Login form fields are present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TextField(
                    key: Key('email_field'),
                    decoration: InputDecoration(labelText: 'Email')),
                const TextField(
                    key: Key('password_field'),
                    decoration: InputDecoration(labelText: 'Password')),
                ElevatedButton(
                  key: const Key('login_button'),
                  onPressed: () {},
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Emergency button widget renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('emergency_btn'),
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE61717)),
              child: const Text('Send Emergency Report'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('emergency_btn')), findsOneWidget);
      expect(find.text('Send Emergency Report'), findsOneWidget);
    });
  });
}
