import '../../notebook/presentation/notebook_labels.dart';
import '../../words/domain/word_state.dart';
import '../domain/suspend_reason.dart';

/// Portuguese Deck copy (list, empty, F23 suspend / reactivate).
abstract final class DeckLabels {
  static const title = 'Deck';
  static const empty = 'Nenhum card.';
  static const emptyHint = 'Aprenda uma palavra no Caderno para vê-la aqui.';
  static const watermark = '札';
  static const suspender = 'Suspender';
  static const reativar = 'Reativar';
  static const suspenso = 'Suspenso';
  static const suspenderTitulo = 'Suspender este card?';
  static const suspenderBody =
      'O card sai da fila de revisão e permanece no Deck. '
      'O progresso SRS é mantido.';
  static const cancelar = 'Cancelar';

  /// Visible Deck status: F23 [Suspenso] wins over Caderno [WordState].
  static String status({
    required String? suspendReason,
    required WordState wordState,
  }) {
    if (SuspendReason.fromDb(suspendReason) == SuspendReason.user) {
      return suspenso;
    }
    return NotebookLabels.state(wordState);
  }
}
