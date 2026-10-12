/// Portuguese copy for `/pages/:id` (Design Deck Página / Lookup).
abstract final class PageLabels {
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
}

/// Screenshot / print helper only — not a production feature.
///
/// Default `false`, so release tree-shaking drops `_maybeAutoLookup`.
/// Enable with `flutter run --dart-define=MANGAJP_PAGE_LOOKUP=true` to open
/// lookup on 食べた (or the first crop) after the page loads.
const kPageShotLookup = bool.fromEnvironment('MANGAJP_PAGE_LOOKUP');
