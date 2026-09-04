import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/core/security/password_hasher.dart';

void main() {
  group('PasswordHasher Unit Tests', () {
    test('hash produces valid pbkdf2 format string', () {
      final hash = PasswordHasher.hash('mySecretPassword123');
      expect(hash, startsWith('pbkdf2\$120000\$'));
      expect(PasswordHasher.isHashed(hash), isTrue);
    });

    test('verify returns true for correct password', () {
      final hash = PasswordHasher.hash('SuperSecretPass!');
      expect(PasswordHasher.verify('SuperSecretPass!', hash), isTrue);
    });

    test('verify returns false for wrong password', () {
      final hash = PasswordHasher.hash('SuperSecretPass!');
      expect(PasswordHasher.verify('WrongPassword', hash), isFalse);
    });

    test('isHashed identifies legacy plaintext passwords', () {
      expect(PasswordHasher.isHashed('plaintextPassword'), isFalse);
      expect(PasswordHasher.isHashed(null), isFalse);
      expect(PasswordHasher.isHashed(''), isFalse);
    });

    test('hash generates unique salt for identical passwords', () {
      final hash1 = PasswordHasher.hash('samePassword');
      final hash2 = PasswordHasher.hash('samePassword');
      expect(hash1, isNot(equals(hash2)));
      expect(PasswordHasher.verify('samePassword', hash1), isTrue);
      expect(PasswordHasher.verify('samePassword', hash2), isTrue);
    });
  });
}
