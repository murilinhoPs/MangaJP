# Dicionário

Lookup no [leitor](leitor.md) (`/pages/:id`) e na sheet. Deinflexão: [ADR-0002](../adr/0002-licenca-gpl-yomitan.md). Persistência da ação: [caderno](caderno.md).

## Objetivo

Do tap na forma da página até lemma + gloss, offline, com deinflexão e homógrafos.

## Comportamento

- Dict local `jmdict.sqlite` (read-only): `entries`, `forms`, `sense_pos`, `kanji`. Download once (NF4).
- **F6:** tap no texto + longest-prefix em `forms.text`.
- **F7:** se não houver match exato: deinflect (transforms Yomitan) filtrado por `sense_pos`. Se o filtro zerar tudo: mostra sem filtro + badge «sem filtro POS».
- **F8 / AC-homógrafo:** se `entries.length > 1`, lista. Default = maior `priority` JMdict (ichi1/news1). Sem escolha explícita → índice 0. `word_id` do card = entrada confirmada (`jm:<seq>`). Se OCR/heurística tiver kana, preferir match de reading.
- **F9:** sem entrada → «Criar entrada custom» → `custom:<uuid>`, `dict_form = surface`, gloss vazio. `user_note` **obrigatório** para criar card.
- Gloss: **EN** (JMdict) + `user_note` PT manual. Sem LLM (Q-N2).
- **F24 Should:** KANJIDIC2 no lookup (on/kun, significados, traços). Sem flashcard kanji. Kanji tocado pode ser salvo (F45 / M2) — [caderno](caderno.md).
- NF3 / AC-lookup: p95 < 100 ms com dict em disco.
- Sheet de ação: **Salvar / Aprendendo / Conhecido / Ignorar** — [caderno](caderno.md).

**F34 Could:** tokenização Kuromoji/MeCab.

## Critérios de aceite

- **AC-lookup:** toque em forma flexionada do GT resolve lemma via deinflexão em < 100 ms p95 com dict local.
- **AC-homógrafo:** >1 entrada JMdict → sheet lista; default = maior priority; card usa a entrada confirmada.
- **AC-note:** `user_note` de custom aparece no detalhe do Caderno e no verso do card; o Caderno não oferece edição.

> Pendente: copy e campos da UI «criar custom» além de `user_note` obrigatório.
> Pendente: regra exata da preferência de reading quando há kana no OCR.
