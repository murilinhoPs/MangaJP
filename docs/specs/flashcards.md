# Flashcards

Rota: `/deck` (nav card **Deck**). SRS e sessão: [revisao](revisao.md). Palavra no Caderno: [caderno](caderno.md).

## Objetivo

No máximo 1 card vocab por `word_id`. Template derivado. Deck ≠ Caderno (Q-N6): Deck = flashcards e SRS; Caderno = consulta.

## Comportamento

- **F11:** CRUD vocab. `kind = vocab`. `UNIQUE(word_id, kind)`.
- Frente = `dict_form` (kanji/lemma; se só kana, kana). Verso = `reading` · até 3 glosses EN · `user_note` · `context_sentence` (tipo menor). Sem colunas `front`/`back`.
- **F30 Could:** toggle «mostrar reading na frente» (default off) — [settings](settings.md).
- Criação: ação **Aprendendo** / **Aprender**. Segundo Aprendendo no mesmo `word_id` não duplica; reativa ou no-op **sem** reset SRS (AC-card).
- **F23 Should:** suspender no Deck → `suspend_reason = 'user'`; reativar → `null` e `word_states = learning`. Não deleta card, SRS nem logs.
- Deletar card: confirmação; CASCADE `card_srs` + `review_logs`; palavra → `saved` (AC-delete).
- **F38:** flashcards `kind = kanji` saem do Won't. Milestone próprio entre M2 e M3 ([`roadmap.md`](../roadmap.md)); proposta em revisão, sem implementação nesta spec. Cards a partir de `saved_kanji`.
- IA: lista + filtros + suspender.

## Critérios de aceite

- **AC-card:** Aprendendo cria 1 card; segundo Aprendendo no mesmo `word_id` não duplica (reativa ou no-op sem reset SRS).
- **AC-known:** Conhecido suspende (`known`) e tira da fila; palavra no Caderno.
- **AC-delete:** delete card CASCADE; palavra `saved`; confirmação explícita.
- Suspender/reativar (F23) não apaga logs nem SRS.

> Pendente: filtros da lista do Deck (quais; persistência).
> Pendente: empty state e copy da confirmação de delete.
> Pendente: ação de suspender/reativar no Deck (F23 / M2) — ver [`m2.md`](../milestones/m2.md).
