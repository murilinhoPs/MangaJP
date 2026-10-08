import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

/// Named type-scale styles from `tokens.json` (`type-scale`).
///
/// Range tokens expose both ends (e.g. `ui` 13–14 → [ui13] / [ui14]).
/// Line-height is set only when the token string includes `lh`.
abstract final class AppTypeScale {
  static const List<String> _jpFallback = [AppFonts.jp];
  static const List<String> _uiFallback = [AppFonts.ui];

  static const TextStyle reviewDesktopJp = TextStyle(
    fontFamily: AppFonts.jp,
    fontFamilyFallback: _uiFallback,
    fontSize: 120,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle contagemBiblioteca = TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: _jpFallback,
    fontSize: 96,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle reviewMobileJp = TextStyle(
    fontFamily: AppFonts.jp,
    fontFamilyFallback: _uiFallback,
    fontSize: 72,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle contagemHome = TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: _jpFallback,
    fontSize: 64,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle detalheDesktopJp = TextStyle(
    fontFamily: AppFonts.jp,
    fontFamilyFallback: _uiFallback,
    fontSize: 56,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle detalheMobileJp = TextStyle(
    fontFamily: AppFonts.jp,
    fontFamilyFallback: _uiFallback,
    fontSize: 48,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle lookupJp = TextStyle(
    fontFamily: AppFonts.jp,
    fontFamilyFallback: _uiFallback,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle fraseLeitorDesktopJp = TextStyle(
    fontFamily: AppFonts.jp,
    fontFamilyFallback: _uiFallback,
    fontSize: 30,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.text,
  );

  static const TextStyle tituloTela = TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: _jpFallback,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  /// Lower end of `balao-pagina-mobile-jp` 22–24/400 lh 1.7.
  static const TextStyle balaoPaginaMobileJp = TextStyle(
    fontFamily: AppFonts.jp,
    fontFamilyFallback: _uiFallback,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.7,
    color: AppColors.text,
  );

  /// Upper end of `balao-pagina-mobile-jp` 22–24/400 lh 1.7.
  static const TextStyle balaoPaginaMobileJp24 = TextStyle(
    fontFamily: AppFonts.jp,
    fontFamilyFallback: _uiFallback,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.7,
    color: AppColors.text,
  );

  static const TextStyle linhaCadernoJp = TextStyle(
    fontFamily: AppFonts.jp,
    fontFamilyFallback: _uiFallback,
    fontSize: 21,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle botaoPrimario = TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: _jpFallback,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle definicao = TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: _jpFallback,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle ui13 = TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: _jpFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle ui14 = TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: _jpFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle metadados11 = TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: _jpFallback,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.text2,
  );

  static const TextStyle metadados12 = TextStyle(
    fontFamily: AppFonts.ui,
    fontFamilyFallback: _jpFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.text2,
  );

  static const TextStyle mono10 = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.text2,
  );

  static const TextStyle mono11 = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.text2,
  );
}
