import 'package:flutter_test/flutter_test.dart';
// TODO: Import the utility or screen file where your validateEgyptianPhone function lives

String? validateEgyptianPhone(String? value) {
  if (value == null || value.isEmpty) return 'Phone is required';
  final regExp = RegExp(r'^01[0125][0-9]{8}$');
  if (!regExp.hasMatch(value)) return 'Invalid Egyptian Phone Number';
  return null;
}

void main() {
  group('Registration Phone Field Validator Logic Group', () {
    test('Should return error text for incomplete lengths', () {
      var result = validateEgyptianPhone('0101234567'); // 10 digits
      expect(result, 'Invalid Egyptian Phone Number');
    });

    test(
      'Should return null (no errors) for valid 11-digit Egyptian format',
      () {
        var result = validateEgyptianPhone(
          '01234567890',
        ); // Correct configuration
        expect(result, null);
      },
    );
  });
}
