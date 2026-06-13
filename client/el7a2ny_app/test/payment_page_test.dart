import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:el7a2ny_app/pages/payment_page.dart';
import 'package:el7a2ny_app/core/localization/locale_provider.dart';

void main() {
  testWidgets('Payment Page Input Fields and Submission UI Test', (WidgetTester tester) async {
    // 1. Build the payment screen inside the test environment wrapped in AppConfigProvider
    final configNotifier = AppConfigNotifier()..isArabic = false; // Run in English

    await tester.pumpWidget(
      AppConfigProvider(
        notifier: configNotifier,
        child: const MaterialApp(
          home: PaymentPage(amount: 299),
        ),
      ),
    );
    await tester.pump(); // Render first frame

    // 2. Verify basic checkout payment components are visible on screen
    expect(find.byType(ElevatedButton), findsOneWidget); // Corrected matcher to findsOneWidget
    expect(find.text('Continue'), findsOneWidget); // Corrected button text

    // Get the ElevatedButton widget to check its initial disabled state
    final buttonBefore = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(buttonBefore.onPressed, isNull); // Verify it is disabled initially

    // 3. Select a payment option (Credit/Debit Card) to enable the button
    final creditCardOption = find.text('Credit/Debit Card');
    await tester.tap(creditCardOption);
    await tester.pump(); // Process state update to enable the button

    // 4. Verify that the button is now enabled
    final buttonAfter = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(buttonAfter.onPressed, isNotNull); // Verify button is now active
  });
}
