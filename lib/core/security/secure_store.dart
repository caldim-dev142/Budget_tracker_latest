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
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Key names — keep them here so they are never typo'd elsewhere.
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kDbKey = 'db_encryption_key';

  // ── Auth tokens ────────────────────────────────────────────────────────────
  static Future<void> writeAccessToken(String token) =>
      _storage.write(key: _kAccessToken, value: token);
  static Future<String?> readAccessToken() =>
      _storage.read(key: _kAccessToken);

  static Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _kRefreshToken, value: token);
  static Future<String?> readRefreshToken() =>
      _storage.read(key: _kRefreshToken);

  /// Clears only auth material — call on logout. Does NOT drop the DB key,
  /// so unsynced local data stays readable (doc 12 §1: never discard on logout).
  static Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  // ── Local DB encryption key (SQLCipher) ────────────────────────────────────
  /// Returns the DB key, generating and persisting a 256-bit random key on first
  /// run. Pass this to the SQLCipher PRAGMA when opening the database.
  static Future<String> getOrCreateDbKey() async {
    final existing = await _storage.read(key: _kDbKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final key = base64UrlEncode(bytes);
    await _storage.write(key: _kDbKey, value: key);
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
