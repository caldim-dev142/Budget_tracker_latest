import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// OS-backed secure storage for secrets (doc 12 §4, §5, §6).
///
/// Tokens and the local DB encryption key live in the Keystore/Keychain,
/// never in SharedPreferences or a plain StateProvider.
class SecureStore {
  SecureStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Key names — keep them here so they are never typo'd elsewhere.
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kRefreshTokenFamily = 'refresh_token_family';
  static const _kDbKey = 'db_encryption_key';

  // ── Auth tokens ────────────────────────────────────────────────────────────
  static Future<void> writeAccessToken(String token) => write(_kAccessToken, token);
  static Future<String?> readAccessToken() => read(_kAccessToken);

  static Future<void> writeRefreshToken(String token) => write(_kRefreshToken, token);
  static Future<String?> readRefreshToken() => read(_kRefreshToken);

  static Future<void> writeRefreshTokenFamily(String family) => write(_kRefreshTokenFamily, family);
  static Future<String?> readRefreshTokenFamily() => read(_kRefreshTokenFamily);

  /// Clears only auth material — call on logout. Does NOT drop the DB key,
  /// so unsynced local data stays readable (doc 12 §1: never discard on logout).
  static Future<void> clearTokens() async {
    await delete(_kAccessToken);
    await delete(_kRefreshToken);
    await delete(_kRefreshTokenFamily);
  }

  // ── Local DB encryption key (SQLCipher) ────────────────────────────────────
  /// Returns the DB key, generating and persisting a 256-bit random key on first
  /// run. Pass this to the SQLCipher PRAGMA when opening the database.
  /// SECURITY: this method FAILS CLOSED. It previously returned the hardcoded
  /// constant 'budget_tracker_secure_fallback_key' whenever Keystore access
  /// threw — and `resetOnError: true` makes that path genuinely reachable. A
  /// known, committed key is equivalent to no encryption at all, and it would
  /// also silently re-encrypt the database under a key an attacker knows.
  /// Refusing to open is strictly safer than opening with a public key.
  static Future<String> getOrCreateDbKey() async {
    final existing = await read(_kDbKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final key = base64UrlEncode(bytes);
    await write(_kDbKey, key);

    // Read back: if the key did not persist, the next launch would generate a
    // different one and the database would be permanently unreadable. Better to
    // surface that now than to write data that can never be decrypted again.
    final verify = await read(_kDbKey);
    if (verify != key) {
      throw StateError(
        'Could not persist the local database encryption key to secure storage. '
        'Refusing to continue: data written now could not be decrypted later.',
      );
    }

    return key;
  }

  // ── Generic key-value helpers ────────────────────────────────────────────────
  /// Read any arbitrary key from secure storage.
  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      try {
        const fallback = FlutterSecureStorage();
        return await fallback.read(key: key);
      } catch (_) {
        return null;
      }
    }
  }

  /// Write any arbitrary key-value pair to secure storage.
  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      try {
        const fallback = FlutterSecureStorage();
        await fallback.write(key: key, value: value);
      } catch (_) {}
    }
  }

  /// Delete any arbitrary key from secure storage.
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      try {
        const fallback = FlutterSecureStorage();
        await fallback.delete(key: key);
      } catch (_) {}
    }
  }
}
