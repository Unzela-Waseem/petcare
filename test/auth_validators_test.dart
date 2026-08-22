import 'package:flutter_test/flutter_test.dart';
import 'package:pawfect_care/core/config/auth_validators.dart';

void main() {
  group('password validation', () {
    test('rejects short or low-complexity passwords', () {
      expect(AuthValidators.password('password'), isNotNull);
      expect(AuthValidators.password('OnlyLettersHere'), isNotNull);
    });

    test('accepts a 12+ character mixed password', () {
      expect(AuthValidators.password('Pawfect!2026Care'), isNull);
    });
  });

  test('email validation rejects malformed addresses', () {
    expect(AuthValidators.email('not-an-email'), isNotNull);
    expect(AuthValidators.email('care@pawfect.app'), isNull);
  });
}
