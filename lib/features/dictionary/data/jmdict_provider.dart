import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dictionary_lookup.dart';
import 'jmdict_service.dart';

part 'jmdict_provider.g.dart';

/// Copies `assets/dict/jmdict.sqlite` (M0.5 bake) to a filesystem path.
Future<String> ensureJmdictFile() async {
  final dir = await _jmdictDiskDirectory();
  await dir.create(recursive: true);
  final file = File('${dir.path}/jmdict.sqlite');
  if (!file.existsSync()) {
    final data = await rootBundle.load(JmdictService.assetPath);
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }
  return file.path;
}

Future<Directory> _jmdictDiskDirectory() async {
  try {
    return await getApplicationSupportDirectory();
  } catch (_) {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }
}

/// Opens the M0.5 JMdict asset read-only. Tests override with a fixture file.
@Riverpod(keepAlive: true)
Future<JmdictService> jmdictService(Ref ref) async {
  final path = await ensureJmdictFile();
  final service = JmdictService()..openFile(path);
  ref.onDispose(service.close);
  return service;
}

@Riverpod(keepAlive: true)
Future<DictionaryLookup> dictionaryLookup(Ref ref) async {
  final jmdict = await ref.watch(jmdictServiceProvider.future);
  return DictionaryLookup(jmdict);
}
