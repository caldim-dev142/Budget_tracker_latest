import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web export (DEF-DATA-05): builds a CSV Blob and triggers a browser download.
Future<String> saveCsvFile(String content, {String? fileName}) async {
  final effectiveFileName = fileName ?? 'budget_tracker_export.csv';

  final options = globalContext.getProperty<JSFunction>('Object'.toJS).callAsConstructor<JSObject>();
  options.setProperty('type'.toJS, 'text/csv;charset=utf-8'.toJS);
  // Leading BOM so spreadsheet apps open UTF-8 (₹, names) correctly.
  final parts = <JSAny>['﻿$content'.toJS].toJS;
  final blob = globalContext.getProperty<JSFunction>('Blob'.toJS).callAsConstructor<JSObject>(parts, options);

  final urlApi = globalContext.getProperty<JSObject>('URL'.toJS);
  final url = urlApi.callMethod<JSString>('createObjectURL'.toJS, blob);

  final document = globalContext.getProperty<JSObject>('document'.toJS);
  final anchor = document.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
  anchor.setProperty('href'.toJS, url);
  anchor.setProperty('download'.toJS, effectiveFileName.toJS);
  final body = document.getProperty<JSObject>('body'.toJS);
  body.callMethod<JSAny?>('appendChild'.toJS, anchor);
  anchor.callMethod<JSAny?>('click'.toJS);
  body.callMethod<JSAny?>('removeChild'.toJS, anchor);
  urlApi.callMethod<JSAny?>('revokeObjectURL'.toJS, url);

  return effectiveFileName;
}
