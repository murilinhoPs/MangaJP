import 'package:flutter/material.dart';

/// Color tokens from `tokens.json` (MangaJP Study · M1). No extra hex roles.
abstract final class AppColors {
  // Surfaces
  static const Color bg = Color(0xFF0E0D12);
  static const Color rail = Color(0xFF121117);
  static const Color surface = Color(0xFF18171E);
  static const Color surfaceLow = Color(0xFF1D1C24);
  static const Color surfaceRaised = Color(0xFF23212B);
  static const Color border = Color(0xFF2E2C37);
  static const Color borderStrong = Color(0xFF403D4B);

  // Text
  static const Color text = Color(0xFFF2F0F5);
  static const Color text2 = Color(0xFFB3AFBD);
  static const Color text3 = Color(0xFF8C8898);
  static const Color text4 = Color(0xFF6A6775);

  // Accents
  static const Color coral = Color(0xFFFF5C7A);
  static const Color coralText = Color(0xFFFF8BA0);
  static const Color violet = Color(0xFF7C63F5);
  static const Color violetText = Color(0xFF9A86FA);
  static const Color mint = Color(0xFF4BE3A3);
  static const Color onCoral = Color(0xFF1A0F14);
  static const Color onMint = Color(0xFF06261A);

  // Overlays (`overlay` in tokens.json)
  static const Color overlaySelecaoToque = Color.fromRGBO(255, 92, 122, 0.25);
  static const Color overlayPalavraNaFrase = Color.fromRGBO(124, 99, 245, 0.22);
  static const Color overlayPrimaria = Color.fromRGBO(255, 92, 122, 0.14);
  static const Color overlayEstadoAtivo = Color.fromRGBO(124, 99, 245, 0.14);
  static const Color overlayRailAtivo = Color.fromRGBO(255, 92, 122, 0.16);

  // SRS fills (`srs.*.fill` when not a named role)
  static const Color srsErreiFill = Color.fromRGBO(255, 92, 122, 0.12);
  static const Color srsBomFill = Color.fromRGBO(75, 227, 163, 0.14);

  /// `state.*` → color role. Unknown/custom fall back to `text` like `novo`.
  static Color wordState(String state) {
    return switch (state) {
      'aprendendo' || 'learning' => violetText,
      'conhecido' || 'known' => mint,
      'ignorado' || 'ignored' => text3,
      _ => text,
    };
  }

  /// `queue.*` accent fills.
  static Color queue(String kind) {
    return switch (kind) {
      'novos' => violet,
      'revisoes' => mint,
      'drill' => coral,
      _ => coral,
    };
  }
}
