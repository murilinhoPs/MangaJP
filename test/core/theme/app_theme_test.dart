import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final theme = AppTheme.dark;
  final scheme = theme.colorScheme;
  final tokens = theme.extension<MangaJpTokens>()!;

  test('dark theme is not a seed palette', () {
    expect(scheme.brightness, Brightness.dark);
    expect(
      File('lib/core/theme/app_theme.dart').readAsStringSync(),
      isNot(contains('fromSeed')),
    );
    expect(AppTheme.light.brightness, Brightness.dark);
  });

  test('ColorScheme maps tokens.json hex roles exactly', () {
    expect(scheme.primary, AppColors.coral);
    expect(scheme.onPrimary, AppColors.onCoral);
    expect(scheme.primaryContainer, AppColors.overlayPrimaria);
    expect(scheme.onPrimaryContainer, AppColors.coralText);
    expect(scheme.secondary, AppColors.violet);
    expect(scheme.onSecondary, AppColors.text);
    expect(scheme.secondaryContainer, AppColors.overlayEstadoAtivo);
    expect(scheme.onSecondaryContainer, AppColors.violetText);
    expect(scheme.tertiary, AppColors.mint);
    expect(scheme.onTertiary, AppColors.onMint);
    expect(scheme.tertiaryContainer, AppColors.srsBomFill);
    expect(scheme.onTertiaryContainer, AppColors.mint);
    expect(scheme.error, AppColors.coral);
    expect(scheme.onError, AppColors.onCoral);
    expect(scheme.errorContainer, AppColors.srsErreiFill);
    expect(scheme.onErrorContainer, AppColors.coralText);
    expect(scheme.surface, AppColors.surface);
    expect(scheme.onSurface, AppColors.text);
    expect(scheme.onSurfaceVariant, AppColors.text2);
    expect(scheme.outline, AppColors.border);
    expect(scheme.outlineVariant, AppColors.borderStrong);
    expect(scheme.surfaceContainerLowest, AppColors.bg);
    expect(scheme.surfaceContainerLow, AppColors.rail);
    expect(scheme.surfaceContainer, AppColors.surface);
    expect(scheme.surfaceContainerHigh, AppColors.surfaceLow);
    expect(scheme.surfaceContainerHighest, AppColors.surfaceRaised);
    expect(scheme.surfaceTint, AppColors.coral);
    expect(theme.scaffoldBackgroundColor, AppColors.bg);
  });

  test('ThemeExtension exposes non-Material token roles', () {
    expect(tokens.coral, const Color(0xFFFF5C7A));
    expect(tokens.coralText, const Color(0xFFFF8BA0));
    expect(tokens.violet, const Color(0xFF7C63F5));
    expect(tokens.violetText, const Color(0xFF9A86FA));
    expect(tokens.mint, const Color(0xFF4BE3A3));
    expect(tokens.onMint, const Color(0xFF06261A));
    expect(tokens.onCoral, const Color(0xFF1A0F14));
    expect(tokens.text2, const Color(0xFFB3AFBD));
    expect(tokens.text3, const Color(0xFF8C8898));
    expect(tokens.text4, const Color(0xFF6A6775));
    expect(tokens.surfaceLow, const Color(0xFF1D1C24));
    expect(tokens.surfaceRaised, const Color(0xFF23212B));
    expect(tokens.borderStrong, const Color(0xFF403D4B));
    expect(tokens.rail, const Color(0xFF121117));
    expect(tokens.bg, const Color(0xFF0E0D12));
    expect(tokens.overlaySelecaoToque, const Color.fromRGBO(255, 92, 122, 0.25));
    expect(
      tokens.overlayPalavraNaFrase,
      const Color.fromRGBO(124, 99, 245, 0.22),
    );
    expect(tokens.overlayPrimaria, const Color.fromRGBO(255, 92, 122, 0.14));
    expect(tokens.overlayEstadoAtivo, const Color.fromRGBO(124, 99, 245, 0.14));
    expect(tokens.overlayRailAtivo, const Color.fromRGBO(255, 92, 122, 0.16));
    expect(tokens.srsErreiFill, const Color.fromRGBO(255, 92, 122, 0.12));
    expect(tokens.srsBomFill, const Color.fromRGBO(75, 227, 163, 0.14));
    expect(tokens.queueNovos, AppColors.violet);
    expect(tokens.queueRevisoes, AppColors.mint);
    expect(tokens.queueDrill, AppColors.coral);
    expect(tokens.wordState('learning'), tokens.violetText);
    expect(tokens.wordState('known'), tokens.mint);
    expect(tokens.wordState('ignored'), tokens.text3);
    expect(tokens.wordState('saved'), tokens.text);
  });

  test('no amber, blue, or #FF4D6D in ColorScheme or tokens', () {
    const forbidden = <int>{
      0xFFFF4D6D,
      0xFFFFC107, // amber
      0xFFFFB300,
      0xFFFFA000,
      0xFF2196F3, // blue
      0xFF1976D2,
      0xFF1E88E5,
      0xFF42A5F5,
      0xFF1B4D3E, // previous seed
    };
    for (final color in _schemeColors(scheme).followedBy(_tokenColors(tokens))) {
      final argb = color.toARGB32();
      expect(forbidden.contains(argb), isFalse, reason: 'unexpected $color');
      expect(
        argb & 0x00FFFFFF,
        isNot(0x00FF4D6D),
        reason: 'legacy coral $color',
      );
    }
  });

  test('TextTheme uses Inter; Japanese styles use Noto Sans JP', () {
    expect(theme.textTheme.bodyMedium?.fontFamily, AppFonts.ui);
    expect(theme.textTheme.bodyLarge?.fontFamily, AppFonts.ui);
    expect(theme.textTheme.headlineSmall?.fontFamily, AppFonts.ui);
    expect(theme.textTheme.labelLarge?.fontFamily, AppFonts.ui);
    expect(AppTypeScale.tituloTela.fontFamily, AppFonts.ui);
    expect(AppTypeScale.definicao.fontFamily, AppFonts.ui);
    expect(AppTypeScale.ui14.fontFamily, AppFonts.ui);
    expect(AppTypeScale.mono10.fontFamily, AppFonts.mono);
    expect(AppTypeScale.reviewMobileJp.fontFamily, AppFonts.jp);
    expect(AppTypeScale.reviewDesktopJp.fontFamily, AppFonts.jp);
    expect(AppTypeScale.lookupJp.fontFamily, AppFonts.jp);
    expect(AppTypeScale.linhaCadernoJp.fontFamily, AppFonts.jp);
    expect(AppTypeScale.detalheMobileJp.fontFamily, AppFonts.jp);
    expect(AppTypeScale.balaoPaginaMobileJp.fontFamily, AppFonts.jp);
    expect(theme.textTheme.displaySmall?.fontFamily, AppFonts.jp);
    expect(
      File('lib/core/theme/app_type_scale.dart').readAsStringSync(),
      isNot(contains('Noto Serif')),
    );
    expect(
      File('lib/core/theme/app_fonts.dart').readAsStringSync(),
      isNot(contains('mincho')),
    );
  });

  test('type-scale named sizes match tokens.json', () {
    expect(AppTypeScale.reviewDesktopJp.fontSize, 120);
    expect(AppTypeScale.reviewDesktopJp.fontWeight, FontWeight.w500);
    expect(AppTypeScale.contagemBiblioteca.fontSize, 96);
    expect(AppTypeScale.reviewMobileJp.fontSize, 72);
    expect(AppTypeScale.contagemHome.fontSize, 64);
    expect(AppTypeScale.detalheDesktopJp.fontSize, 56);
    expect(AppTypeScale.detalheMobileJp.fontSize, 48);
    expect(AppTypeScale.lookupJp.fontSize, 40);
    expect(AppTypeScale.fraseLeitorDesktopJp.fontSize, 30);
    expect(AppTypeScale.fraseLeitorDesktopJp.height, 1.6);
    expect(AppTypeScale.tituloTela.fontSize, 24);
    expect(AppTypeScale.tituloTela.fontWeight, FontWeight.w600);
    expect(AppTypeScale.balaoPaginaMobileJp.fontSize, 22);
    expect(AppTypeScale.balaoPaginaMobileJp24.fontSize, 24);
    expect(AppTypeScale.balaoPaginaMobileJp.height, 1.7);
    expect(AppTypeScale.linhaCadernoJp.fontSize, 21);
    expect(AppTypeScale.botaoPrimario.fontSize, 16);
    expect(AppTypeScale.definicao.fontSize, 15);
    expect(AppTypeScale.ui13.fontSize, 13);
    expect(AppTypeScale.ui14.fontSize, 14);
    expect(AppTypeScale.metadados11.fontSize, 11);
    expect(AppTypeScale.metadados12.fontSize, 12);
    expect(AppTypeScale.mono10.fontSize, 10);
    expect(AppTypeScale.mono11.fontSize, 11);
  });

  test('radius and target constants match tokens.json', () {
    expect(AppRadius.tecla, 5);
    expect(AppRadius.segmentado, 8);
    expect(AppRadius.railBarra, 10);
    expect(AppRadius.linha, 12);
    expect(AppRadius.dockAcaoBusca, 14);
    expect(AppRadius.card, 18);
    expect(AppRadius.cardFila, 20);
    expect(AppRadius.sheetReview, 24);
    expect(AppRadius.chip, 999);
    expect(AppTargets.min, 44);
    expect(AppTargets.dockTela, 48);
    expect(AppTargets.acaoEstado, 52);
    expect(AppTargets.detalhe, 56);
    expect(AppTargets.navCards, 64);
    expect(AppTargets.respostaReviewMobile, 68);
    expect(AppIcons.stroke, 1.8);
    expect(AppIcons.sizeMin, 18);
    expect(AppIcons.sizeMax, 22);
  });

  testWidgets('Japanese text style actually requests Noto Sans JP', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Text('見せる', style: AppTypeScale.reviewMobileJp),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('見せる'));
    expect(text.style?.fontFamily, AppFonts.jp);
    expect(text.style?.fontSize, 72);
    expect(text.style?.fontWeight, FontWeight.w500);
  });

  testWidgets('default body text uses Inter with JP fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            return Text('Caderno', style: Theme.of(context).textTheme.bodyMedium);
          },
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Caderno'));
    expect(text.style?.fontFamily, AppFonts.ui);
    expect(text.style?.fontFamilyFallback, contains(AppFonts.jp));
  });

  test('outlinedButtonTheme and ColorScheme.outline use border, not coral', () {
    expect(scheme.outline, AppColors.border);
    expect(scheme.outlineVariant, AppColors.borderStrong);
    final outlined = theme.outlinedButtonTheme.style?.side?.resolve(
      const <WidgetState>{},
    );
    expect(outlined?.color, AppColors.border);
    final filled = theme.filledButtonTheme.style?.side?.resolve(
      const <WidgetState>{},
    );
    expect(filled?.color, AppColors.coral);
  });

  test('navigationBarTheme active is coral rail-ativo, not violet', () {
    final nav = theme.navigationBarTheme;
    expect(nav.indicatorColor, AppColors.overlayRailAtivo);
    expect(nav.indicatorColor, isNot(AppColors.overlayEstadoAtivo));
    expect(
      nav.iconTheme?.resolve({WidgetState.selected})?.color,
      AppColors.coral,
    );
    expect(
      nav.iconTheme?.resolve(const <WidgetState>{})?.color,
      AppColors.text3,
    );
    expect(
      nav.labelTextStyle?.resolve({WidgetState.selected})?.color,
      AppColors.coral,
    );
    expect(
      nav.labelTextStyle?.resolve(const <WidgetState>{})?.color,
      AppColors.text3,
    );
  });

  test('lib sources do not introduce amber/blue/legacy coral', () {
    final root = Directory('lib');
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final src = file.readAsStringSync();
      expect(src, isNot(contains('FF4D6D')), reason: file.path);
      expect(src, isNot(contains('Colors.amber')), reason: file.path);
      expect(src, isNot(contains('Colors.blue')), reason: file.path);
      expect(src, isNot(contains('fromSeed')), reason: file.path);
    }
  });
}

