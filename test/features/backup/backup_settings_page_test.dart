import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/features/backup/data/backup_file_port.dart';
import 'package:manga_jp/features/backup/domain/backup_labels.dart';
import 'package:manga_jp/features/backup/presentation/about_section.dart';
import 'package:manga_jp/features/backup/presentation/backup_keys.dart';
import 'package:manga_jp/features/backup/presentation/backup_section.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_store.dart';
import 'package:manga_jp/features/ocr/data/ocr_repository.dart';
import 'package:manga_jp/features/settings/presentation/settings_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import 'backup_fixtures.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('export writes schema + empty saved_kanji at $label', (
      tester,
    ) async {
      final files = MemoryBackupFilePort();
      await _openSettings(tester, files: files, size: size);

      await tester.ensureVisible(find.byKey(BackupKeys.export));
      await tester.tap(find.byKey(BackupKeys.export));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(files.lastFileName, 'mangajp-backup.json');
      expect(files.lastExported, contains('"schema_version": 10'));
      expect(files.lastExported, contains('"format_version": 2'));
      expect(files.lastExported, contains('"saved_kanji": []'));
      expect(files.lastExported, contains('"crop_words": []'));
      expect(find.text(BackupLabels.exportOk), findsOneWidget);
      expect(find.text(BackupLabels.exportJson), findsOneWidget);
    });

    testWidgets('export error shows a snackbar at $label', (tester) async {
      final files = MemoryBackupFilePort(saveError: Exception('disk'));
      await _openSettings(tester, files: files, size: size);

      await tester.ensureVisible(find.byKey(BackupKeys.export));
      await tester.tap(find.byKey(BackupKeys.export));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(BackupLabels.exportFailed), findsOneWidget);
      expect(files.lastExported, isNull);
    });

    testWidgets(
      'failing desktop write shows Falha ao exportar, not success at $label',
      (tester) async {
        final files = MemoryBackupFilePort(
          saveError: const FileSystemException(
            'Permission denied',
            '/tmp/mangajp-backup.json',
            OSError('Permission denied', 13),
          ),
        );
        await _openSettings(tester, files: files, size: size);

        await tester.ensureVisible(find.byKey(BackupKeys.export));
        await tester.tap(find.byKey(BackupKeys.export));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text(BackupLabels.exportFailed), findsOneWidget);
        expect(find.text(BackupLabels.exportOk), findsNothing);
        expect(files.lastExported, isNull);
      },
    );

    testWidgets('unreadable restore file shows a snackbar at $label', (
      tester,
    ) async {
      final files = MemoryBackupFilePort(
        pickError: const FormatException('bad utf-8'),
      );
      final env = await _openSettings(tester, files: files, size: size);
      await _seedLocalWord(env.db);

      await tester.ensureVisible(find.byKey(BackupKeys.restore));
      await tester.tap(find.byKey(BackupKeys.restore));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(BackupKeys.confirmDialog), findsNothing);
      expect(find.text(BackupLabels.invalidFile), findsOneWidget);
      expect(
        (await env.db.select(env.db.userWords).get()).single.id,
        'keep-me',
      );
    });

    testWidgets('restore ok replaces Caderno after confirm at $label', (
      tester,
    ) async {
      final files = MemoryBackupFilePort(importJson: sampleJson());
      final env = await _openSettings(tester, files: files, size: size);
      await _seedLocalWord(env.db);

      await tester.ensureVisible(find.byKey(BackupKeys.restore));
      await tester.tap(find.byKey(BackupKeys.restore));
      await tester.pumpAndSettle();

      expect(find.byKey(BackupKeys.confirmDialog), findsOneWidget);
      expect(find.text(BackupLabels.confirmBody), findsOneWidget);
      await tester.tap(find.byKey(BackupKeys.confirmRestore));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(BackupLabels.restoreOk), findsOneWidget);
      expect((await env.db.select(env.db.userWords).get()).single.id, 'eat');
      expect(
        (await env.db.select(env.db.savedKanji).get()).single.literal,
        '食',
      );
    });

    testWidgets(
      'restore of unknown schema shows the message and writes nothing at $label',
      (tester) async {
        final files = MemoryBackupFilePort(
          importJson: sampleJson(schemaVersion: 11),
        );
        final env = await _openSettings(tester, files: files, size: size);
        await _seedLocalWord(env.db);

        await tester.ensureVisible(find.byKey(BackupKeys.restore));
        await tester.tap(find.byKey(BackupKeys.restore));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byKey(BackupKeys.confirmDialog), findsNothing);
        expect(
          find.text(BackupLabels.unknownSchema(fileSchema: 11, appSchema: 10)),
          findsOneWidget,
        );
        expect(
          (await env.db.select(env.db.userWords).get()).single.id,
          'keep-me',
        );
      },
    );

    testWidgets('Sobre / Fontes shows KANJIDIC2 attribution at $label', (
      tester,
    ) async {
      await _openSettings(tester, files: MemoryBackupFilePort(), size: size);

      await tester.ensureVisible(find.byKey(BackupKeys.aboutSection));
      expect(find.byType(AboutSection), findsOneWidget);
      expect(find.text(BackupLabels.aboutSection), findsOneWidget);
      expect(find.text(BackupLabels.kanjidic), findsOneWidget);
      expect(find.text('KANJIDIC2 © EDRDG, CC BY-SA 4.0'), findsOneWidget);
      expect(find.byType(BackupSection), findsOneWidget);
    });
  }
}

class _Env {
  const _Env({required this.db});

  final AppDatabase db;
}

Future<_Env> _openSettings(
  WidgetTester tester, {
  required MemoryBackupFilePort files,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        backupFilePortProvider.overrideWithValue(files),
        cloudVisionStoreProvider.overrideWithValue(MemoryCloudVisionStore()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  const SettingsRoute().go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  expect(find.byType(SettingsPage), findsOneWidget);
  return _Env(db: db);
}

Future<void> _seedLocalWord(AppDatabase db) async {
  await db.wordsDao.insertWord(
    UserWordsCompanion.insert(
      id: 'keep-me',
      seq: 1,
      lemma: '古い',
      reading: 'ふるい',
      createdAt: DateTime.utc(2025, 1, 1),
    ),
  );
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: 'keep-me',
          state: WordState.saved.name,
          updatedAt: DateTime.utc(2025, 1, 1),
        ),
      );
}
