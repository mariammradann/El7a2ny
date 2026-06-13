import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:el7a2ny_app/pages/emergency_chat_screen.dart';
import 'package:el7a2ny_app/core/localization/locale_provider.dart';

void main() {
  testWidgets('Daleel AI Chat UI Field and Send Button Test', (WidgetTester tester) async {
    // 1. Build the Daleel Chat screen inside the test sandbox wrapped in AppConfigProvider
    final configNotifier = AppConfigNotifier()..isArabic = false; // Run in English

    await tester.pumpWidget(
      AppConfigProvider(
        notifier: configNotifier,
        child: const MaterialApp(
          home: EmergencyChatScreen(),
        ),
      ),
    );
    await tester.pump(); // Render first frame
    await tester.pump(const Duration(milliseconds: 100)); // Process post-frame callbacks

    // 2. Verify that the user input text field and send icon are visible
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget); // Corrected to Icons.send_rounded

    // 3. Simulate typing an emergency question into the chatbot field
    await tester.enterText(find.byType(TextField), 'How to treat a burn injury?');
    await tester.pump(); // Re-render frame to update input text state

    // 4. Simulate tapping the Send button to dispatch the query
    await tester.tap(find.byIcon(Icons.send_rounded)); // Corrected to Icons.send_rounded
    await tester.pump(); // Process the button tap trigger pipeline
  });
}
