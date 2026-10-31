# Kanji / Caderno

Rotas: `/notebook` (aba Kanji), `/notebook/kanji/:char` (M2). Specs ligadas: [caderno](caderno.md) (F41–F44), [dicionario](dicionario.md) (lookup), [flashcards](flashcards.md) (F38 Won't). Issue: [#58](https://github.com/murilinhoPs/MangaJP/issues/58).

## Objetivo

Mostrar o kanji sozinho (leituras, significados, traços) a partir do KANJIDIC2, permitir **Salvar kanji** no Caderno e consultar a lista depois. Fora do SRS.

## Comportamento

### Fonte — KANJIDIC2 (F24)

O lookup de kanji lê a tabela `kanji` do `jmdict.sqlite` local, a mesma base read-only do JMdict (PRD: `entries` / `forms` / `sense_pos` / `kanji`). A linha traz on/kun, significados e traços.

O dado entra no app no bake: `python3 tools/build_jmdict_sqlite/build_jmdict_sqlite.py --output assets/dict/jmdict.sqlite --with-kanji`. `--with-kanji` baixa o [KANJIDIC2](http://ftp.edrdg.org/pub/Nihongo/kanjidic2.xml.gz) e preenche `kanji`. Sem a flag a tabela existe vazia, com o mesmo schema. O sqlite completo é gitignored (dezenas de MB); o app o carrega como asset. NF4: download once.

Colunas da tabela de lookup (não confundir com `saved_kanji`): `character`, `readings_json`, `meanings_json`, `stroke_count`, `freq`. Detalhe em [`tools/build_jmdict_sqlite/README.md`](../../tools/build_jmdict_sqlite/README.md).

Licença: KANJIDIC2 é © EDRDG, CC BY-SA, igual ao JMdict. Atribuição nos [Ajustes](settings.md) (NF8). O PRD não fixa o tamanho em bytes do XML nem do sqlite.

**F24** no lookup: o kanji tocado mostra on/kun, significados e traços. Sem flashcard de kanji.

### Ação Salvar kanji (F45)

A partir do lookup, um kanji tocado pode ser salvo no Caderno (dicionário: «kanji tocado pode ser salvo»). A ação grava em `saved_kanji` e **não** cria flashcard, **não** altera `word_states` e **não** cria `words`.

Salvar o mesmo caractere de novo é no-op: a rota de detalhe é `/notebook/kanji/:char`, então a identidade é o caractere. Não rebaixa e não duplica a linha.

### Modelo `saved_kanji`

Tabela própria, distinta de `word_states` e de `words`. Palavra salva e kanji salvo são listas diferentes no Caderno. Não há card `kind = kanji` (F38 Won't; futuro pós-v1 a partir de `saved_kanji`). Sem `user_note` no kanji (F45; Caderno de palavras também não edita nota).

A PRD nomeia a tabela e para aí. Colunas, `first_saved_at`, origem/crop, migration Drift e tratamento de IVS / seletor de variação ficam em Pendentes.

### Aba Kanji no Caderno (F45)

O Caderno ganha a aba **Kanji** ao lado da lista de palavras. A aba mostra leituras, significados e traços. O detalhe é somente leitura (Caderno = consulta). Rota do detalhe: `/notebook/kanji/:char`.

A lista de **palavras** continua F41–F44: busca por palavra/leitura/nota, filtro por estado, NF11. Essas regras **não** se aplicam automaticamente à aba Kanji.

### Fora de escopo

- Flashcards de kanji e qualquer SRS de kanji (PRD não-objetivo; F38 Won't; F45 «fora do SRS»).
- Nota no kanji salvo (F45).
- Edição de texto no detalhe.
- Export do Caderno (F46 Could).
- Tokenização (F34 Could) e polish extra de UI do KANJIDIC2 (M3 no recorte antigo da PRD).

## Critérios de aceite

- **AC-kanjidic:** o lookup de um kanji tocado mostra on/kun, significados e traços a partir da tabela `kanji` do `jmdict.sqlite` (F24).
- **AC-kanji-save:** **Salvar kanji** grava `saved_kanji` e não cria card, não mexe em `word_states` / `words`. Salvar o mesmo caractere de novo é no-op.
- **AC-kanji-tab:** o Caderno tem a aba **Kanji**; a lista e o detalhe `/notebook/kanji/:char` mostram leituras, significados e traços, somente leitura, sem nota e sem ação de Aprender.
- **AC-kanji-no-srs:** kanji salvo não entra na fila de revisão e não cria `kind = kanji`.

## Como verificar

- Teste de domínio / Drift: insert em `saved_kanji`; segundo save do mesmo `:char` não duplica; nenhum row em `cards` / `card_srs` / `word_states`.
- Teste de widget: aba Kanji, detalhe `/notebook/kanji/:char`, lookup com dados da tabela `kanji` (fixture do `tools/build_jmdict_sqlite/testdata`).
- Prints conforme [`print-rules.md`](../qa/print-rules.md): Android **390×844** retrato sem hover e Linux **1280×800** só a área do app, no `pr-assets`, `print_sizes.txt` no head final. Widget/golden sozinho não conta. macOS / iOS: ou print, ou `n/a: Mac offline — #54 item: <link>`.
- `integration_test`: saída real no head final, ou `n/a` com motivo.

## Pendentes (Murilo)

- **Pendente (Murilo):** ponto exato da ação no lookup (sheet do kanji, sheet da palavra, detalhe) e o copy do rótulo.
- **Pendente (Murilo):** layout da aba Kanji além de leituras, significados e traços.
- **Pendente (Murilo):** schema de `saved_kanji` (colunas, `first_saved_at`, origem/crop, unique, IVS) e a migration Drift.
- **Pendente (Murilo):** lista da aba — ordenação, busca e filtros. F41 / NF11 valem para palavras.
- **Pendente (Murilo):** estados vazios (lista sem kanji; busca sem resultado) e o copy.
- **Pendente (Murilo):** se existe **Remover** kanji do Caderno. Hoje a spec só define Remover do Caderno para palavras.
- **Pendente (Murilo):** se F24 (KANJIDIC2 no lookup) entra no mesmo PR que F45 ou em corte separado. A tabela `kanji` já existe no sqlite; nenhuma tela a usa ainda.
- **Pendente (Murilo):** tamanho em bytes do KANJIDIC2 / sqlite com `--with-kanji`. A PRD não fixa número.
