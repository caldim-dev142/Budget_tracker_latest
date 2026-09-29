import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> saveCsvFile(String content, {String? fileName}) async {
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final effectiveFileName = fileName ?? 'budget_tracker_export_$dateStr.csv';

  // Ensure UTF-8 BOM so Excel and spreadsheet apps decode special characters & symbols correctly.
  final contentWithBom =
      content.startsWith('\uFEFF') ? content : '\uFEFF$content';

  if (kIsWeb) {
    throw UnsupportedError('Use web exporter for web platforms');
  }

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // Desktop: save directly to user's public Downloads directory if possible
    Directory? downloadsDir;
    try {
      downloadsDir = await getDownloadsDirectory();
    } catch (_) {}
    downloadsDir ??= await getApplicationDocumentsDirectory();

    final filePath = p.join(downloadsDir.path, effectiveFileName);
    final file = File(filePath);
    await file.writeAsString(contentWithBom, flush: true);
    return filePath;
  } else {
    // Mobile (Android / iOS):
    // 1. Save to temporary/cache directory so it is shareable via system FileProvider
    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, effectiveFileName);
    final file = File(filePath);
    await file.writeAsString(contentWithBom, flush: true);

    // 2. Also attempt to save a copy directly in public external downloads if available
    try {
      final extDirs =
          await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (extDirs != null && extDirs.isNotEmpty) {
        final extPath = p.join(extDirs.first.path, effectiveFileName);
        final extFile = File(extPath);
        await extFile.writeAsString(contentWithBom, flush: true);
      }
    } catch (_) {}

    // 3. Open native system share sheet (Save to Files / Drive / WhatsApp / Email / etc.)
    try {
      final xFile = XFile(
        file.path,
        mimeType: 'text/csv',
        name: effectiveFileName,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Budget Tracker CSV Export',
          subject: 'Budget Tracker CSV Export',
        ),
      );
    } catch (e) {
      debugPrint('Share sheet invocation error: $e');
    }

    return file.path;
  }
}
