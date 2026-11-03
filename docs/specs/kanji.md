# Kanji / Caderno

Rotas: `/notebook` (aba Kanji), `/notebook/kanji/:char` (M2). O `:char` é o `literal` normalizado, URL-encoded (go_router decodifica). Specs ligadas: [caderno](caderno.md) (F41–F44), [dicionario](dicionario.md) (lookup), [flashcards](flashcards.md) (F38: milestone próprio entre M2 e M3). F24 e F45 saíram no [#88](https://github.com/murilinhoPs/MangaJP/pull/88) (head `99aaeee`, squash `70d150d`), que fechou a [#58](https://github.com/murilinhoPs/MangaJP/issues/58).

## Objetivo

Mostrar o kanji sozinho (leituras, significados, traços) a partir do KANJIDIC2, permitir **Salvar kanji** no Caderno e consultar a lista depois. Fora do SRS.

## Comportamento

### Fonte — KANJIDIC2 (F24)

O lookup de kanji lê a tabela `kanji` do `jmdict.sqlite` local, a mesma base read-only do JMdict (PRD: `entries` / `forms` / `sense_pos` / `kanji`). A linha traz on/kun, significados e traços.

O dado entra no app no bake: `python3 tools/build_jmdict_sqlite/build_jmdict_sqlite.py --output assets/dict/jmdict.sqlite --with-kanji`. `--with-kanji` baixa o [KANJIDIC2](http://ftp.edrdg.org/pub/Nihongo/kanjidic2.xml.gz) e preenche `kanji`. Sem a flag a tabela existe vazia, com o mesmo schema. O sqlite completo é gitignored; o app o carrega como asset. NF4: download once.

Colunas da tabela de lookup (não confundir com `saved_kanji`): `character`, `readings_json`, `meanings_json`, `stroke_count`, `freq`. Detalhe em [`tools/build_jmdict_sqlite/README.md`](../../tools/build_jmdict_sqlite/README.md).

Licença: KANJIDIC2 é © EDRDG, [CC BY-SA 4.0](https://www.edrdg.org/wiki/index.php/KANJIDIC_Project). Atribuição nos [Ajustes](settings.md) (NF8).

Tamanho (medido 2026-11-03 no arquivo do EDRDG, `http://ftp.edrdg.org/pub/Nihongo/kanjidic2.xml.gz`): **1 488 578 bytes** gzip (`Content-Length` / arquivo baixado) e **15 641 823 bytes** XML descomprimido (gunzip local). Não é um asset separado: vai para dentro de `assets/dict/jmdict.sqlite`. Bake completo no mesmo dia (`tools/build_jmdict_sqlite/build_jmdict_sqlite.py`, JMdict_e 219 012 entradas):

- sem `--with-kanji`: **108 797 952 bytes** (103,76 MiB), tabela `kanji` vazia
- com `--with-kanji` (13 108 linhas KANJIDIC2): **110 080 000 bytes** (104,98 MiB)
- acréscimo só da tabela `kanji`: **1 282 048 bytes** (1,22 MiB) — bake do [#88](https://github.com/murilinhoPs/MangaJP/pull/88)

JMdict_e.gz no mesmo host: 10 592 677 bytes. Detalhe do bake em [`tools/build_jmdict_sqlite/README.md`](../../tools/build_jmdict_sqlite/README.md).

**F24** no lookup: tocar num kanji **na ficha da palavra** abre a **ficha do kanji**, com on/kun, significados e traços. Sem flashcard de kanji.

A ficha abre no navigator raiz (`useRootNavigator`), para o scrim cobrir a barra da página (Editar / título / +). **Salvar kanji** fica fixo embaixo; on, kun, significados e traços rolam acima. No wide a ficha usa 45% da altura (phone continua em 50%), para os significados caberem em contraste cheio acima do fade e os traços ficarem abaixo da dobra em 1280×800. Quando há mais conteúdo abaixo, uma sombra/fade na borda do scroll indica que dá para rolar.

Se o caractere não tem linha na tabela `kanji` (bake sem `--with-kanji`, ou kanji fora do KANJIDIC2): a ficha ainda abre; on/kun, significados e traços do KANJIDIC2 ficam omitidos (a ficha **não** mostra «sem dados do dicionário»); **Salvar kanji** continua disponível. Na aba Kanji e no detalhe `/notebook/kanji/:char` o mesmo caso mostra «sem dados do dicionário». Teste com o fixture da tool sem linhas de kanji.

### Ação Salvar kanji (F45)

Na ficha do kanji, botão **Salvar kanji**, no mesmo padrão do **Salvar** de palavras. A ação grava em `saved_kanji` e **não** cria flashcard, **não** altera `word_states` e **não** cria `words`. O atalho de teclado **S** existe nos dois layouts; o hint «S» no botão **só** aparece no layout largo (largura ≥ 900, `ShellLayout.isWide`).

Salvar o mesmo `literal` de novo é no-op. A identidade é o `literal` normalizado (abaixo). Não rebaixa e não duplica a linha.

### Modelo `saved_kanji`

Tabela Drift própria, com migração, distinta de `word_states` e de `words`. Palavra salva e kanji salvo são listas diferentes no Caderno. Não há card `kind = kanji` nesta entrega (F38 sai do Won't: milestone próprio entre M2 e M3, proposta em revisão). Sem `user_note` no kanji (F45; Caderno de palavras também não edita nota).

Colunas:

| Coluna | Regra |
| --- | --- |
| `literal` | `TEXT` PK, já normalizado (único). Normalizar **antes de salvar e de comparar**: remover seletores de variação IVS U+E0100–U+E01EF e VS1–VS16 U+FE00–U+FE0F (o mesmo recorte de `stripVariationSelectors` em [`lib/core/utils/graphemes.dart`](../../lib/core/utils/graphemes.dart)). |
| `saved_at` | `DATETIME NOT NULL`. Data em que foi salvo. Um segundo save do mesmo `literal` **não** altera `saved_at` nem `origin_page_id`. |
| `origin_page_id` | `TEXT NULL REFERENCES pages(id) ON DELETE SET NULL`. Página de origem, opcional. Apagar a página **não** apaga o kanji: `origin_page_id` vira `null`. |

Índice em `saved_at`. `schemaVersion` Drift **9** (`saved_kanji`), migração 8 → 9.

O mesmo kanji com e sem IVS/VS colapsa no `literal` sem seletor. `叱` (U+53F1) e `𠮟` (U+20B9F) **continuam distintas**: o strip não as normaliza uma na outra, e cada uma é a sua própria linha em `saved_kanji`. A rota `/notebook/kanji/:char` usa esse `literal`. O `literal` é rejeitado se não sobrar exatamente 1 code point depois do strip. A consulta em `kanji.character` e o parâmetro da rota também passam pelo strip.

### Aba Kanji no Caderno (F45)

O Caderno ganha a aba **Kanji** ao lado da lista de palavras. Lista: mais recentes primeiro (`saved_at`). Busca por kanji, leitura ou significado. **Sem filtros** nesta entrega. Leitura e significado vêm da tabela `kanji` em `jmdict.sqlite`; com a tabela vazia, a busca só acha pelo literal.

Cada linha / o detalhe `/notebook/kanji/:char` mostra: kanji grande, leituras **on** e **kun**, significados, número de traços, e as **palavras do Caderno** que usam aquele `literal`. A **lista** da aba Kanji filtra por `lemma` (`stripVariationSelectors(word.lemma)`). O **detalhe** filtra por `lemma_key` (`LIKE`). Sem linha na tabela `kanji`, a lista e o detalhe mostram «sem dados do dicionário» no lugar de on/kun, significados e traços. Somente leitura (Caderno = consulta). Sem nota e sem Aprender.

Estados vazios no mesmo padrão das palavras, copy adaptado:

- Lista sem kanji: «Nenhum kanji.» / «Salve um kanji na ficha da palavra para vê-lo aqui.»
- Busca sem resultado: «Nenhum resultado.» / «Tente outro kanji, leitura ou significado.»

**Remover do Caderno** no mesmo padrão das palavras: confirmação; apaga a row em `saved_kanji`. Sem card, então sem o ramo de confirmação dupla de card. Nada some sem essa ação.

A lista de **palavras** continua F41–F44: busca por palavra/leitura/nota, filtro por estado, NF11.

Follow-up [#91](https://github.com/murilinhoPs/MangaJP/issues/91): no layout largo a ficha pinna **Salvar kanji**, rola o conteúdo com fade na borda, e abre no navigator raiz para o scrim cobrir Editar / +.

### Fora de escopo

- Flashcards de kanji e SRS de kanji nesta entrega (F45 «fora do SRS»). F38 sai do Won't: milestone próprio entre M2 e M3 — [`roadmap.md`](../roadmap.md).
- Nota no kanji salvo (F45).
- Edição de texto no detalhe.
- Filtros na aba Kanji (esta entrega).
- Export do Caderno (F46 Could).
- Tokenização (F34 Could) e polish extra de UI do KANJIDIC2 (M3 no recorte antigo da PRD).

## Critérios de aceite

- **AC-kanjidic:** tocar um kanji na ficha da palavra abre a ficha do kanji com on/kun, significados e traços a partir da tabela `kanji` do `jmdict.sqlite` (F24).
- **AC-kanji-miss:** sem linha na tabela `kanji`, a ficha abre, os campos do KANJIDIC2 ficam omitidos e **Salvar kanji** continua disponível. Na aba Kanji e em `/notebook/kanji/:char` aparece «sem dados do dicionário».
- **AC-kanji-save:** **Salvar kanji** na ficha grava `saved_kanji` (`literal` normalizado, `saved_at`, `origin_page_id` nullable) e não cria card, não mexe em `word_states` / `words`. Salvar o mesmo `literal` (já sem IVS/VS) de novo é no-op.
- **AC-kanji-tab:** o Caderno tem a aba **Kanji**; lista mais recentes primeiro, busca por kanji/leitura/significado, sem filtros; detalhe `/notebook/kanji/:char` mostra kanji grande, on, kun, significados, traços e as palavras do Caderno que usam aquele literal; somente leitura, sem nota e sem Aprender.
- **AC-kanji-empty:** lista vazia e busca sem resultado usam o copy acima, no mesmo padrão das palavras.
- **AC-kanji-remove:** **Remover do Caderno** apaga a row em `saved_kanji` após confirmação.
- **AC-kanji-no-srs:** kanji salvo não entra na fila de revisão e não cria `kind = kanji`.
- **AC-kanjidic-attr:** Sobre / Fontes mostra «KANJIDIC2 © EDRDG, CC BY-SA 4.0» com link para https://www.edrdg.org/wiki/index.php/KANJIDIC_Project.

## Como verificar

- Teste de domínio / Drift: migração cria `saved_kanji`; insert; segundo save do mesmo `literal` (com e sem IVS/VS) não duplica; nenhum row em `cards` / `card_srs` / `word_states`; strip bate com `stripVariationSelectors`.
- Teste de widget **phone (390×844) e wide (≥900)**: aba Kanji, detalhe `/notebook/kanji/:char`, ficha com **Salvar kanji**, estados vazios, Remover. Lookup com dados da tabela `kanji` (fixture do `tools/build_jmdict_sqlite/testdata`) e o caso sem linhas de kanji. Com a ficha aberta: significados alcançáveis (sem overlap com o botão fixo); toque em Editar / + não dispara a barra da página.
- Prints conforme [`print-rules.md`](../qa/print-rules.md): **390×844** (emulador ou janela Linux, pasta `android/`) e Linux **1280×800** só a área do app, no `pr-assets`, `print_sizes.txt` no head final. Widget/golden sozinho não conta. macOS / iOS: ou print, ou `n/a: Mac offline (#54)`. Sobre / Fontes: print com a atribuição KANJIDIC2 (AC-kanjidic-attr).
- `integration_test`: saída real no head final, ou `n/a` com motivo.
- F24 e F45 saíram juntos no [#88](https://github.com/murilinhoPs/MangaJP/pull/88) (fecha [#58](https://github.com/murilinhoPs/MangaJP/issues/58)). Follow-up [#91](https://github.com/murilinhoPs/MangaJP/issues/91): ficha no wide com rolagem, fade e scrim sobre a barra.
