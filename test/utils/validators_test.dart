import 'package:flutter_test/flutter_test.dart';
import 'package:whelbeing/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts a standard email address', () {
      expect(Validators.email('member@example.com'), isNull);
    });

    test('rejects malformed email addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('member@'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires the shared password requirements', () {
      expect(Validators.password('Password1!'), isNull);
      expect(Validators.password('password1!'), isNotNull);
      expect(Validators.password('PASSWORD1!'), isNotNull);
      expect(Validators.password('Password!'), isNotNull);
      expect(Validators.password('Password1'), isNotNull);
    });
  });
}
