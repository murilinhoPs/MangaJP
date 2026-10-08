import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_icons.dart';
import 'app_radius.dart';
import 'app_targets.dart';
import 'app_type_scale.dart';
import 'manga_jp_tokens.dart';

export 'app_colors.dart';
export 'app_fonts.dart';
export 'app_icons.dart';
export 'app_radius.dart';
export 'app_targets.dart';
export 'app_type_scale.dart';
export 'manga_jp_tokens.dart';

/// Dark Material theme: explicit hex from `tokens.json`, not a seed palette.
abstract final class AppTheme {
  /// DS is dark-only; kept so existing `theme:` callers stay dark.
  static ThemeData get light => dark;

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.coral,
      onPrimary: AppColors.onCoral,
      primaryContainer: AppColors.overlayPrimaria,
      onPrimaryContainer: AppColors.coralText,
      primaryFixed: AppColors.coral,
      primaryFixedDim: AppColors.coral,
      onPrimaryFixed: AppColors.onCoral,
      onPrimaryFixedVariant: AppColors.coralText,
      secondary: AppColors.violet,
      onSecondary: AppColors.text,
      secondaryContainer: AppColors.overlayEstadoAtivo,
      onSecondaryContainer: AppColors.violetText,
      secondaryFixed: AppColors.violet,
      secondaryFixedDim: AppColors.violet,
      onSecondaryFixed: AppColors.text,
      onSecondaryFixedVariant: AppColors.violetText,
      tertiary: AppColors.mint,
      onTertiary: AppColors.onMint,
      tertiaryContainer: AppColors.srsBomFill,
      onTertiaryContainer: AppColors.mint,
      tertiaryFixed: AppColors.mint,
      tertiaryFixedDim: AppColors.mint,
      onTertiaryFixed: AppColors.onMint,
      onTertiaryFixedVariant: AppColors.mint,
      error: AppColors.coral,
      onError: AppColors.onCoral,
      errorContainer: AppColors.srsErreiFill,
      onErrorContainer: AppColors.coralText,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.text2,
      outline: AppColors.border,
      outlineVariant: AppColors.borderStrong,
      shadow: AppColors.bg,
      scrim: AppColors.bg,
      inverseSurface: AppColors.text,
      onInverseSurface: AppColors.bg,
      inversePrimary: AppColors.coralText,
      surfaceDim: AppColors.rail,
      surfaceBright: AppColors.surfaceRaised,
      surfaceContainerLowest: AppColors.bg,
      surfaceContainerLow: AppColors.rail,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceLow,
      surfaceContainerHighest: AppColors.surfaceRaised,
      surfaceTint: AppColors.coral,
    );

    final shapeDock = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
    );
    final shapeCard = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: const BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: AppFonts.ui,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      cardColor: AppColors.surface,
      dividerColor: AppColors.border,
      splashColor: AppColors.overlaySelecaoToque,
      highlightColor: AppColors.overlayPrimaria,
      hoverColor: AppColors.overlayPrimaria,
      focusColor: AppColors.overlayEstadoAtivo,
      extensions: const <ThemeExtension<dynamic>>[MangaJpTokens.data],
      textTheme: _textTheme,
      primaryTextTheme: _textTheme,
      iconTheme: const IconThemeData(
        color: AppColors.text2,
        size: AppIcons.sizeMin,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.bg,
        titleTextStyle: AppTypeScale.tituloTela,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: AppColors.surface,
        shape: shapeCard,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.overlayPrimaria,
          foregroundColor: AppColors.text,
          disabledBackgroundColor: AppColors.surfaceLow,
          disabledForegroundColor: AppColors.text4,
          minimumSize: const Size(AppTargets.min, AppTargets.min),
          textStyle: AppTypeScale.botaoPrimario,
          side: const BorderSide(color: AppColors.coral),
          shape: shapeDock,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.surface,
          disabledForegroundColor: AppColors.text4,
          minimumSize: const Size(AppTargets.min, AppTargets.min),
          textStyle: AppTypeScale.ui14,
          side: const BorderSide(color: AppColors.border),
          shape: shapeDock,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.coral,
          minimumSize: const Size(AppTargets.min, AppTargets.min),
          textStyle: AppTypeScale.ui14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.overlayPrimaria,
        disabledColor: AppColors.surfaceLow,
        labelStyle: AppTypeScale.metadados12.copyWith(color: AppColors.text2),
        secondaryLabelStyle: AppTypeScale.metadados12.copyWith(
          color: AppColors.text,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.border),
        checkmarkColor: AppColors.coral,
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypeScale.ui14.copyWith(color: AppColors.text3),
        labelStyle: AppTypeScale.ui14.copyWith(color: AppColors.text2),
        prefixIconColor: AppColors.text3,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.dockAcaoBusca),
          borderSide: const BorderSide(color: AppColors.coral),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.text2,
        textColor: AppColors.text,
        selectedColor: AppColors.coral,
        selectedTileColor: AppColors.overlaySelecaoToque,
        subtitleTextStyle: AppTypeScale.ui13,
        titleTextStyle: AppTypeScale.ui14,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: AppColors.surfaceRaised,
        titleTextStyle: AppTypeScale.tituloTela,
        contentTextStyle: AppTypeScale.ui14,
        shape: shapeCard,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheetReview),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: AppTypeScale.ui14,
        actionTextColor: AppColors.coralText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.linha),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.coral,
        circularTrackColor: AppColors.border,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.overlayPrimaria,
        foregroundColor: AppColors.coral,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppRadius.dockAcaoBusca),
          ),
          side: BorderSide(color: AppColors.coral),
        ),
      ),
      // Color only (M1.20 owns shell layout). Default M3 indicator uses
      // secondaryContainer (violet / Aprendendo). Active = coral + rail-ativo.
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.overlayRailAtivo,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.coral : AppColors.text3,
            size: AppIcons.sizeMin,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypeScale.metadados11.copyWith(
            color: selected ? AppColors.coral : AppColors.text3,
          );
        }),
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTypeScale.reviewDesktopJp,
    displayMedium: AppTypeScale.contagemBiblioteca,
    displaySmall: AppTypeScale.reviewMobileJp,
    headlineLarge: AppTypeScale.contagemHome,
    headlineMedium: AppTypeScale.detalheDesktopJp,
    headlineSmall: AppTypeScale.tituloTela,
    titleLarge: AppTypeScale.tituloTela,
    titleMedium: AppTypeScale.botaoPrimario,
    titleSmall: AppTypeScale.ui14,
    bodyLarge: AppTypeScale.definicao,
    bodyMedium: AppTypeScale.ui14,
    bodySmall: AppTypeScale.metadados12,
    labelLarge: AppTypeScale.botaoPrimario,
    labelMedium: AppTypeScale.ui13,
    labelSmall: AppTypeScale.metadados11,
  );
}
