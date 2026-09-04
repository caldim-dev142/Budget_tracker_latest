import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 password hashing for the local (offline) auth path.
///
/// Doc 12 §1 mandates argon2id server-side. On the Dart client, PBKDF2-HMAC-SHA256
/// with a per-user random salt and a high iteration count is a strong, dependency-light
/// equivalent for the local account store.
///
/// Stored format (single string, safe to keep in the `users.password` column):
///   pbkdf2$<iterations>$<base64 salt>$<base64 derived key>
class PasswordHasher {
  PasswordHasher._();

  static const int _iterations = 120000; // OWASP-aligned for PBKDF2-SHA256
  static const int _saltBytes = 16;
  static const int _keyBytes = 32; // 256-bit derived key
  static final Random _rng = Random.secure();

  /// Hash a plaintext password into the storable string format.
  static String hash(String password) {
    final salt = Uint8List.fromList(
      List<int>.generate(_saltBytes, (_) => _rng.nextInt(256)),
    );
    final dk = _pbkdf2(utf8.encode(password), salt, _iterations, _keyBytes);
    return 'pbkdf2\$$_iterations\$${base64.encode(salt)}\$${base64.encode(dk)}';
  }

  /// Verify a plaintext password against a stored hash string.
  /// Uses a constant-time comparison to avoid timing leaks.
  static bool verify(String password, String stored) {
    try {
      final parts = stored.split('\$');
      if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
      final iterations = int.parse(parts[1]);
      final salt = base64.decode(parts[2]);
      final expected = base64.decode(parts[3]);
      final actual =
          _pbkdf2(utf8.encode(password), salt, iterations, expected.length);
      return _constantTimeEquals(actual, expected);
    } catch (_) {
      return false;
    }
  }

  /// True if a stored value is already in the PBKDF2 format (vs legacy plaintext).
  static bool isHashed(String? stored) =>
      stored != null && stored.startsWith('pbkdf2\$');

  // ── PBKDF2-HMAC-SHA256 ─────────────────────────────────────────────────────
  static Uint8List _pbkdf2(
      List<int> password, List<int> salt, int iterations, int keyLen) {
    final hmac = Hmac(sha256, password);
    final blocks = (keyLen / 32).ceil();
    final out = BytesBuilder();

    for (var block = 1; block <= blocks; block++) {
      final intBlock = Uint8List(4)
        ..[0] = (block >> 24) & 0xff
        ..[1] = (block >> 16) & 0xff
        ..[2] = (block >> 8) & 0xff
        ..[3] = block & 0xff;

      var u = hmac.convert([...salt, ...intBlock]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.add(t);
    }
    return Uint8List.fromList(out.toBytes().sublist(0, keyLen));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
