import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/utils/kanji.dart';
import 'package:manga_jp/features/backup/domain/backup_codec.dart';
import 'package:manga_jp/features/backup/domain/backup_document.dart';
import 'package:manga_jp/features/backup/domain/backup_exception.dart';
import 'package:manga_jp/features/backup/domain/backup_labels.dart';

import 'backup_fixtures.dart';

void main() {
  test('encode/decode round-trip keeps Caderno, SRS, crop_words and kanji', () {
    final original = sampleDocument(cropWords: [sampleCropWord()]);
    final json = encodeBackupJson(original);
    expect(json, contains('"format_version": 2'));
    expect(json, contains('"schema_version": 10'));
    expect(json, contains('"saved_kanji"'));
    expect(json, contains('"crop_words"'));
    expect(json, contains('"crop_id": "crop-a"'));
    expect(json, contains('"literal": "食"'));
    expect(json, isNot(contains('api')));
    expect(json, isNot(contains('keyring')));

    final decoded = decodeBackupJson(json, currentSchemaVersion: 10);
    expect(decoded.formatVersion, kBackupFormatVersion);
    expect(decoded.schemaVersion, 10);
    expect(decoded.words.single.id, 'eat');
    expect(decoded.words.single.lemma, '食べる');
    expect(decoded.words.single.userNote, 'comer');
    expect(decoded.wordStates.single.state, 'learning');
    expect(decoded.cards.single.id, 'card-eat');
    expect(decoded.cardSrs.single.engineId, 'sm2-jr@1');
    expect(decoded.reviewLogs.single.rating, 3);
    expect(decoded.cropWords.single.cropId, 'crop-a');
    expect(decoded.cropWords.single.wordId, 'eat');
    expect(decoded.savedKanji.single.literal, '食');
    expect(decoded.savedKanji.single.originPageId, 'page-a');
    expect(encodeBackupJson(decoded), json);
  });

  test('empty saved_kanji is present in the export JSON', () {
    final json = encodeBackupJson(sampleDocument(savedKanji: const []));
    expect(json, contains('"saved_kanji": []'));
    final decoded = decodeBackupJson(json, currentSchemaVersion: 10);
    expect(decoded.savedKanji, isEmpty);
  });

  test('schema 8 backup without saved_kanji decodes as empty kanji', () {
    final decoded = decodeBackupJson(schema8Json(), currentSchemaVersion: 10);
    expect(decoded.formatVersion, 1);
    expect(decoded.schemaVersion, 8);
    expect(decoded.words, isNotEmpty);
    expect(decoded.cards, isNotEmpty);
    expect(decoded.savedKanji, isEmpty);
    expect(decoded.cropWords, isEmpty);
  });

  test('format_version 1 without crop_words decodes as empty links', () {
    final json = sampleJson(formatVersion: 1);
    expect(json, isNot(contains('crop_words')));
    final decoded = decodeBackupJson(json, currentSchemaVersion: 10);
    expect(decoded.formatVersion, 1);
    expect(decoded.cropWords, isEmpty);
    expect(decoded.words, isNotEmpty);
  });

  test('missing format_version defaults to 1', () {
    final json = sampleJson(formatVersion: 1)
        .replaceFirst('"format_version": 1,\n  ', '');
    final decoded = decodeBackupJson(json, currentSchemaVersion: 10);
    expect(decoded.formatVersion, 1);
  });

  test('schema newer than the app is rejected', () {
    expect(
      () => decodeBackupJson(
        sampleJson(schemaVersion: 11),
        currentSchemaVersion: 10,
      ),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.message,
          'message',
          BackupLabels.unknownSchema(fileSchema: 11, appSchema: 10),
        ),
      ),
    );
  });

  test('unknown format_version is rejected', () {
    expect(
      () => decodeBackupJson(
        sampleJson(formatVersion: 3),
        currentSchemaVersion: 10,
      ),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.message,
          'message',
          BackupLabels.unknownFormat(3),
        ),
      ),
    );
  });

  test('invalid word state is rejected', () {
    expect(
      () => decodeBackupJson(
        sampleJson().replaceFirst('"state": "learning"', '"state": "foo"'),
        currentSchemaVersion: 10,
      ),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.message,
          'message',
          BackupLabels.invalidFile,
        ),
      ),
    );
  });

  test('invalid card kind is rejected', () {
    expect(
      () => decodeBackupJson(
        sampleJson().replaceFirst('"kind": "vocab"', '"kind": "kanji"'),
        currentSchemaVersion: 10,
      ),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.message,
          'message',
          BackupLabels.invalidFile,
        ),
      ),
    );
  });

  test('invalid card phase is rejected', () {
    expect(
      () => decodeBackupJson(
        sampleJson().replaceFirst('"phase": "learning"', '"phase": "foo"'),
        currentSchemaVersion: 10,
      ),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.message,
          'message',
          BackupLabels.invalidFile,
        ),
      ),
    );
  });

  test('invalid suspend_reason is rejected', () {
    expect(
      () => decodeBackupJson(
        sampleJson().replaceFirst(
          '"suspend_reason": null',
          '"suspend_reason": "paused"',
        ),
        currentSchemaVersion: 10,
      ),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.message,
          'message',
          BackupLabels.invalidFile,
        ),
      ),
    );
  });

  test('rejects garbage, non-object, and malformed backups', () {
    const current = 10;
    expect(
      () => decodeBackupJson('not-json', currentSchemaVersion: current),
      throwsA(isA<BackupRejectedException>()),
    );
    expect(
      () => decodeBackupJson('[]', currentSchemaVersion: current),
      throwsA(isA<BackupRejectedException>()),
    );
    expect(
      () => decodeBackupJson(
        '{"schema_version":"ten"}',
        currentSchemaVersion: current,
      ),
      throwsA(isA<BackupRejectedException>()),
    );
    expect(
      () => decodeBackupJson(
        '{"format_version":1}',
        currentSchemaVersion: current,
      ),
      throwsA(isA<BackupRejectedException>()),
    );
    expect(
      () => decodeBackupJson(
        '{"format_version":1,"schema_version":10,"words":"eat"}',
        currentSchemaVersion: current,
      ),
      throwsA(isA<BackupRejectedException>()),
    );
  });

  test('schema_version 0 is rejected', () {
    expect(
      () => decodeBackupJson(
        sampleJson(schemaVersion: 0),
        currentSchemaVersion: 10,
      ),
      throwsA(isA<BackupRejectedException>()),
    );
  });

  test('normalizeKanjiLiteral strips IVS and rejects 0 or 2+ code points', () {
    const ivs = '\u{E0100}';
    expect(normalizeKanjiLiteral('食$ivs'), '食');
    expect(normalizeKanjiLiteral('叱'), '叱');
    expect(normalizeKanjiLiteral('𠮟'), '𠮟');
    expect(normalizeKanjiLiteral('叱'), isNot(normalizeKanjiLiteral('𠮟')));
    expect(normalizeKanjiLiteral(''), isNull);
    expect(normalizeKanjiLiteral('食べる'), isNull);
    expect(normalizeKanjiLiteral(ivs), isNull);
  });
}
