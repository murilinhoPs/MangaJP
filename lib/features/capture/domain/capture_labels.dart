/// Portuguese copy for `/capture` (Design Deck Crop / Captura).
abstract final class CaptureLabels {
  static const confirmar = 'Confirmar crop';
  static const cancelar = 'Cancelar';
  static const recortes = 'Recortes';
  static const arrasteParaCriar = 'arraste para criar';
  static const escolherGaleria = 'Escolher da galeria';

  static String recortesMeta(int count) {
    if (count <= 0) {
      return '';
    }
    final noun = count == 1 ? '1 recorte' : '$count recortes';
    return '$noun · ordem ← automática';
  }

  static String recortesCountHint(int count) {
    if (count <= 0) {
      return '';
    }
    return '$count · ordem ← automática';
  }

  static String recorteRow(int number) => 'Recorte $number';
}
