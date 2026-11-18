import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> savePageImage({
  required String pageId,
  required Uint8List bytes,
  String? documentsPath,
}) async {
  final root = await _documents(documentsPath);
  final dir = Directory('${root.path}/pages');
  dir.createSync(recursive: true);
  final file = File('${dir.path}/$pageId.png');
  // Sync IO so widget tests (fake async) can persist without runAsync.
  file.writeAsBytesSync(bytes, flush: true);
  return file.path;
}

Future<Directory> _documents(String? documentsPath) async {
  if (documentsPath != null && documentsPath.isNotEmpty) {
    return Directory(documentsPath);
  }
  if (_inWidgetTest) {
    final dir = Directory('${Directory.systemTemp.path}/mangajp-page-images');
    dir.createSync(recursive: true);
    return dir;
  }
  try {
    return await getApplicationDocumentsDirectory();
  } catch (_) {
    final dir = Directory('${Directory.systemTemp.path}/mangajp-page-images');
    dir.createSync(recursive: true);
    return dir;
  }
}

bool get _inWidgetTest {
  try {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  } catch (_) {
    return true;
  }
}
