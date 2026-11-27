# Backup JSON (F25)

Rota: `/settings` (Ajustes › Backup). Sem rota nova. Issue: [#99](https://github.com/murilinhoPs/MangaJP/issues/99). Squash [`1990912`](https://github.com/murilinhoPs/MangaJP/commit/1990912) do [#118](https://github.com/murilinhoPs/MangaJP/pull/118) (head `13cdb49`). Specs ligadas: [settings](settings.md), [caderno](caderno.md), [kanji](kanji.md), [flashcards](flashcards.md). Plano: [`m2.md`](../milestones/m2.md) M2.7. Q6 e Q7 fechadas no default implementado.

## Objetivo

Exportar e restaurar o Caderno, o SRS e os kanji salvos num único arquivo JSON, sem páginas nem imagens. Restore **substitui** os dados depois de confirmação. Sem migração Drift: o schema permanece **10**.

## Comportamento

### Onde vive

Seção **Backup** em `/settings`, abaixo de OCR e acima de Sobre / Fontes. Subtítulo: «Caderno, SRS e kanji salvos. Imagens não entram neste arquivo.»

| Botão | Widget | Cor |
| --- | --- | --- |
| **Exportar JSON** | `FilledButton` | borda coral (`#FF5C7A`) do `filledButtonTheme` |
| **Restaurar JSON** | `OutlinedButton` | borda `border` |

Diálogo de confirmação («Substituir Caderno e SRS?»): botão **Restaurar** em `tokens.danger` (`#FF6A4D`); **Cancelar** é ghost. Corpo: «O restore substitui as palavras, os cards/SRS e os kanji salvos deste aparelho. Páginas e imagens permanecem. Esta ação não desfaz.»

Nome sugerido do arquivo: `mangajp-backup.json`.

Sobre / Fontes (NF8, sem rota nova) fica no mesmo `/settings`: JMdict/EDICT, KANJIDIC2, Yomitan — [settings](settings.md).

### Formato

Um arquivo JSON (pretty-print, chaves snake_case). Envelope independente do Drift:

- `format_version` **2** no export corrente. v2 adiciona `crop_words`. O decoder aceita `1..=2`. `format_version` ausente vale **1** (fixtures de schema 8 e backups já exportados).
- `schema_version` = `AppDatabase.schemaVersion` (hoje **10**). O [#118](https://github.com/murilinhoPs/MangaJP/pull/118) **não** adiciona migração; o schema permanece 10.
- `exported_at` em UTC ISO-8601.

Tabelas no JSON (arrays; vazios se não houver linhas):

| Chave | Origem Drift |
| --- | --- |
| `words` | `words` (`id`, `seq`, `lemma`, `reading`, `user_note`, `lemma_key`, `created_at`) |
| `word_states` | `word_states` (`word_id`, `state`, `updated_at`) |
| `cards` | `cards` (`id`, `word_id`, `kind`, `created_at`, `suspend_reason`) |
| `card_srs` | `card_srs` |
| `review_logs` | `review_logs` |
| `crop_words` | `crop_words` (`crop_id`, `word_id`, `created_at`) |
| `saved_kanji` | `saved_kanji` (`literal`, `saved_at`, `origin_page_id` nullable) |

Não entram: `pages`, `crops`, imagens, `app_meta`, chave do Cloud Vision.

`saved_kanji` / `crop_words` ausentes no arquivo = lista vazia. Arquivo v1 sem `crop_words` continua válido.

`lemma_key` ausente ou vazio no decode vira `stripVariationSelectors(lemma)`.

### Restore

Decode **antes** do diálogo: arquivo inválido mostra snackbar e **não** abre a confirmação. Restore só grava depois de **Restaurar** no diálogo. Cancelar o picker ou o diálogo: no-op, sem snackbar.

Uma transação Drift. Apaga `crop_words`, `review_logs`, `card_srs`, `cards`, `word_states`, `saved_kanji`, `words` e reinsere o conteúdo do arquivo. Páginas, crops e imagens **permanecem**.

Replace, não merge: o Caderno, o SRS e `saved_kanji` do aparelho somem e voltam os do arquivo.

`crop_words`: o link só volta se `crop_id` ainda existe em `crops` **e** `word_id` está nas palavras restauradas — o mesmo skip de `origin_page_id`. Duplicata no arquivo é pulada.

`origin_page_id`: se a página não existe no destino, o kanji entra com `origin_page_id` null.

Cada `literal` passa por `normalizeKanjiLiteral` (strip IVS/VS, exatamente 1 code point). Inválido **não entra**; o resto do restore continua; a UI conta os pulados.

v1 sem `crop_words`: restore conclui; palavras voltam; nenhum link.

### Validação

Decode **não grava nada**. Recusados (`BackupRejectedException`; banco intacto):

| Caso | Snackbar |
| --- | --- |
| JSON corrompido, não-JSON, raiz que não é objeto, UTF-8 inválido | «Arquivo de backup inválido. Nada foi gravado.» |
| `format_version` fora de `1..=2` (ex. 99) | «Este backup usa o formato N, que este app não conhece. Nada foi gravado.» |
| `schema_version` **maior** que o do app | «Este backup é de um schema mais novo (N). Este app está no schema M. Nada foi gravado.» |
| `schema_version` menor que 1 | «Arquivo de backup inválido. Nada foi gravado.» |
| enum inválido (`phase`, `kind`, `state`, `suspend_reason`) | «Arquivo de backup inválido. Nada foi gravado.» |

Schema **mais antigo** que o app (ex. 8 no app 10) **é aceito**. Enums válidos hoje: `WordState` (`saved` / `learning` / `known` / `ignored` / `unknown`), `FlashcardKind` (`vocab`), `CardPhase` (`neu` / `learning` / `review` / `relearning`), `SuspendReason` (`user` / `known` / `ignored`) ou `null`.

### Snackbars

| Situação | Copy |
| --- | --- |
| Export ok | «Backup exportado.» |
| Falha de export (incluindo escrita parcial / `FileSystemException` no desktop) | «Falha ao exportar.» |
| Restore ok | «Backup restaurado.» |
| Restore ok com kanji pulado | «Backup restaurado. 1 kanji ignorado (literal inválido).» / «Backup restaurado. N kanji ignorados (literal inválido).» |
| Falha no meio da transação (já revertida) | «Falha ao restaurar. Nada foi gravado.» |

Snackbar flutuante; margem inferior = `ShellLayout.commandBarPaddingOf` + 8 (sobe o dock). Sobre / Fontes, se estiver na dobra de baixo, ainda pode ficar atrás do snackbar.

### Plataformas

- **Android e iOS:** `file_picker` persiste os bytes no canal da plataforma (SAF no Android). Sem rewrite `dart:io` no path — um rewrite depois do save ok lançava `FileSystemException` e mostrava «Falha ao exportar.» com o JSON já gravado.
- **Desktop:** sucesso **só** depois de o JSON no disco bater (tamanho + `jsonDecode` + bytes). Linux / Windows: `saveFile` **sem** `bytes` (o picker 10.3.10 com `bytes:` grava direto no destino e destruiria o backup antigo); depois sidecar único `.<pid>.<µs>.tmp`, flush, validação, rename. macOS sandbox (`files.user-selected.read-write`): o painel só autoriza o arquivo escolhido, não a pasta — um sidecar `.tmp` dá EPERM. O picker grava os bytes no path; se tamanho/`jsonDecode` já batem, não reescreve; se estiver errado, reescreve **no próprio path**. Falha não conta como sucesso. Android SAF inalterado.

### Q6 / Q7

Fechadas no default implementado (Murilo não decidiu antes do [#118](https://github.com/murilinhoPs/MangaJP/pull/118)):

- **Q6:** um arquivo JSON com `format_version` e `schema_version`; Caderno + SRS + `saved_kanji` + `crop_words`; zip de imagens opcional e separado (**não** nesta entrega); **sem** export SQLite.
- **Q7:** restore **substitui** Caderno + SRS + `saved_kanji` depois de confirmação explícita. Páginas e imagens permanecem.

## Critérios de aceite

- **AC-backup-export:** exportar produz um JSON com `format_version` (2) e `schema_version` (10) e contém Caderno + SRS (`words` / `word_states` / `cards` / `card_srs` / `review_logs`) + `saved_kanji` (vazio se não houver kanji) + `crop_words` (vazio se não houver vínculo).
- **AC-backup-roundtrip:** restaurar um backup da versão corrente devolve as mesmas palavras, cards/SRS, kanji salvos e `crop_words` cujo crop ainda existe. Restore **substitui** (Q7).
- **AC-backup-crop-words:** crop inexistente é pulado; o resto restaura. `format_version` 1 sem `crop_words` restaura palavras e nenhum link.
- **AC-backup-old-schema:** restaurar um backup de schema anterior (ex. schema 8, sem `saved_kanji`) conclui; Caderno + SRS voltam; a aba Kanji fica vazia, sem erro.
- **AC-backup-origin-page:** kanji com `origin_page_id` null, ou apontando para página inexistente, entra em `saved_kanji` com `origin_page_id` null.
- **AC-backup-unknown-schema:** `schema_version` **maior** que o do app, ou `format_version` fora de `1..=2`, é recusado com mensagem; nada é gravado. Enum inválido (`phase` / `kind` / `state` / `suspend_reason`) também recusa e não grava.
- **AC-backup-atomic:** restore é uma transação Drift; se falhar no meio, **nada** é gravado.
- **AC-backup-normalize:** cada `literal` passa por `normalizeKanjiLiteral`; inválido não entra, com contagem na UI.
- **AC-kanjidic-attr:** seção Sobre / Fontes **dentro de `/settings`** (sem rota nova) mostra «KANJIDIC2 © EDRDG, CC BY-SA 4.0» com link da EDRDG.

> Pendente: zip de imagens (opcional, separado). Fora desta entrega.
> Pendente: limpeza manual de storage.
