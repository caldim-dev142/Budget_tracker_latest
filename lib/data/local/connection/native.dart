import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
 
import '../../../core/security/secure_store.dart';
 
/// Points `package:sqlite3` at the SQLCipher native library instead of plain
/// SQLite.
///
/// CRITICAL: the `open` registry is PER-ISOLATE. `NativeDatabase
/// .createInBackground` opens the database on a background isolate, so
/// registering the override only on the main isolate leaves that background
/// isolate running plain SQLite — `PRAGMA key` is then silently ignored and the
/// database is written in plaintext. This function is therefore passed as
/// `isolateSetup` as well as being called on the main isolate.
///
/// It must be a top-level function so it can be sent to another isolate.
void useSqlCipher() {
  if (Platform.isAndroid) {
    // Only Android needs the override; on iOS/macOS sqlcipher_flutter_libs
    // links SQLCipher directly into the process.
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}
 
/// Opens the local database with SQLCipher encryption genuinely enabled.
///
/// SECURITY / HISTORY: this previously depended on `sqlite3_flutter_libs` and
/// issued `PRAGMA key`. Plain SQLite silently ignores pragmas it does not
/// recognise, so the pragma was a no-op and `budget_tracker.db` was stored as
/// PLAINTEXT — every transaction, balance and card readable by anyone with the
/// file. Switching to `sqlcipher_flutter_libs` is what makes the pragma real.
///
/// BREAKING: an existing PLAINTEXT database created by an older build cannot be
/// opened by SQLCipher. Such installs must clear app data / reinstall. Server
/// data is unaffected and re-syncs on next login.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    // sqlcipher_flutter_libs requires this to be awaited on the MAIN isolate
    // before any background isolate is spawned.
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    }
 
    // Register on this isolate too, for any direct sqlite3 use here.
    useSqlCipher();
 
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budget_tracker.db'));
    final key = await SecureStore.getOrCreateDbKey();
 
    // The key is base64url (A–Z a–z 0–9 - _ =), so it cannot contain a quote.
    // Escape defensively anyway so a future key format change cannot break out
    // of the pragma string.
    final escapedKey = key.replaceAll("'", "''");
 
    return NativeDatabase.createInBackground(
      file,
      // Runs inside the background isolate before the database is opened.
      isolateSetup: useSqlCipher,
      setup: (raw) {
        // Fail loudly if we are not actually talking to SQLCipher. Without this
        // check a mis-wired dependency silently degrades to plaintext storage
        // again — exactly the defect this file exists to prevent.
        // `cipher_version` is informational and safe to read before `key`.
        if (raw.select('PRAGMA cipher_version;').isEmpty) {
          throw StateError(
            'SQLCipher is not active — refusing to open the local database '
            'unencrypted. Check that sqlcipher_flutter_libs is installed and '
            'that useSqlCipher() ran on this isolate.',
          );
        }
 
        raw.execute("PRAGMA key = '$escapedKey';");
 
        // Verifies the key is correct and the file is really a SQLCipher DB.
        // Throws for a wrong key or a legacy plaintext database.
        raw.execute('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}