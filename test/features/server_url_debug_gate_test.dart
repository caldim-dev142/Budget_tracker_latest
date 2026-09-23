import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:budget_tracker/features/auth/presentation/login_screen.dart';
import 'package:budget_tracker/features/settings/presentation/settings_screen.dart';
import 'package:budget_tracker/features/auth/providers/auth_providers.dart';
import 'package:budget_tracker/data/local/database.dart';
import 'package:budget_tracker/core/services/app_init_service.dart';

void main() {
  group('Server-URL affordance kDebugMode gate', () {
    test('kDebugMode is a compile-time boolean', () {
      // Confirms tests run with kDebugMode == true in this environment
      expect(kDebugMode, isTrue);
    });

    testWidgets('LoginScreen shows DNS icon button when kDebugMode is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      // In debug mode, the DNS icon button must be rendered in AppBar actions
      expect(find.byIcon(Icons.dns_rounded), findsOneWidget);
      expect(find.byTooltip('Backend Server Connection'), findsOneWidget);
    });

    testWidgets('SettingsScreen shows Server Connection tile when kDebugMode is true',
        (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await AppInitService.seed(db);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            serverUrlProvider.overrideWith((ref) => 'http://127.0.0.1:3001'),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Backend Server URL'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // In debug mode, "Server Connection" and "Backend Server URL" must be present
      expect(find.text('Server Connection'), findsOneWidget);
      expect(find.text('Backend Server URL'), findsOneWidget);
      expect(find.text('http://127.0.0.1:3001'), findsOneWidget);

      await db.close();
    });
  });
}
