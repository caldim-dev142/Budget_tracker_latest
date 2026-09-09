import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'secure_store.dart';

/// Lock App — native device-credential authentication (doc 12 §1).
///
/// Uses the system lock-screen authentication configured on the device.
/// Fingerprint gets priority where available; falls back to device
/// PIN / password / pattern. Never creates a custom auth system.
class AppLockService {
  AppLockService(this._ref);
  final Ref _ref;
  final LocalAuthentication _auth = LocalAuthentication();

  static const _kLockEnabled = 'app_lock_enabled';

  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  // ── Capability checks ────────────────────────────────────────────────

  /// Checks whether the device is capable of native lock authentication
  /// (either biometrics like fingerprint/face, or device credentials like PIN/pattern/password).
  Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (e) {
      debugPrint('AppLockService canAuthenticate check error: $e');
      return false;
    }
  }

  // ── Authenticate ─────────────────────────────────────────────────────

  /// Prompts the user to authenticate via the system lock-screen.
  ///
  /// Native Android/iOS authentication gives priority to fingerprint/biometrics
  /// where configured, and falls back to device PIN, pattern, or password.
  ///
  /// Returns `true` ONLY if system authentication succeeded.
  /// Returns `false` on cancel, failure, or device error.
  Future<bool> authenticate({String reason = 'Authenticate to access BudgetIQ'}) async {
    if (kIsWeb) return true;
    if (_isAuthenticating) return false;

    final capable = await canAuthenticate();
    if (!capable) {
      return false;
    }

    _isAuthenticating = true;
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Priority to biometric, fallback to PIN/pattern/password
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('AppLockService PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('AppLockService authenticate error: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  // ── Persistence ──────────────────────────────────────────────────────

  /// Loads the persisted lock preference across app restarts.
  static Future<bool> loadSavedPreference() async {
    try {
      final raw = await SecureStore.read(_kLockEnabled);
      return raw == 'true';
    } catch (e) {
      debugPrint('Error reading lock preference: $e');
      return false;
    }
  }

  /// Restores the saved lock preference into the state provider.
  static Future<void> restoreSavedPreference(
    StateController<bool> lockCtrl,
  ) async {
    final enabled = await loadSavedPreference();
    lockCtrl.state = enabled;
  }

  /// Toggle the lock on/off and persist the choice securely.
  Future<void> setEnabled(bool enabled) async {
    _ref.read(appLockEnabledProvider.notifier).state = enabled;
    try {
      await SecureStore.write(_kLockEnabled, enabled.toString());
    } catch (e) {
      debugPrint('Error saving lock preference: $e');
    }
  }
}

/// User preference: is the app lock turned on?
final appLockEnabledProvider = StateProvider<bool>((_) => false);

/// True once the user has successfully passed authentication this session.
final appUnlockedProvider = StateProvider<bool>((_) => false);

final appLockServiceProvider =
    Provider<AppLockService>((ref) => AppLockService(ref));
