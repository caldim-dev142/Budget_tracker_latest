import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric / device-credential app-lock (doc 12 §1).
///
/// Gates app open and sensitive actions (month close/reopen, balance edits,
/// data export). Falls back to device PIN/pattern when biometrics are absent,
/// and is a no-op on platforms without local_auth support.
class AppLockService {
  AppLockService(this._ref);
  final Ref _ref;
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get isSupported async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> get canCheckBiometrics async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user to authenticate. Returns true on success.
  /// If the setting is off or the device can't authenticate, returns true
  /// (do not lock the user out of their own offline data).
  Future<bool> authenticate({String reason = 'Unlock your budget'}) async {
    final enabled = _ref.read(appLockEnabledProvider);
    if (!enabled) return true;
    if (!await isSupported) return true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow device PIN/pattern fallback
        ),
      );
    } catch (_) {
      return true; // never hard-lock on a plugin error
    }
  }
}

/// Persisted user preference (mirror into SharedPreferences on change).
final appLockEnabledProvider = StateProvider<bool>((_) => false);

/// True once the user has passed the lock this session.
final appUnlockedProvider = StateProvider<bool>((_) => false);

final appLockServiceProvider =
    Provider<AppLockService>((ref) => AppLockService(ref));
