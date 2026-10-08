import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../core/constants/legal_constants.dart';
import '../../../core/utils/app_feedback.dart';

/// S2 — Passwordless Email OTP Login / Register Screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _householdCtrl = TextEditingController();

  bool _isRegister = false;
  bool _otpSent = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _displayNameCtrl.dispose();
    _householdCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _resendCountdown = 0);
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();
    final householdName = _householdCtrl.text.trim();

    final success = await ref.read(authStateNotifierProvider.notifier).requestOtp(
          email: email,
          displayName: _isRegister && displayName.isNotEmpty ? displayName : null,
          householdName: _isRegister && householdName.isNotEmpty ? householdName : null,
        );

    final authState = ref.read(authStateNotifierProvider);
    if (mounted) {
      if (success) {
        setState(() {
          _otpSent = true;
          _otpCtrl.clear();
        });
        _startResendTimer();
        AppFeedback.showSuccess(
          context,
          'Verification code sent to $email',
        );
      } else if (authState.hasError) {
        AppFeedback.showError(
          context,
          'Failed to send verification code',
          error: authState.error,
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      AppFeedback.showWarning(context, 'Please enter the 6-digit verification code.');
      return;
    }

    final email = _emailCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();
    final householdName = _householdCtrl.text.trim();

    final success = await ref.read(authStateNotifierProvider.notifier).verifyOtp(
          email: email,
          otp: otp,
          displayName: _isRegister && displayName.isNotEmpty ? displayName : null,
          householdName: _isRegister && householdName.isNotEmpty ? householdName : null,
        );

    final authState = ref.read(authStateNotifierProvider);
    if (mounted) {
      if (success && authState.valueOrNull?.isAuthenticated == true) {
        _resendTimer?.cancel();
        AppFeedback.showSuccess(
          context,
          _isRegister ? 'Account verified successfully!' : 'Welcome back!',
        );
        context.go('/dashboard');
      } else if (authState.hasError) {
        AppFeedback.showError(
          context,
          'Verification failed',
          error: authState.error,
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    final email = _emailCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();
    final householdName = _householdCtrl.text.trim();

    final success = await ref.read(authStateNotifierProvider.notifier).requestOtp(
          email: email,
          displayName: _isRegister && displayName.isNotEmpty ? displayName : null,
          householdName: _isRegister && householdName.isNotEmpty ? householdName : null,
        );

    final authState = ref.read(authStateNotifierProvider);
    if (mounted) {
      if (success) {
        _startResendTimer();
        AppFeedback.showSuccess(
          context,
          'New verification code sent to $email',
        );
      } else if (authState.hasError) {
        AppFeedback.showError(
          context,
          'Failed to resend code',
          error: authState.error,
        );
      }
    }
  }

  void _changeEmail() {
    _resendTimer?.cancel();
    setState(() {
      _otpSent = false;
      _otpCtrl.clear();
      _resendCountdown = 0;
    });
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
                    'Configure the IP / URL of the backend service.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'e.g. https://api.caldimproducts.com/calbudget',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
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
    final isLoading = authState.isLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (kDebugMode)
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
              child: _otpSent ? _buildOtpView(cs, isLoading) : _buildEmailView(cs, isLoading),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailView(ColorScheme cs, bool isLoading) {
    return Form(
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
            textInputAction: _isRegister ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) => _isRegister ? null : _sendOtp(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Please enter a valid email address';
              }
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
              onFieldSubmitted: (_) => _sendOtp(),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Household name is required' : null,
            ),
          ],

          const SizedBox(height: 24),

          // Error display
          finalErrorWidget(cs),

          // Submit Button (Send OTP)
          PressableScale(
            onTap: isLoading ? null : _sendOtp,
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
                        'Send OTP',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Toggle login/register
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    setState(() => _isRegister = !_isRegister);
                  },
            child: Text(
              _isRegister
                  ? 'Already have an account? Sign in'
                  : 'New here? Create an account',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy Policy & Terms of Service Links
          _buildLegalFooter(cs),
        ],
      ),
    );
  }

  Widget _buildOtpView(ColorScheme cs, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo / Icon
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              size: 40,
              color: cs.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Verify Email',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'OTP sent to:\n${_emailCtrl.text.trim()}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // OTP Input Field
        TextFormField(
          controller: _otpCtrl,
          decoration: const InputDecoration(
            labelText: '6-digit OTP',
            hintText: '123456',
            prefixIcon: Icon(Icons.pin_outlined),
            counterText: '',
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _verifyOtp(),
        ),

        const SizedBox(height: 24),

        // Error display
        finalErrorWidget(cs),

        // Verify OTP Button
        PressableScale(
          onTap: isLoading ? null : _verifyOtp,
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
                      'Verify OTP',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resend OTP Countdown & Button
        if (_resendCountdown > 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Resend OTP in $_resendCountdown seconds',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          TextButton.icon(
            onPressed: isLoading ? null : _resendOtp,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Resend OTP',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

        // Change Email button
        TextButton(
          onPressed: isLoading ? null : _changeEmail,
          child: const Text(
            'Change Email',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),

        _buildLegalFooter(cs),
      ],
    );
  }

  Widget finalErrorWidget(ColorScheme cs) {
    final authState = ref.watch(authStateNotifierProvider);
    if (!authState.hasError) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        authState.error.toString(),
        style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLegalFooter(ColorScheme cs) {
    return Wrap(
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
    );
  }
}
