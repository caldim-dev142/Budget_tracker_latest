import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../security/app_lock_service.dart';

/// LockGate widget wraps the root UI to enforce native device lock (doc 12 §1, A3).
/// Gating financial data until authentication succeeds, and re-locking on app pause.
class LockGate extends ConsumerStatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final enabled = await AppLockService.loadSavedPreference();
      if (!mounted) return;
      ref.read(appLockEnabledProvider.notifier).state = enabled;
      if (enabled) {
        ref.read(appUnlockedProvider.notifier).state = false;
        _checkLock();
      } else {
        ref.read(appUnlockedProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final svc = ref.read(appLockServiceProvider);
    // Ignore lifecycle transitions caused by the system authentication prompt itself
    if (svc.isAuthenticating) return;

    final enabled = ref.read(appLockEnabledProvider);
    if (!enabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // Re-lock when app goes to background
      ref.read(appUnlockedProvider.notifier).state = false;
    } else if (state == AppLifecycleState.resumed) {
      final unlocked = ref.read(appUnlockedProvider);
      if (!unlocked) {
        _checkLock();
      }
    }
  }

  Future<void> _checkLock() async {
    final enabled = ref.read(appLockEnabledProvider);
    final unlocked = ref.read(appUnlockedProvider);
    if (!enabled || unlocked) return;

    final svc = ref.read(appLockServiceProvider);
    if (svc.isAuthenticating) return;

    final ok = await svc.authenticate(
      reason: 'Authenticate to access BudgetIQ',
    );
    if (mounted && ok) {
      ref.read(appUnlockedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isAuthenticated = authState?.isAuthenticated ?? false;
    final enabled = ref.watch(appLockEnabledProvider);
    final unlocked = ref.watch(appUnlockedProvider);

    // If user is not logged in or app lock is disabled or already unlocked, show normal UI
    if (!isAuthenticated || !enabled || unlocked) {
      return widget.child;
    }

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Budget Tracker Locked',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authenticate to view financial data and manage your budget.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _checkLock,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Unlock Budget'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
