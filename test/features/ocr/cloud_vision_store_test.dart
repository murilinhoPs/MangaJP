import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fakeKey = 'cv-test-key';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      FlutterCloudVisionStore.enabledPref: true,
    });
  });

  testWidgets('plugin timeout of 400 ms is slow, not unavailable', (
    tester,
  ) async {
    final store = FlutterCloudVisionStore(
      readPlugin: () => Completer<String?>().future,
      writePlugin: (_) async {},
      deletePlugin: () async {},
    );

    var done = false;
    KeyringAvailability? got;
    final pending = store.keyringAvailability.then((value) {
      done = true;
      got = value;
      return value;
    });

    await tester.pump();
    expect(done, isFalse);
    await tester.pump(
      FlutterCloudVisionStore.pluginTimeout - const Duration(milliseconds: 1),
    );
    expect(done, isFalse);

    final wall = Stopwatch()..start();
    await tester.pump(const Duration(milliseconds: 1));
    await pending;
    expect(wall.elapsedMilliseconds, lessThan(100));
    expect(done, isTrue);
    expect(got, KeyringAvailability.slow);
    expect(got, isNot(KeyringAvailability.unavailable));
  });

  testWidgets('slow read does not throw and does not wait wall-clock 400 ms', (
    tester,
  ) async {
    final store = FlutterCloudVisionStore(
      readPlugin: () => Completer<String?>().future,
      writePlugin: (_) async {},
      deletePlugin: () async {},
    );

    String? key;
    final pending = store.readApiKey().then((value) {
      key = value;
      return value;
    });

    final wall = Stopwatch()..start();
    await tester.pump(FlutterCloudVisionStore.pluginTimeout);
    await pending;
    expect(wall.elapsedMilliseconds, lessThan(100));
    expect(key, isNull);
    expect(await store.isEnabled, isTrue);
  });

  testWidgets('slow write throws KeyringSlowException after 400 ms', (
    tester,
  ) async {
    final store = FlutterCloudVisionStore(
      readPlugin: () async => _fakeKey,
      writePlugin: (_) => Completer<void>().future,
      deletePlugin: () async {},
    );

    Object? error;
    final pending = store.writeApiKey(_fakeKey).then<void>((_) {}).catchError((
      Object e,
    ) {
      error = e;
    });

    await tester.pump();
    expect(error, isNull);
    final wall = Stopwatch()..start();
    await tester.pump(FlutterCloudVisionStore.pluginTimeout);
    await pending;
    expect(wall.elapsedMilliseconds, lessThan(100));
    expect(error, isA<KeyringSlowException>());
  });

  testWidgets('read that finishes just under 400 ms is available', (
    tester,
  ) async {
    final store = FlutterCloudVisionStore(
      readPlugin: () async {
        await Future<void>.delayed(
          FlutterCloudVisionStore.pluginTimeout -
              const Duration(milliseconds: 1),
        );
        return _fakeKey;
      },
      writePlugin: (_) async {},
      deletePlugin: () async {},
    );

    KeyringAvailability? got;
    final pending = store.keyringAvailability.then((value) {
      got = value;
      return value;
    });

    await tester.pump();
    expect(got, isNull);
    await tester.pump(
      FlutterCloudVisionStore.pluginTimeout - const Duration(milliseconds: 1),
    );
    await pending;
    expect(got, KeyringAvailability.available);

    final keyPending = store.readApiKey();
    await tester.pump(
      FlutterCloudVisionStore.pluginTimeout - const Duration(milliseconds: 1),
    );
    expect(await keyPending, _fakeKey);
  });

  test('plugin error is unavailable, not slow', () async {
    final store = FlutterCloudVisionStore(
      readPlugin: () async => throw StateError('missing plugin'),
      writePlugin: (_) async => throw StateError('missing plugin'),
      deletePlugin: () async {},
    );

    expect(await store.keyringAvailability, KeyringAvailability.unavailable);
    expect(await store.isKeyringAvailable, isFalse);
    expect(await store.readApiKey(), isNull);
    await expectLater(
      store.writeApiKey(_fakeKey),
      throwsA(isA<KeyringUnavailableException>()),
    );
  });

  test('MemoryCloudVisionStore keeps slow distinct from unavailable', () async {
    final slow = MemoryCloudVisionStore(
      storedKey: _fakeKey,
      enabledFlag: true,
      keyringSlow: true,
    );
    expect(await slow.keyringAvailability, KeyringAvailability.slow);
    expect(await slow.isKeyringAvailable, isTrue);
    expect(await slow.readApiKey(), _fakeKey);
    expect(await slow.isEnabled, isTrue);
    await expectLater(
      slow.writeApiKey(_fakeKey),
      throwsA(isA<KeyringSlowException>()),
    );

    final missing = MemoryCloudVisionStore(keyringAvailable: false);
    expect(await missing.keyringAvailability, KeyringAvailability.unavailable);
    expect(await missing.isKeyringAvailable, isFalse);
    await expectLater(
      missing.writeApiKey(_fakeKey),
      throwsA(isA<KeyringUnavailableException>()),
    );
  });
}
