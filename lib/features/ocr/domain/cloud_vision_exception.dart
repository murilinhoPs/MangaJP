/// Typed Cloud Vision failures. Messages never include the API key.
sealed class CloudVisionException implements Exception {
  const CloudVisionException({
    required this.testMessage,
    required this.fallbackMessage,
  });

  /// Copy for **Testar chave** in Ajustes.
  final String testMessage;

  /// Non-blocking crop fallback notice.
  final String fallbackMessage;

  bool get fallsBackToLocal => true;

  @override
  String toString() => testMessage;
}

final class CloudVisionMissingApiKey extends CloudVisionException {
  const CloudVisionMissingApiKey()
    : super(
        testMessage: 'Cole uma chave primeiro.',
        fallbackMessage: 'Sem chave. Recorte lido com manga-ocr.',
      );
}

final class CloudVisionInvalidApiKey extends CloudVisionException {
  const CloudVisionInvalidApiKey()
    : super(
        testMessage: 'Chave inválida.',
        fallbackMessage: 'Chave inválida. Recorte lido com manga-ocr.',
      );
}

final class CloudVisionQuotaExceeded extends CloudVisionException {
  const CloudVisionQuotaExceeded()
    : super(
        testMessage: 'Cota do Cloud Vision esgotada.',
        fallbackMessage:
            'Cota do Cloud Vision esgotada. Recorte lido com manga-ocr.',
      );
}

final class CloudVisionNetworkError extends CloudVisionException {
  const CloudVisionNetworkError()
    : super(
        testMessage: 'Sem rede.',
        fallbackMessage: 'Sem rede. Recorte lido com manga-ocr.',
      );
}

final class CloudVisionTimeout extends CloudVisionException {
  const CloudVisionTimeout()
    : super(
        testMessage: 'Cloud Vision não respondeu (15 s).',
        fallbackMessage:
            'Cloud Vision não respondeu (15 s). Recorte lido com manga-ocr.',
      );
}

final class CloudVisionUnexpected extends CloudVisionException {
  const CloudVisionUnexpected()
    : super(
        testMessage: 'Não foi possível falar com o Cloud Vision.',
        fallbackMessage: 'Cloud Vision falhou. Recorte lido com manga-ocr.',
      );
}
