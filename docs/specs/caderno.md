# Palavras / Caderno

Rotas: `/notebook`, `/notebook/word/:id`. Kanji (`/notebook/kanji/:char`, aba Kanji) — [kanji](kanji.md). Nav: Caderno. Deck é outra tela — [flashcards](flashcards.md) (Q-N6).

## Objetivo

Toda ação explícita grava a palavra no Caderno, com ou sem flashcard. Nada some sem **Remover do Caderno**. Somente consulta (sem edição de texto/notas).

## Comportamento

**Estados (F10):** `saved` | `learning` | `known` | `ignored`. Sem row = `unknown` (não persistir `unknown`). `first_saved_at` + `first_seen_crop_id`. Índice `(state, first_saved_at)`.

**Ações na sheet (F12 / F42):**

| Ação | `word_states` | Flashcard |
| --- | --- | --- |
| Abrir lookup sem ação | nada | — |
| **Salvar** | `saved`; se já há estado, **não muda** (nunca rebaixa) | inalterado |
| **Aprendendo** | `learning` | cria `phase = new` ou reativa (`suspend_reason = null`) **sem** reset SRS |
| **Conhecido** | `known` | card ativo → `suspend_reason = 'known'` |
| **Ignorar** | `ignored` | card ativo → `suspend_reason = 'ignored'` |
| Deletar card | volta a `saved` | hard delete CASCADE (SRS + logs). Palavra e nota ficam |
| **Remover do Caderno** | delete `words` (CASCADE) → `unknown` | confirmação dupla se houver card |

Qualquer ação na sheet faz upsert em `words` + ocorrência em `crop_words`. Frase do Caderno = `ocr_text` do recorte da primeira ocorrência.

**Lista (F41):** todas as palavras com `word_state`, mais recentes primeiro (`first_saved_at`). Busca por palavra, leitura e nota. Filtros por estado e por tag. Mostra frase e página de origem. NF11: abrir/buscar/filtrar 5.000 palavras < 100 ms.

**Tags (Q-N7):** slug de `pages.title` sem sufixo de capítulo (`Silent Hill f #4-1` → `silent-hill-f`). Calculada na consulta; sem edição manual; página sem título não gera tag. Filtro **não** usa `flashcards.tags_json`.

**F43:** exibe `user_note` (custom) e contexto; sem edição de texto.

**F44:** detalhe — entrada completa, frase do balão, miniatura do recorte + link da página, nota, estado. Ações: mudar estado, **Aprender** (cria card), remover do Caderno.

**F45 Should / M2:** spec em [kanji](kanji.md). Salvar kanji (`saved_kanji`); aba Kanji (leituras, significados, traços). Sem nota. Sem card.

**F46 Could:** export Markdown ou CSV.

## Critérios de aceite

- **AC-save:** Salvar grava `words` + `word_states = saved` + `crop_words`, sem card; salvar de novo é no-op e nunca rebaixa.
- **AC-notebook:** lista toda palavra com estado, mais recentes primeiro; busca e filtro por estado < 100 ms com 5.000 palavras.
- **AC-note:** `user_note` custom no detalhe e no verso do card; sem edição no Caderno.
- **AC-promote:** Aprender a partir do Caderno cria o card sem duplicar.
- **AC-remove:** remover do Caderno apaga palavra, ocorrências e card, após confirmação.
- **AC-known:** Conhecido grava `suspend_reason = 'known'` e tira o card da fila; a palavra continua no Caderno.
- **AC-delete:** deletar card remove card, SRS e logs; a palavra volta a `saved` e continua no Caderno. Confirmação na UI.

> Pendente: copy dos diálogos de Remover card / Remover do Caderno.
