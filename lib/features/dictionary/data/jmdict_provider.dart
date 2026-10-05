import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dictionary_lookup.dart';
import 'jmdict_open.dart';
import 'jmdict_service.dart';

part 'jmdict_provider.g.dart';

/// Opens the M0.5 JMdict asset read-only. Tests override with a fixture file.
@Riverpod(keepAlive: true)
Future<JmdictService> jmdictService(Ref ref) async {
  final db = await openJmdictFromAsset();
  final service = JmdictService()..open(db);
  ref.onDispose(service.close);
  return service;
}

@Riverpod(keepAlive: true)
Future<DictionaryLookup> dictionaryLookup(Ref ref) async {
  final jmdict = await ref.watch(jmdictServiceProvider.future);
  return DictionaryLookup(jmdict);
}
