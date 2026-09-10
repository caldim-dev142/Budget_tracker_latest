import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/lock_gate.dart';
import 'features/settings/providers/settings_providers.dart';

class BudgetTrackerApp extends ConsumerWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CalBudget',
      debugShowCheckedModeBanner: false,

      // Material 3 theming seeded from deep teal #0E7C7B (doc 08)
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,

      // Security Gate
      builder: (context, child) => LockGate(child: child ?? const SizedBox.shrink()),

      // Routing
      routerConfig: router,

      // INR locale support
      supportedLocales: const [Locale('en', 'IN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('en', 'IN'),
    );
  }
}
