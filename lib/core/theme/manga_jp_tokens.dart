import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Non-Material DS roles (coral-text, surfaces, overlays, SRS fills, …).
///
/// Material roles live on [ColorScheme]. Everything else is read from this
/// [ThemeExtension] so widgets never hardcode hex.
@immutable
class MangaJpTokens extends ThemeExtension<MangaJpTokens> {
  const MangaJpTokens({
    required this.bg,
    required this.rail,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.coral,
    required this.coralText,
    required this.violet,
    required this.violetText,
    required this.mint,
    required this.onCoral,
    required this.onMint,
    required this.overlaySelecaoToque,
    required this.overlayPalavraNaFrase,
    required this.overlayPrimaria,
    required this.overlayEstadoAtivo,
    required this.overlayRailAtivo,
    required this.srsErreiFill,
    required this.srsBomFill,
    required this.queueNovos,
    required this.queueRevisoes,
    required this.queueDrill,
    required this.stateNovo,
    required this.stateSalvo,
    required this.stateAprendendo,
    required this.stateConhecido,
    required this.stateIgnorado,
  });

  /// Tokens.json 1:1.
  static const MangaJpTokens data = MangaJpTokens(
    bg: AppColors.bg,
    rail: AppColors.rail,
    surface: AppColors.surface,
    surfaceLow: AppColors.surfaceLow,
    surfaceRaised: AppColors.surfaceRaised,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    text: AppColors.text,
    text2: AppColors.text2,
    text3: AppColors.text3,
    text4: AppColors.text4,
    coral: AppColors.coral,
    coralText: AppColors.coralText,
    violet: AppColors.violet,
    violetText: AppColors.violetText,
    mint: AppColors.mint,
    onCoral: AppColors.onCoral,
    onMint: AppColors.onMint,
    overlaySelecaoToque: AppColors.overlaySelecaoToque,
    overlayPalavraNaFrase: AppColors.overlayPalavraNaFrase,
    overlayPrimaria: AppColors.overlayPrimaria,
    overlayEstadoAtivo: AppColors.overlayEstadoAtivo,
    overlayRailAtivo: AppColors.overlayRailAtivo,
    srsErreiFill: AppColors.srsErreiFill,
    srsBomFill: AppColors.srsBomFill,
    queueNovos: AppColors.violet,
    queueRevisoes: AppColors.mint,
    queueDrill: AppColors.coral,
    stateNovo: AppColors.text,
    stateSalvo: AppColors.text,
    stateAprendendo: AppColors.violetText,
    stateConhecido: AppColors.mint,
    stateIgnorado: AppColors.text3,
  );

  final Color bg;
  final Color rail;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color text2;
  final Color text3;
  final Color text4;
  final Color coral;
  final Color coralText;
  final Color violet;
  final Color violetText;
  final Color mint;
  final Color onCoral;
  final Color onMint;
  final Color overlaySelecaoToque;
  final Color overlayPalavraNaFrase;
  final Color overlayPrimaria;
  final Color overlayEstadoAtivo;
  final Color overlayRailAtivo;
  final Color srsErreiFill;
  final Color srsBomFill;
  final Color queueNovos;
  final Color queueRevisoes;
  final Color queueDrill;
  final Color stateNovo;
  final Color stateSalvo;
  final Color stateAprendendo;
  final Color stateConhecido;
  final Color stateIgnorado;

  /// `state.*` roles (`learning` / `known` are DB names for the same tokens).
  Color wordState(String state) {
    return switch (state) {
      'novo' => stateNovo,
      'salvo' || 'saved' => stateSalvo,
      'aprendendo' || 'learning' => stateAprendendo,
      'conhecido' || 'known' => stateConhecido,
      'ignorado' || 'ignored' => stateIgnorado,
      _ => stateNovo,
    };
  }

