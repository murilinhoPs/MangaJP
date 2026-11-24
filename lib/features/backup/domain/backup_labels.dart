/// pt-BR copy for F25 backup JSON (Ajustes › Backup + Sobre / Fontes).
abstract final class BackupLabels {
  static const section = 'Backup';
  static const subtitle =
      'Caderno, SRS e kanji salvos. Imagens não entram neste arquivo.';
  static const exportJson = 'Exportar JSON';
  static const restoreJson = 'Restaurar JSON';
  static const confirmTitle = 'Substituir Caderno e SRS?';
  static const confirmBody =
      'O restore substitui as palavras, os cards/SRS e os kanji salvos deste '
      'aparelho. Páginas e imagens permanecem. Esta ação não desfaz.';
  static const confirmAction = 'Restaurar';
  static const cancel = 'Cancelar';
  static const exportOk = 'Backup exportado.';
  static const restoreOk = 'Backup restaurado.';
  static const invalidFile = 'Arquivo de backup inválido. Nada foi gravado.';
  static const restoreFailed = 'Falha ao restaurar. Nada foi gravado.';
  static const exportDialogTitle = 'Exportar backup';
  static const importDialogTitle = 'Restaurar backup';
  static const aboutSection = 'Sobre / Fontes';
  static const jmdict = 'JMdict/EDICT © EDRDG, CC BY-SA 3.0';
  static const kanjidic = 'KANJIDIC2 © EDRDG, CC BY-SA 4.0';
  static const yomitan = 'Deinflexão: Yomitan, GPL-3.0';
  static const kanjidicUrl =
      'https://www.edrdg.org/wiki/index.php/KANJIDIC_Project';
  static const jmdictUrl =
      'https://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project';
  static const yomitanUrl = 'https://github.com/yomidevs/yomitan';

  static String restoreOkSkipped(int skipped) {
    if (skipped == 1) {
      return 'Backup restaurado. 1 kanji ignorado (literal inválido).';
    }
    return 'Backup restaurado. $skipped kanji ignorados (literal inválido).';
  }

  static String unknownSchema({
    required int fileSchema,
    required int appSchema,
  }) {
    return 'Este backup é de um schema mais novo ($fileSchema). '
        'Este app está no schema $appSchema. Nada foi gravado.';
  }

  static String unknownFormat(int fileFormat) {
    return 'Este backup usa o formato $fileFormat, que este app não conhece. '
        'Nada foi gravado.';
  }
}
