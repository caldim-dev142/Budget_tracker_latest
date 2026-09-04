import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/transactions/presentation/add_entry_screen.dart';
import '../../features/budget/presentation/budget_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/reports/presentation/report_detail_screen.dart';
import '../../features/protection/presentation/protection_screen.dart';
import '../../features/saving/presentation/saving_screen.dart';
import '../../features/cards/presentation/cards_screen.dart';
import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/planning/presentation/planning_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/borrow_lending/presentation/borrow_lending_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../widgets/nav_shell.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = GoRouterRefreshStream(ref.watch(authStateNotifierProvider.notifier).stream);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final hasCompletedOnboarding = authState.valueOrNull?.hasCompletedOnboarding ?? false;
      final onAuthPage = state.fullPath?.startsWith('/auth') ?? false;
      final onSplash = state.fullPath == '/splash';
      final onOnboarding = state.fullPath == '/onboarding';

      if (onSplash) return null; // Always allow splash
      if (!isAuthenticated && !onAuthPage) return '/auth/login';
      // Bypass onboarding as requested
      // if (isAuthenticated && !hasCompletedOnboarding && !onOnboarding) return '/onboarding';
      if (isAuthenticated && (onAuthPage || onOnboarding)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/splash',
      ),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),

      // Auth routes (no nav shell)
      GoRoute(
        path: '/auth',
        redirect: (_, __) => '/auth/login',
        routes: [
          GoRoute(path: 'login', builder: (_, __) => const LoginScreen()),
        ],
      ),

      // Onboarding route (no nav shell)
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => NavShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (_, __) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, state) => AddEntryScreen(
                  initialKind: state.uri.queryParameters['kind'],
                ),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => AddEntryScreen(
                  entryId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/budget',
            builder: (_, __) => const BudgetScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const ReportsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ReportDetailScreen(
                  reportId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/more',
            builder: (_, __) => const MoreScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/more/protection',
            builder: (_, __) => const ProtectionScreen(),
          ),
          GoRoute(
            path: '/more/saving',
            builder: (_, __) => const SavingScreen(),
          ),
          GoRoute(
            path: '/more/cards',
            builder: (_, __) => const CardsScreen(),
          ),
          GoRoute(
            path: '/more/accounts',
            builder: (_, __) => const AccountsScreen(),
          ),
          GoRoute(
            path: '/more/planning',
            builder: (_, __) => const PlanningScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/more/borrow-lending',
            builder: (_, __) => const BorrowLendingScreen(),
          ),
        ],
      ),
    ],
  );
});
