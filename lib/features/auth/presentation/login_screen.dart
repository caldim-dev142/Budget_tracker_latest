import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../core/constants/legal_constants.dart';
import '../../../core/utils/app_feedback.dart';

/// S2 — Login / Register Screen (doc 09 S2).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _householdCtrl = TextEditingController();

  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    _householdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (_isRegister) {
      await ref.read(authStateNotifierProvider.notifier).register(
            email: email,
            password: password,
            displayName: _displayNameCtrl.text.trim(),
            householdName: _householdCtrl.text.trim(),
          );
    } else {
      await ref.read(authStateNotifierProvider.notifier).login(
            email: email,
            password: password,
          );
    }

    final authState = ref.read(authStateNotifierProvider);
    if (mounted) {
      if (authState.hasError) {
        AppFeedback.showError(
          context,
          _isRegister ? 'Registration failed' : 'Sign in failed',
          error: authState.error,
        );
      } else if (authState.valueOrNull?.isAuthenticated == true) {
        AppFeedback.showSuccess(
          context,
          _isRegister ? 'Account created successfully!' : 'Welcome back!',
        );
        context.go('/dashboard');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref
          .read(authStateNotifierProvider.notifier)
          .signInWithGoogleOAuth();
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }

    if (mounted) {
      final authState = ref.read(authStateNotifierProvider);
      if (authState.hasError) {
        AppFeedback.showError(
          context,
          'Google Sign-In failed',
          error: authState.error,
        );
      } else if (authState.valueOrNull?.isAuthenticated == true) {
        AppFeedback.showSuccess(context, 'Google Sign-In successful!');
        context.go('/dashboard');
      }
    }
  }

  void _showServerSettingsDialog(BuildContext context) {
    final currentUrl = ref.read(serverUrlProvider);
    final ctrl = TextEditingController(text: currentUrl);
    String? testResult;
    bool isTesting = false;
    bool? isSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.dns_rounded, color: cs.primary),
                const SizedBox(width: 10),
                const Text('Backend Server URL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Configure the IP / URL of the backend PostgreSQL service.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'e.g. http://192.168.1.166:3001',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.wifi, size: 14),
                        label: const Text('PC LAN: 192.168.1.166:3001', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          ctrl.text = 'http://192.168.1.166:3001';
                          setDialogState(() {});
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.phone_android, size: 14),
                        label: const Text('Emulator: 10.0.2.2:3001', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          ctrl.text = 'http://10.0.2.2:3001';
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  if (isTesting) ...[
                    const SizedBox(height: 14),
                    const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ] else if (testResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isSuccess == true ? Colors.green : cs.error).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isSuccess == true ? Colors.green : cs.error).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                            color: isSuccess == true ? Colors.green.shade800 : cs.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              testResult!,
                              style: TextStyle(
                                color: isSuccess == true ? Colors.green.shade800 : cs.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isTesting
                    ? null
                    : () async {
                        setDialogState(() {
                          isTesting = true;
                          testResult = null;
                        });
                        final res = await ref
                            .read(authStateNotifierProvider.notifier)
                            .testServerConnection(ctrl.text.trim());
                        setDialogState(() {
                          isTesting = false;
                          isSuccess = res.success;
                          testResult = res.message;
                        });
                      },
                child: const Text('Test Connection'),
              ),
              FilledButton(
                onPressed: () async {
                  final url = ctrl.text.trim();
                  if (url.isEmpty) {
                    AppFeedback.showWarning(ctx, 'Please enter a server URL.');
                    return;
                  }
                  if (!url.startsWith('http://') && !url.startsWith('https://')) {
                    AppFeedback.showWarning(ctx, 'Server URL must start with http:// or https://');
                    return;
                  }
                  await ref
                      .read(authStateNotifierProvider.notifier)
                      .updateServerUrl(url);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    AppFeedback.showSuccess(context, 'Server URL set to $url');
                  }
                },
                child: const Text('Save & Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final isLoading = authState.isLoading || _isGoogleLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.dns_rounded, color: cs.primary),
            tooltip: 'Backend Server Connection',
            onPressed: () => _showServerSettingsDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 40,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      _isRegister ? 'Create Account' : 'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegister
                          ? 'Start tracking your household budget'
                          : 'Sign in to your Budget Tracker',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: _isRegister
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (_) => _isRegister ? null : _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),

                    // Register-only fields
                    if (_isRegister) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _displayNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Your Display Name',
                          hintText: 'e.g. John Doe',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Display name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _householdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Household Name',
                          hintText: 'e.g. Smith Household',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Household name is required' : null,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Error display
                    if (authState.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          authState.error.toString(),
                          style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Submit Button
                    PressableScale(
                      onTap: isLoading ? null : _submit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isLoading ? cs.primary.withValues(alpha: 0.6) : cs.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: cs.onPrimary,
                                  ),
                                )
                              : Text(
                                  _isRegister ? 'Create Account' : 'Sign In',
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Sign-In Button
                    PressableScale(
                      onTap: isLoading ? null : _handleGoogleSignIn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 4),
                                ],
                              ),
                              child: const Text(
                                ' G ',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Toggle login/register
                    TextButton(
                      onPressed: () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Privacy Policy & Terms of Service Links
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'By continuing, you agree to our ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                        ),
                        InkWell(
                          onTap: () => LegalConstants.showTermsDialog(context),
                          child: Text(
                            'Terms',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ' & ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                        ),
                        InkWell(
                          onTap: () => LegalConstants.showPrivacyPolicyDialog(context),
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
