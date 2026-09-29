import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/features/auth/providers/auth_providers.dart';

void main() {
  group('isLoopbackHost Unit Tests', () {
    test('standard loopback and emulator hosts return true in all modes', () {
      expect(isLoopbackHost('localhost'), isTrue);
      expect(isLoopbackHost('127.0.0.1'), isTrue);
      expect(isLoopbackHost('::1'), isTrue);
      expect(isLoopbackHost('10.0.2.2'), isTrue);
    });

    test('public domains return false', () {
      expect(isLoopbackHost('caldimproducts.com'), isFalse);
      expect(isLoopbackHost('api.example.com'), isFalse);
      expect(isLoopbackHost('google.com'), isFalse);
    });

    test('private LAN ranges in non-release mode (!kReleaseMode) return true', () {
      // In flutter test, kReleaseMode is always false (debug/profile VM mode).
      expect(kReleaseMode, isFalse);
      expect(isLoopbackHost('192.168.1.166'), isTrue);
      expect(isLoopbackHost('10.1.2.3'), isTrue);
      expect(isLoopbackHost('172.16.0.1'), isTrue);
      expect(isLoopbackHost('172.31.255.255'), isTrue);
      expect(isLoopbackHost('172.32.0.1'), isFalse);
    });
  });
}
