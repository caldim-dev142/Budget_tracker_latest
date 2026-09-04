import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../../../shared/widgets/pressable_scale.dart';

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
        final errText = authState.error.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errText),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (authState.valueOrNull?.isAuthenticated == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegister ? 'Account created successfully!' : 'Welcome back!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.go('/dashboard');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await ref
        .read(authStateNotifierProvider.notifier)
        .signInWithGoogleOAuth();

    if (mounted) {
      final authState = ref.read(authStateNotifierProvider);
      if (authState.hasError) {
        final errText = authState.error.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errText),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (authState.valueOrNull?.isAuthenticated == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google Sign-In successful!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.go('/dashboard');
      }
    }
  }

  void _showGoogleAccountPicker() {
    String selectedEmail = 'user.budget@gmail.com';
    bool isCustom = false;
    final googleEmailCtrl = TextEditingController();
    final googleFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: googleFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Google OAuth Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                            ],
                          ),
                          child: const Text(
                            ' G ',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose an account',
                              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                            ),
                            Text(
                              'to continue to Budget Tracker',
                              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Account Option 1
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: (!isCustom && selectedEmail == 'user.budget@gmail.com')
                          ? const Color(0xFF4285F4).withValues(alpha: 0.1)
                          : null,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF4285F4),
                        child: Text('U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: const Text('User Budget', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('user.budget@gmail.com'),
                      trailing: (!isCustom && selectedEmail == 'user.budget@gmail.com')
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4285F4))
                          : null,
                      onTap: () {
                        setModalState(() {
                          isCustom = false;
                          selectedEmail = 'user.budget@gmail.com';
                        });
                      },
                    ),
                    const SizedBox(height: 6),

                    // Account Option 2
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: (!isCustom && selectedEmail == 'family.budget@gmail.com')
                          ? const Color(0xFF4285F4).withValues(alpha: 0.1)
                          : null,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF34A853),
                        child: Text('F', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: const Text('Family Account', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('family.budget@gmail.com'),
                      trailing: (!isCustom && selectedEmail == 'family.budget@gmail.com')
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4285F4))
                          : null,
                      onTap: () {
                        setModalState(() {
                          isCustom = false;
                          selectedEmail = 'family.budget@gmail.com';
                        });
                      },
                    ),
                    const SizedBox(height: 6),

                    // Custom Account Option
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: isCustom ? const Color(0xFF4285F4).withValues(alpha: 0.1) : null,
                      leading: CircleAvatar(
                        backgroundColor: cs.surfaceContainerHighest,
                        child: Icon(Icons.person_add_outlined, color: cs.onSurfaceVariant),
                      ),
                      title: const Text('Use another Google Account', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Sign in with a different email address'),
                      trailing: isCustom ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4285F4)) : null,
                      onTap: () {
                        setModalState(() {
                          isCustom = true;
                        });
                      },
                    ),

                    if (isCustom) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: googleEmailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Google Email Address *',
                          prefixIcon: const Icon(Icons.mark_email_read_outlined),
                          hintText: 'your.name@gmail.com',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Google email required';
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Enter a valid Google email address';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.security_rounded, size: 18, color: Color(0xFF4285F4)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Google OAuth 2.0 Secure Authorization. Your session is protected.',
                              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Button
                    PressableScale(
                      onTap: () async {
                        String emailToAuth = selectedEmail;
                        if (isCustom) {
                          if (!googleFormKey.currentState!.validate()) return;
                          emailToAuth = googleEmailCtrl.text.trim();
                        }

                        Navigator.pop(ctx);
                        setState(() => _isGoogleLoading = true);

                        await ref.read(authStateNotifierProvider.notifier).googleSignIn(
                              email: emailToAuth,
                              displayName: emailToAuth.split('@').first,
                            );

                        if (mounted) {
                          setState(() => _isGoogleLoading = false);
                          final authState = ref.read(authStateNotifierProvider);
                          if (authState.hasError) {
                            final errText = authState.error.toString().replaceAll('Exception: ', '');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errText),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Google Sign-In Successful: Signed in as $emailToAuth'),
                                backgroundColor: const Color(0xFF34A853),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            context.go('/dashboard');
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8), // Official Google Blue
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            isCustom ? 'Continue with Selected Account' : 'Continue as $selectedEmail',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final isLoading = authState.isLoading || _isGoogleLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
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
                          hintText: 'John Doe',
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
                          hintText: 'Smith Household',
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
