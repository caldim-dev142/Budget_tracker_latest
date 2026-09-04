import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> saveCsvFile(String content) async {
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'budget_tracker_export.csv');
  final file = File(path);
  await file.writeAsString(content);
  return path;
}
