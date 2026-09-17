import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/app_init_service.dart';
import 'data/local/database.dart';

/// Bootstrap: initialise Drift, restore session, then launch app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crash reporting & observability error hooks
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Uncaught Flutter error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Platform error: $error\n$stack');
    return true;
  };

  await Firebase.initializeApp();

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
