import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';

import 'fixture_png.dart';

class FakeImageSourceService extends ImageSourceService {
  FakeImageSourceService({this.galleryImage, this.initial});

  final IncomingImage? galleryImage;
  final IncomingImage? initial;

  @override
  Stream<IncomingImage> get mediaStream => const Stream.empty();

  @override
  Future<IncomingImage?> initialMedia() async => initial;

  @override
  Future<IncomingImage?> pickFromGallery() async => galleryImage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List png;

  setUp(() {
    png = fixturePng();
  });

  testWidgets('fixture image → crop screen → 1 rect → non-empty PNG bytes', (
    tester,
  ) async {
    Uint8List? cropped;
    await tester.pumpWidget(
      CapturePage(
        image: IncomingImage(bytes: png),
        onCropped: (bytes) => cropped = bytes,
      ).wrap(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Captura'), findsOneWidget);
    expect(find.text('Confirmar crop'), findsOneWidget);

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();

    expect(cropped, isNotNull);
    expect(cropped!.length, greaterThan(0));
    expect(find.byKey(CaptureKeys.cropBytes), findsOneWidget);
    expect(find.textContaining('Crop PNG:'), findsOneWidget);
    expect(find.textContaining('bytes'), findsOneWidget);
  });

  testWidgets('share intent extra opens /capture without bottom tabs', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      MangaJpApp(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          imageSourceServiceProvider.overrideWith(
            (ref) => FakeImageSourceService(initial: IncomingImage(bytes: png)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CapturePage), findsOneWidget);
    expect(find.text('Captura'), findsOneWidget);
    expect(find.text('Caderno'), findsNothing);
    expect(find.text('Review'), findsNothing);

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.byKey(CaptureKeys.cropBytes), findsOneWidget);
  });

  testWidgets('Home Galeria opens /capture; gallery stub yields crop bytes', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      MangaJpApp(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          imageSourceServiceProvider.overrideWith(
            (ref) =>
                FakeImageSourceService(galleryImage: IncomingImage(bytes: png)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Galeria'));
    await tester.pumpAndSettle();

    expect(find.byType(CapturePage), findsOneWidget);
    expect(find.text('Caderno'), findsNothing);

    await tester.tap(find.byKey(CaptureKeys.pickGallery));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.byKey(CaptureKeys.cropBytes), findsOneWidget);
  });
}

extension on CapturePage {
  Widget wrap() {
    return ProviderScope(child: MaterialApp(home: this));
  }
}
