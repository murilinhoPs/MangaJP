/// pt-BR copy for F26 Cloud Vision (Ajustes › OCR + chip do leitor).
abstract final class CloudVisionLabels {
  static const section = 'OCR';
  static const defaultEngine = 'Padrão: manga-ocr (local)';
  static const toggle = 'Usar OCR na nuvem';
  static const toggleSubtitle =
      'Tenta o Cloud Vision em cada recorte. Sem chave o interruptor não liga.';
  static const apiKey = 'Chave da API Cloud Vision';
  static const apiKeyHint = 'Cole a chave';
  static const apiKeySavedHint = 'Chave salva';
  static const testKey = 'Testar chave';
  static const removeKey = 'Remover chave';
  static const keyringUnavailable =
      'Armazenamento seguro indisponível neste aparelho. '
      'A chave não pode ser salva em texto puro.';
  static const keyringSlow =
      'Armazenamento seguro demorou para responder. '
      'A chave não foi apagada — tente de novo.';
  static const needKeyFirst = 'Cole uma chave primeiro.';
  static const testOk = 'Chave válida.';
  static const keyRemoved = 'Chave removida.';
  static const privacyTitle = 'OCR na nuvem';
  static const privacyBody =
      'A imagem de cada recorte vai para o Google Cloud Vision, com a chave '
      'e a cobrança da sua conta Google Cloud. Só o recorte sai do aparelho — '
      'a página inteira, o Caderno e o SRS ficam locais.';
  static const privacyAccept = 'Aceitar';
  static const privacyDecline = 'Recusar';
  static const chipMangaOcr = 'manga-ocr';
  static const chipCloudVision = 'Cloud Vision';
  static const chipMixed = 'misto';
}
