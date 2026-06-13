import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('My first test for El7a2ny Plus UI', (WidgetTester tester) async {
    // 1. Bnbny shasha bsita awi fiha text gowa el test
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Welcome to El7a2ny Plus'),
          ),
        ),
      ),
    );

    // 2. Bndawar 3al text da fl shasha
    final textFinder = find.text('Welcome to El7a2ny Plus');

    // 3. Bnet2aked enna la2enah mara wa7da bas
    expect(textFinder, findsOneWidget);
  });
}
