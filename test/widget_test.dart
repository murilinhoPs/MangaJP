import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';

void main() {
  testWidgets('Home stub route shows Drift hello', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      MangaJpApp(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MangaJP Study'), findsOneWidget);
    expect(find.textContaining('app_meta.hello = MangaJP M0.1'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
  });
}