  @override
  MangaJpTokens copyWith({
    Color? bg,
    Color? rail,
    Color? surface,
    Color? surfaceLow,
    Color? surfaceRaised,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? text2,
    Color? text3,
    Color? text4,
    Color? coral,
    Color? coralText,
    Color? violet,
    Color? violetText,
    Color? mint,
    Color? onCoral,
    Color? onMint,
    Color? overlaySelecaoToque,
    Color? overlayPalavraNaFrase,
    Color? overlayPrimaria,
    Color? overlayEstadoAtivo,
    Color? overlayRailAtivo,
    Color? srsErreiFill,
    Color? srsBomFill,
    Color? queueNovos,
    Color? queueRevisoes,
    Color? queueDrill,
    Color? stateNovo,
    Color? stateSalvo,
    Color? stateAprendendo,
    Color? stateConhecido,
    Color? stateIgnorado,
  }) {
    return MangaJpTokens(
      bg: bg ?? this.bg,
      rail: rail ?? this.rail,
      surface: surface ?? this.surface,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      text4: text4 ?? this.text4,
      coral: coral ?? this.coral,
      coralText: coralText ?? this.coralText,
      violet: violet ?? this.violet,
      violetText: violetText ?? this.violetText,
      mint: mint ?? this.mint,
      onCoral: onCoral ?? this.onCoral,
      onMint: onMint ?? this.onMint,
      overlaySelecaoToque: overlaySelecaoToque ?? this.overlaySelecaoToque,
      overlayPalavraNaFrase: overlayPalavraNaFrase ?? this.overlayPalavraNaFrase,
      overlayPrimaria: overlayPrimaria ?? this.overlayPrimaria,
      overlayEstadoAtivo: overlayEstadoAtivo ?? this.overlayEstadoAtivo,
      overlayRailAtivo: overlayRailAtivo ?? this.overlayRailAtivo,
      srsErreiFill: srsErreiFill ?? this.srsErreiFill,
      srsBomFill: srsBomFill ?? this.srsBomFill,
      queueNovos: queueNovos ?? this.queueNovos,
      queueRevisoes: queueRevisoes ?? this.queueRevisoes,
      queueDrill: queueDrill ?? this.queueDrill,
      stateNovo: stateNovo ?? this.stateNovo,
      stateSalvo: stateSalvo ?? this.stateSalvo,
      stateAprendendo: stateAprendendo ?? this.stateAprendendo,
      stateConhecido: stateConhecido ?? this.stateConhecido,
      stateIgnorado: stateIgnorado ?? this.stateIgnorado,
    );
  }

  @override
  ThemeExtension<MangaJpTokens> lerp(
    ThemeExtension<MangaJpTokens>? other,
    double t,
  ) {
    if (other is! MangaJpTokens) {
      return this;
    }
    return MangaJpTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      rail: Color.lerp(rail, other.rail, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      text4: Color.lerp(text4, other.text4, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralText: Color.lerp(coralText, other.coralText, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      violetText: Color.lerp(violetText, other.violetText, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      onCoral: Color.lerp(onCoral, other.onCoral, t)!,
      onMint: Color.lerp(onMint, other.onMint, t)!,
      overlaySelecaoToque: Color.lerp(
        overlaySelecaoToque,
        other.overlaySelecaoToque,
        t,
      )!,
      overlayPalavraNaFrase: Color.lerp(
        overlayPalavraNaFrase,
        other.overlayPalavraNaFrase,
        t,
      )!,
      overlayPrimaria: Color.lerp(overlayPrimaria, other.overlayPrimaria, t)!,
      overlayEstadoAtivo: Color.lerp(
        overlayEstadoAtivo,
        other.overlayEstadoAtivo,
        t,
      )!,
      overlayRailAtivo: Color.lerp(overlayRailAtivo, other.overlayRailAtivo, t)!,
      srsErreiFill: Color.lerp(srsErreiFill, other.srsErreiFill, t)!,
      srsBomFill: Color.lerp(srsBomFill, other.srsBomFill, t)!,
      queueNovos: Color.lerp(queueNovos, other.queueNovos, t)!,
      queueRevisoes: Color.lerp(queueRevisoes, other.queueRevisoes, t)!,
      queueDrill: Color.lerp(queueDrill, other.queueDrill, t)!,
      stateNovo: Color.lerp(stateNovo, other.stateNovo, t)!,
      stateSalvo: Color.lerp(stateSalvo, other.stateSalvo, t)!,
      stateAprendendo: Color.lerp(stateAprendendo, other.stateAprendendo, t)!,
      stateConhecido: Color.lerp(stateConhecido, other.stateConhecido, t)!,
      stateIgnorado: Color.lerp(stateIgnorado, other.stateIgnorado, t)!,
    );
  }
}

extension MangaJpThemeContext on BuildContext {
  MangaJpTokens get tokens => Theme.of(this).extension<MangaJpTokens>()!;
}
