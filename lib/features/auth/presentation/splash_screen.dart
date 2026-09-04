import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';

/// S1 — Splash Screen (doc 09 S1).
/// Bootstrap: open DB, restore session, biometric gate, route to login or dashboard.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Ensure minimum splash display time
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Wait until auth state has finished loading (session restore completes)
    // Poll until the state is no longer AsyncLoading
    int waited = 0;
    while (mounted) {
      final authState = ref.read(authStateNotifierProvider);
      if (!authState.isLoading) break;
      if (waited >= 3000) break; // max 3s safety timeout
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }
    if (mounted) {
      // Router redirect handles auth state → login or dashboard
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 44,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Budget Tracker',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: cs.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your household finances, clarified.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
