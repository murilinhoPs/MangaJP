import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the persisted Drift DB in the browser (sqlite3.wasm + drift worker).
QueryExecutor openMangaJpDatabase() {
  return driftDatabase(
    name: 'mangajp',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
