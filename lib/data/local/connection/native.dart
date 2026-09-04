import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/security/secure_store.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budget_tracker.db'));
    final key = await SecureStore.getOrCreateDbKey();
    return NativeDatabase.createInBackground(
      file,
      setup: (raw) => raw.execute("PRAGMA key = '$key';"),
    );
  });
}
