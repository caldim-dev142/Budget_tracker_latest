import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:budget_tracker/app.dart';
import 'package:budget_tracker/data/local/database.dart';
import 'package:budget_tracker/core/services/app_init_service.dart';

void main() {
  testWidgets('App bootstraps and starts successfully', (WidgetTester tester) async {
    // Open in-memory Drift database
    final db = AppDatabase(NativeDatabase.memory());
    await AppInitService.seed(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const BudgetTrackerApp(),
      ),
    );

    // Let the initial frame render and trigger loaders
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify app router loads the main screen (which could be the loading or onboarding/dashboard)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
