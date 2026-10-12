import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/shell/kbd_chip.dart';
import 'package:manga_jp/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('KbdChip uses JetBrains Mono from type-scale tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: KbdChip(label: 'Enter')),
      ),
    );

    final text = tester.widget<Text>(find.text('Enter'));
    expect(text.style?.fontFamily, AppFonts.mono);
    expect(text.style?.fontFamily, 'JetBrains Mono');
    expect(AppTypeScale.mono10.fontFamily, AppFonts.mono);
    expect(AppFonts.mono, 'JetBrains Mono');
  });
}
