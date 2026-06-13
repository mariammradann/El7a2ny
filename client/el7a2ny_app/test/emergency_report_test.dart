import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:el7a2ny_app/pages/emergency_report_screen.dart';
import 'package:el7a2ny_app/core/localization/locale_provider.dart';

void main() {
  testWidgets('Emergency Report Form UI Interaction Test', (WidgetTester tester) async {
    // 1. Build the widget inside the test environment wrapped in AppConfigProvider
    final configNotifier = AppConfigNotifier()..isArabic = false; // Run in English so buttons are in English
    
    await tester.pumpWidget(
      AppConfigProvider(
        notifier: configNotifier,
        child: const MaterialApp(
          home: EmergencyReportScreen(),
        ),
      ),
    );

    // 2. Find the input text field and simulate typing a name
    final textField = find.byType(TextField).first;
    await tester.enterText(textField, 'John Doe');
    await tester.pump(); // Trigger a frame rebuild to update the text state

    // 3. Verify that the text field holds the value
    expect(find.text('John Doe'), findsOneWidget);

    // 4. Find and simulate tapping the submit button
    final submitButton = find.text('Send Report');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump(); // Process the tap action
  });
}
