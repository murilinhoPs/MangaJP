# Flashcards

Rota: `/deck` (nav card **Deck**). SRS e sessão: [revisao](revisao.md). Palavra no Caderno: [caderno](caderno.md).

## Objetivo

No máximo 1 card vocab por `word_id`. Template derivado. Deck ≠ Caderno (Q-N6): Deck = flashcards e SRS; Caderno = consulta.

## Comportamento

- **F11:** CRUD vocab. `kind = vocab`. `UNIQUE(word_id, kind)`.
- Frente = `dict_form` (kanji/lemma; se só kana, kana). Verso = `reading` · até 3 glosses EN · `user_note` · `context_sentence` (tipo menor). Sem colunas `front`/`back`.
- **F30 Could:** toggle «mostrar reading na frente» (default off) — [settings](settings.md).
- Criação: ação **Aprendendo** / **Aprender**. Segundo Aprendendo no mesmo `word_id` não duplica; reativa ou no-op **sem** reset SRS (AC-card).
- **F23 Should:** suspender no Deck → `suspend_reason = 'user'`; reativar → `null` e `word_states = learning`. Não deleta card, SRS nem logs. Suspender **não** muda `word_states`, só a razão. Sem migração Drift: `cards.suspend_reason` já existe no schema 9; F23 só passa a gravar `'user'`. Ação na lista do Deck (botão **Suspender** / **Reativar**); confirmação só para suspender. Lista (`listDeck`): todo card vocab, mais recentes primeiro; cards suspensos permanecem. API: `listDeck`, `suspendByUser`, `reactivate`; domínio: `isEligibleForReview`, `applyUserSuspend`, `applyReactivate`. Badge **Suspenso** tem prioridade sobre o estado do Caderno.
- Deletar card: confirmação; CASCADE `card_srs` + `review_logs`; palavra → `saved` (AC-delete).
- **F38:** flashcards `kind = kanji` saem do Won't. Milestone [M2b](../roadmap.md#m2b--kanji-no-srs) entre M2 e M3; proposta em revisão, sem implementação nesta spec. Cards a partir de `saved_kanji`.
- IA: lista + filtros + suspender.

## Critérios de aceite

- **AC-card:** Aprendendo cria 1 card; segundo Aprendendo no mesmo `word_id` não duplica (reativa ou no-op sem reset SRS).
- **AC-known:** Conhecido suspende (`known`) e tira da fila; palavra no Caderno.
- **AC-delete:** delete card CASCADE; palavra `saved`; confirmação explícita.
- Suspender/reativar (F23) não apaga logs nem SRS.

> Pendente: filtros da lista do Deck (quais; persistência).
> Pendente: copy da confirmação de delete.
>
> F23 (M2.6): ação na lista do `/deck`. Card ativo → **Suspender** (diálogo «Suspender este card?», corpo «O card sai da fila de revisão e permanece no Deck. O progresso SRS é mantido.», botões **Cancelar** e **Suspender**). Card com `suspend_reason = 'user'` → badge **Suspenso** (prioridade sobre o estado do Caderno) e **Reativar** (sem diálogo extra). Known / ignored continuam no Deck com o estado do Caderno, sem os botões F23. Empty: «Nenhum card.» / «Aprenda uma palavra no Caderno para vê-la aqui.» / marca d'água `札`. Residual conhecido (critique do #112, não bloqueia, follow-up pendente): pela API pública, `reactivate` também limpa `known`/`ignored` e `suspendByUser` sobrescreve um card `known`/`ignored`; a UI impede os dois. — ver [`m2.md`](../milestones/m2.md) Q5.
