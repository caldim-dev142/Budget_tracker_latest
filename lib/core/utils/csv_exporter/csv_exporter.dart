import 'csv_exporter_unsupported.dart'
    if (dart.library.js_interop) 'csv_exporter_web.dart'
    if (dart.library.io) 'csv_exporter_native.dart';

Future<String> exportCsv(String content) => saveCsvFile(content);
