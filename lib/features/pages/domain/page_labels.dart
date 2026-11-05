/// Portuguese copy for `/pages` (history) and `/pages/:id` (Deck Página).
abstract final class PageLabels {
  static const pagesTitle = 'Páginas';
  static const empty = 'Nenhuma página.';
  static const emptyHint = 'Importe da galeria para ver o histórico aqui.';
  static const gallery = 'Galeria +';
  static const loadError = 'Não foi possível carregar as páginas.';
  static const verTodas = 'Ver todas';
  static const watermark = '頁';
  static const voltar = 'Voltar';
  static const editar = 'Editar';
  static const adicionar = 'Captura';
  static const nenhumOcr = 'Nenhum texto OCR nesta página.';
  static const toquePalavra = 'Toque uma palavra no texto.';
  static const dicionarioIndisponivel = 'Dicionário indisponível';
  static const aprendendo = 'Aprendendo';
  static const conhecido = 'Conhecido';
  static const ignorar = 'Ignorar';
  static const salvar = 'Salvar';
  static const editarOcrTitulo = 'Editar OCR';
  static const salvarOcr = 'Salvar OCR';
  static const recorteN = 'Recorte';
}

/// Layout numbers from the Deck / brief, not `tokens.json`.
abstract final class PageLayout {
  /// Lookup drawer on desktop (≥ 900). Deck Página.
  static const double lookupDrawerWidth = 400;

  /// Mobile lookup is a half-screen sheet (`radius.sheet-review` 24).
  static const double lookupSheetFraction = 0.5;

  /// Wide kanji ficha. 0.5 plus command-bar inset hid "eat; food" behind
  /// Salvar kanji; 0.5 without the inset fits 食 with no scroll. 0.45 keeps
  /// 食 meanings at full contrast above the fade; TRAÇOS peeks through the
  /// fade so overflow stays visible at 1280×800. Kanji with longer
  /// on/kun/meanings (生, 上, 行) scroll inside the same fraction — the fade
  /// is the overflow signal; do not grow the sheet or 食 loses the peek.
  static const double kanjiSheetFractionWide = 0.45;

  /// Bottom fade while the kanji ficha has more content below. Short and
  /// below full opacity so the TRAÇOS (or other) label on the edge stays
  /// readable, without covering 食 meanings on open.
  static const double kanjiSheetScrollFadeHeight = 12;
}

/// Screenshot / print helper only — not a production feature.
///
/// Default `false`, so release tree-shaking drops `_maybeAutoLookup`.
/// Enable with `flutter run --dart-define=MANGAJP_PAGE_LOOKUP=true` to open
/// lookup on 食べた (or the first crop) after the page loads.
const kPageShotLookup = bool.fromEnvironment('MANGAJP_PAGE_LOOKUP');