Iterable<Color> _schemeColors(ColorScheme scheme) {
  return [
    scheme.primary,
    scheme.onPrimary,
    scheme.primaryContainer,
    scheme.onPrimaryContainer,
    scheme.primaryFixed,
    scheme.primaryFixedDim,
    scheme.onPrimaryFixed,
    scheme.onPrimaryFixedVariant,
    scheme.secondary,
    scheme.onSecondary,
    scheme.secondaryContainer,
    scheme.onSecondaryContainer,
    scheme.secondaryFixed,
    scheme.secondaryFixedDim,
    scheme.onSecondaryFixed,
    scheme.onSecondaryFixedVariant,
    scheme.tertiary,
    scheme.onTertiary,
    scheme.tertiaryContainer,
    scheme.onTertiaryContainer,
    scheme.tertiaryFixed,
    scheme.tertiaryFixedDim,
    scheme.onTertiaryFixed,
    scheme.onTertiaryFixedVariant,
    scheme.error,
    scheme.onError,
    scheme.errorContainer,
    scheme.onErrorContainer,
    scheme.surface,
    scheme.onSurface,
    scheme.onSurfaceVariant,
    scheme.outline,
    scheme.outlineVariant,
    scheme.shadow,
    scheme.scrim,
    scheme.inverseSurface,
    scheme.onInverseSurface,
    scheme.inversePrimary,
    scheme.surfaceDim,
    scheme.surfaceBright,
    scheme.surfaceContainerLowest,
    scheme.surfaceContainerLow,
    scheme.surfaceContainer,
    scheme.surfaceContainerHigh,
    scheme.surfaceContainerHighest,
    scheme.surfaceTint,
  ];
}

Iterable<Color> _tokenColors(MangaJpTokens tokens) {
  return [
    tokens.bg,
    tokens.rail,
    tokens.surface,
    tokens.surfaceLow,
    tokens.surfaceRaised,
    tokens.border,
    tokens.borderStrong,
    tokens.text,
    tokens.text2,
    tokens.text3,
    tokens.text4,
    tokens.coral,
    tokens.coralText,
    tokens.violet,
    tokens.violetText,
    tokens.mint,
    tokens.onCoral,
    tokens.onMint,
    tokens.overlaySelecaoToque,
    tokens.overlayPalavraNaFrase,
    tokens.overlayPrimaria,
    tokens.overlayEstadoAtivo,
    tokens.overlayRailAtivo,
    tokens.srsErreiFill,
    tokens.srsBomFill,
    tokens.queueNovos,
    tokens.queueRevisoes,
    tokens.queueDrill,
    tokens.stateNovo,
    tokens.stateSalvo,
    tokens.stateAprendendo,
    tokens.stateConhecido,
    tokens.stateIgnorado,
  ];
}
