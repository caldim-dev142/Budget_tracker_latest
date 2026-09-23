import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/app_init_service.dart';
import 'data/local/database.dart';

/// Callback type for reporting a Flutter framework error to a crash reporter.
typedef FlutterErrorReporter = void Function(FlutterErrorDetails details);

/// Callback type for reporting a raw Dart/platform error to a crash reporter.
typedef PlatformErrorReporter = void Function(Object error, StackTrace? stack);

/// Wires [FlutterError.onError] and [PlatformDispatcher.instance.onError] to
/// call [flutterErrorReporter] / [platformErrorReporter] IN ADDITION TO the
/// existing [FlutterError.presentError] and [debugPrint] behaviour — neither
/// of those existing behaviours is removed.
///
/// Extracted as a top-level function (not inlined in [main]) so that tests
/// can import and invoke the real function with a mock reporter, without
/// needing a live [FirebaseCrashlytics] instance.
///
/// MUST be called after [Firebase.initializeApp()] — Crashlytics requires
/// Firebase to be ready before any instance method is reachable.
void setupErrorHooks({
  required FlutterErrorReporter flutterErrorReporter,
  required PlatformErrorReporter platformErrorReporter,
}) {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Uncaught Flutter error: ${details.exceptionAsString()}');
    flutterErrorReporter(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Uncaught Platform error: $error\n$stack');
    platformErrorReporter(error, stack);
    return true;
  };
}

/// Bootstrap: initialise Firebase, wire crash reporting, open Drift DB,
/// seed data, then launch app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be ready before Crashlytics is touched.
  await Firebase.initializeApp();

  // Disable Crashlytics collection in debug builds so dev crashes don't
  // pollute production crash data.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  // Wire error hooks AFTER initializeApp() — guaranteed Firebase is ready.
  setupErrorHooks(
    flutterErrorReporter:
        FirebaseCrashlytics.instance.recordFlutterFatalError,
    platformErrorReporter: (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );

  final db = await AppDatabase.open();
  await AppInitService.seed(db);
  await db.accountDao.recalculateAllAccountBalances();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const BudgetTrackerApp(),
    ),
  );
}
