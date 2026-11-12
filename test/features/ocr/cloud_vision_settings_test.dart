import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_ocr_engine.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_store.dart';
import 'package:manga_jp/features/ocr/data/ocr_repository.dart';
import 'package:manga_jp/features/ocr/domain/cloud_vision_labels.dart';
import 'package:manga_jp/features/ocr/presentation/cloud_vision_keys.dart';
import 'package:manga_jp/features/ocr/presentation/cloud_vision_settings_section.dart';
import 'package:manga_jp/features/settings/presentation/settings_page.dart';

import 'scripted_http_client.dart';

const _fakeKey = 'cv-test-key';
const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('toggle without key stays off at $label', (tester) async {
      final store = MemoryCloudVisionStore();
      await _openSettings(tester, store: store, size: size);

      expect(find.byType(CloudVisionSettingsSection), findsOneWidget);
      expect(find.text(CloudVisionLabels.toggle), findsOneWidget);
      expect(_switch(tester).value, isFalse);

      await tester.tap(find.byKey(CloudVisionKeys.toggle));
      await tester.pumpAndSettle();

      expect(_switch(tester).value, isFalse);
      expect(find.text(CloudVisionLabels.needKeyFirst), findsOneWidget);
      expect(find.text(_fakeKey), findsNothing);
      expect(await store.isEnabled, isFalse);
    });

    testWidgets('privacy refuse keeps toggle off and key at $label', (
      tester,
    ) async {
      final store = MemoryCloudVisionStore(storedKey: _fakeKey);
      await _openSettings(tester, store: store, size: size);

      await tester.tap(find.byKey(CloudVisionKeys.toggle));
      await tester.pumpAndSettle();

      expect(find.byKey(CloudVisionKeys.privacyDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(CloudVisionKeys.privacyDialog),
          matching: find.textContaining('recorte'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(CloudVisionKeys.privacyDecline));
      await tester.pumpAndSettle();

      expect(_switch(tester).value, isFalse);
      expect(await store.readApiKey(), _fakeKey);
      expect(await store.isEnabled, isFalse);
      expect(find.text(_fakeKey), findsNothing);
    });

    testWidgets('privacy accept turns toggle on at $label', (tester) async {
      final store = MemoryCloudVisionStore(storedKey: _fakeKey);
      await _openSettings(tester, store: store, size: size);

      await tester.tap(find.byKey(CloudVisionKeys.toggle));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CloudVisionKeys.privacyAccept));
      await tester.pumpAndSettle();

      expect(_switch(tester).value, isTrue);
      expect(await store.isEnabled, isTrue);
      expect(await store.privacyAccepted, isTrue);
      expect(find.text(_fakeKey), findsNothing);
    });

    testWidgets('masked saved key, Testar chave, Remover chave at $label', (
      tester,
    ) async {
      final store = MemoryCloudVisionStore(storedKey: _fakeKey);
      final client = ScriptedHttpClient((request) async {
        return jsonHttpResponse({
          'responses': [
            {
              'fullTextAnnotation': {'text': 'ok'},
            },
          ],
        });
      });
      await _openSettings(
        tester,
        store: store,
        size: size,
        engine: CloudVisionOcrEngine(
          readApiKey: store.readApiKey,
          client: client,
        ),
      );

      expect(find.text(CloudVisionLabels.apiKeySavedHint), findsOneWidget);
      expect(find.text(_fakeKey), findsNothing);

      await tester.ensureVisible(find.byKey(CloudVisionKeys.testKey));
      await tester.tap(find.byKey(CloudVisionKeys.testKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(CloudVisionLabels.testOk), findsOneWidget);
      expect(find.text(_fakeKey), findsNothing);
      expect(await store.readApiKey(), _fakeKey);

      await tester.ensureVisible(find.byKey(CloudVisionKeys.removeKey));
      await tester.tap(find.byKey(CloudVisionKeys.removeKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(await store.readApiKey(), isNull);
      expect(await store.isEnabled, isFalse);
      expect(_switch(tester).value, isFalse);
    });

    testWidgets('Testar chave 401 keeps the key at $label', (tester) async {
      final store = MemoryCloudVisionStore(storedKey: _fakeKey);
      await _openSettings(
        tester,
        store: store,
        size: size,
        engine: CloudVisionOcrEngine(
          readApiKey: store.readApiKey,
          client: ScriptedHttpClient((request) async {
            return http.Response('{}', 401);
          }),
        ),
      );

      await tester.tap(find.byKey(CloudVisionKeys.testKey));
      await tester.pumpAndSettle();
      expect(find.text('Chave inválida.'), findsOneWidget);
      expect(await store.readApiKey(), _fakeKey);
      expect(find.text(_fakeKey), findsNothing);
    });

    testWidgets('Testar chave 400 API_KEY_INVALID keeps the key at $label', (
      tester,
    ) async {
      final store = MemoryCloudVisionStore(storedKey: _fakeKey);
      await _openSettings(
        tester,
        store: store,
        size: size,
        engine: CloudVisionOcrEngine(
          readApiKey: store.readApiKey,
          client: ScriptedHttpClient((request) async {
            return jsonHttpResponse(cloudVisionApiKeyInvalidError(), 400);
          }),
        ),
      );

      await tester.tap(find.byKey(CloudVisionKeys.testKey));
      await tester.pumpAndSettle();
      expect(find.text('Chave inválida.'), findsOneWidget);
      expect(
        find.text('Não foi possível falar com o Cloud Vision.'),
        findsNothing,
      );
      expect(await store.readApiKey(), _fakeKey);
      expect(find.text(_fakeKey), findsNothing);
    });

    testWidgets('keyring unavailable disables the field at $label', (
      tester,
    ) async {
      final store = MemoryCloudVisionStore(keyringAvailable: false);
      await _openSettings(tester, store: store, size: size);

      expect(find.byKey(CloudVisionKeys.keyringWarning), findsOneWidget);
      expect(find.text(CloudVisionLabels.keyringUnavailable), findsOneWidget);
      expect(find.text(CloudVisionLabels.keyringSlow), findsNothing);
      expect(
        tester.widget<TextField>(find.byKey(CloudVisionKeys.apiKey)).enabled,
        isFalse,
      );
      expect(_switch(tester).onChanged, isNull);
    });

    testWidgets(
      'keyring slow keeps the toggle and shows its own copy at $label',
      (tester) async {
        final store = MemoryCloudVisionStore(
          storedKey: _fakeKey,
          enabledFlag: true,
          privacyAcceptedFlag: true,
          keyringSlow: true,
        );
        await _openSettings(tester, store: store, size: size);

        expect(find.byKey(CloudVisionKeys.keyringSlowWarning), findsOneWidget);
        expect(find.text(CloudVisionLabels.keyringSlow), findsOneWidget);
        expect(find.text(CloudVisionLabels.keyringUnavailable), findsNothing);
        expect(
          tester.widget<TextField>(find.byKey(CloudVisionKeys.apiKey)).enabled,
          isTrue,
        );
        expect(_switch(tester).value, isTrue);
        expect(_switch(tester).onChanged, isNotNull);
        expect(await store.isEnabled, isTrue);
        await expectLater(
          store.readApiKey(),
          throwsA(isA<KeyringSlowException>()),
        );
        expect(store.storedKey, _fakeKey);
        expect(find.text(_fakeKey), findsNothing);
      },
    );

    testWidgets('Testar chave when keyring is slow shows slow copy at $label', (
      tester,
    ) async {
      final store = MemoryCloudVisionStore(
        storedKey: _fakeKey,
        enabledFlag: true,
        privacyAcceptedFlag: true,
        keyringSlow: true,
      );
      await _openSettings(tester, store: store, size: size);

      await tester.ensureVisible(find.byKey(CloudVisionKeys.testKey));
      await tester.tap(find.byKey(CloudVisionKeys.testKey));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(CloudVisionLabels.keyringSlow),
        ),
        findsOneWidget,
      );
      expect(find.text(CloudVisionLabels.needKeyFirst), findsNothing);
      expect(find.text('Cole uma chave primeiro.'), findsNothing);
      expect(find.text('Sem chave. Recorte lido com manga-ocr.'), findsNothing);
      expect(store.storedKey, _fakeKey);
      expect(await store.isEnabled, isTrue);
      expect(_switch(tester).value, isTrue);
      expect(find.text(_fakeKey), findsNothing);
    });

    testWidgets('Remover chave when keyring is slow keeps the key at $label', (
      tester,
    ) async {
      final store = MemoryCloudVisionStore(
        storedKey: _fakeKey,
        enabledFlag: true,
        privacyAcceptedFlag: true,
        keyringSlow: true,
      );
      await _openSettings(tester, store: store, size: size);

      await tester.ensureVisible(find.byKey(CloudVisionKeys.removeKey));
      await tester.tap(find.byKey(CloudVisionKeys.removeKey));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(CloudVisionLabels.keyringSlow),
        ),
        findsOneWidget,
      );
      expect(find.text(CloudVisionLabels.keyRemoved), findsNothing);
      expect(store.storedKey, _fakeKey);
      expect(await store.isEnabled, isTrue);
      expect(_switch(tester).value, isTrue);
      expect(find.text(_fakeKey), findsNothing);
    });
  }
}

Switch _switch(WidgetTester tester) {
  return tester.widget<Switch>(
    find.descendant(
      of: find.byKey(CloudVisionKeys.toggle),
      matching: find.byType(Switch),
    ),
  );
}

Future<void> _openSettings(
  WidgetTester tester, {
  required MemoryCloudVisionStore store,
  required Size size,
  CloudVisionOcrEngine? engine,
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
        cloudVisionStoreProvider.overrideWithValue(store),
        if (engine != null)
          cloudVisionOcrEngineProvider.overrideWithValue(engine),
      ],
    ),
  );
  await tester.pumpAndSettle();
  const SettingsRoute().go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  expect(find.byType(SettingsPage), findsOneWidget);
  expect(find.byKey(CloudVisionKeys.section), findsOneWidget);
}
