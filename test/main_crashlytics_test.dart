// Tests for the setupErrorHooks() function in lib/main.dart.
//
// These tests import and call the REAL setupErrorHooks function — they do not
// duplicate its logic. A live FirebaseCrashlytics instance is not required
// because setupErrorHooks accepts plain callbacks, allowing the test to supply
// lightweight fakes.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import the real function under test from main.dart.
import 'package:budget_tracker/main.dart' show setupErrorHooks;

void main() {
  // Save and restore global error hooks so tests are isolated from each other.
  late void Function(FlutterErrorDetails)? savedFlutterOnError;
  late ErrorCallback? savedPlatformOnError;

  setUp(() {
    savedFlutterOnError = FlutterError.onError;
    savedPlatformOnError = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = savedFlutterOnError;
    PlatformDispatcher.instance.onError = savedPlatformOnError;
  });

  group('setupErrorHooks — FlutterError.onError', () {
    test('calls flutterErrorReporter with the exact details passed in', () {
      FlutterErrorDetails? captured;
      var callCount = 0;

      setupErrorHooks(
        flutterErrorReporter: (details) {
          captured = details;
          callCount++;
        },
        platformErrorReporter: (_, __) {},
      );

      final details =
          FlutterErrorDetails(exception: Exception('widget build failed'));
      FlutterError.onError!(details);

      expect(callCount, 1);
      expect(captured, same(details));
    });

    test('still calls FlutterError.presentError (existing behaviour preserved)',
        () {
      var presentCalled = false;
      final original = FlutterError.presentError;
      FlutterError.presentError = (_) => presentCalled = true;

      setupErrorHooks(
        flutterErrorReporter: (_) {},
        platformErrorReporter: (_, __) {},
      );

      FlutterError.onError!(
          FlutterErrorDetails(exception: Exception('test')));

      FlutterError.presentError = original; // restore before expect
      expect(presentCalled, isTrue);
    });
  });

  group('setupErrorHooks — PlatformDispatcher.instance.onError', () {
    test('calls platformErrorReporter with the exact error and stack', () {
      Object? capturedError;
      StackTrace? capturedStack;
      var callCount = 0;

      setupErrorHooks(
        flutterErrorReporter: (_) {},
        platformErrorReporter: (e, s) {
          capturedError = e;
          capturedStack = s;
          callCount++;
        },
      );

      final error = Exception('native crash');
      final stack = StackTrace.current;
      PlatformDispatcher.instance.onError!(error, stack);

      expect(callCount, 1);
      expect(capturedError, same(error));
      expect(capturedStack, same(stack));
    });

    test('returns true so Flutter marks the error as handled', () {
      setupErrorHooks(
        flutterErrorReporter: (_) {},
        platformErrorReporter: (_, __) {},
      );

      final result = PlatformDispatcher.instance.onError!(
        Exception('handled?'),
        StackTrace.current,
      );

      expect(result, isTrue,
          reason:
              'onError must return true — false would re-throw as unhandled');
    });
  });

  group('setupErrorHooks — reporter independence', () {
    test('triggering FlutterError hook does not call platformErrorReporter', () {
      var platformCalled = false;

      setupErrorHooks(
        flutterErrorReporter: (_) {},
        platformErrorReporter: (_, __) => platformCalled = true,
      );

      FlutterError.onError!(
          FlutterErrorDetails(exception: Exception('flutter only')));

      expect(platformCalled, isFalse);
    });

    test('triggering platform hook does not call flutterErrorReporter', () {
      var flutterCalled = false;

      setupErrorHooks(
        flutterErrorReporter: (_) => flutterCalled = true,
        platformErrorReporter: (_, __) {},
      );

      PlatformDispatcher.instance.onError!(
        Exception('platform only'),
        StackTrace.current,
      );

      expect(flutterCalled, isFalse);
    });
  });
}
