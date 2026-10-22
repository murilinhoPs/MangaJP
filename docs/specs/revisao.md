# Revisão / SM-2

Rota: `/review`. Não é tab. Entra pelo CTA **Revisar** da Home, atalho `R` ou paleta ([ADR-0004](../adr/0004-nav-design-system.md)). Saída: [ADR-0005](../adr/0005-saida-revisao.md). Motor: `lib/core/srs` (porta `sm2.clj`).

## Objetivo

Revisar vocab 100% offline com SM-2 clássico `sm2-jr@1`. Sem learning steps em minutos.

## Comportamento

- Onde este texto e `sm2.clj` divergirem → **`sm2.clj` vence**.
- **F14:** 4 botões Again / Hard / Good / Easy → `ReviewRating` → `rating` 1/2/3/4 e `quality` q 0/3/4/5 **sempre juntos** em `review_logs`. Preview de intervalos na primeira resposta do study-day (não no drill).
- Frente → **Revelar** verso → rate. Reveal não grava.
- **F15 / AC-drill:** só a **primeira** resposta do card no study-day atualiza `card_srs`. Again (q=0) ou Hard (q=3) → fim da fila da sessão. Respostas seguintes no mesmo day: `is_drill = 1`, não mutam SRS.
- Fila: learning/relearning due → review due → new até `new_per_day` (default **15**). Virada **04:00 America/Sao_Paulo** (F20).
- EF inicial 2.5; piso 1.3. `sm2.clj` atualiza EF sempre (inclui q<3); `Math/round`; intervalo usa EF' já atualizado.
- `word_state` permanece `learning` ao responder.
- Sessão termina com resumo (due restantes, novos, lapses, drills).
- **F18 / AC-offline:** review + dict já baixado funcionam em airplane mode.
- Tela de tarefa: dock próprio; esconde nav cards.

**Saída (F17):** a sessão **não** sai direto por swipe da borda (iOS) nem pelo back (Android). Saída explícita = **Fechar**. Swipe/back passam pelo `PopScope`: se **≥1 card respondido**, confirmação «Sair da revisão?»; se **nenhum**, sai direto. **Continuar lendo** na Home só abre o Leitor (swipe-back normal).

**F39 Won't:** steps 1 min / 10 min.

## Critérios de aceite

- **AC-drill:** 1ª resposta do study-day atualiza `card_srs`; Again/Hard reinserem no fim da fila; 2ª+ no mesmo day grava `is_drill = 1` sem mutar SRS.
- **AC-new-limit:** limite 15; após 15 novos no study-day (virada 4 h), a fila não oferece mais `phase = new`.
- **AC-offline:** 10 cards due, airplane mode, rate todos, kill app, reabrir → mesmos `interval_days` / `ease_factor` / `due_at` (tolerância 1 s).
- Golden tests portados de `sm2_test.clj` verdes; `engine_id = sm2-jr@1`.
- PopScope conforme ADR-0005. Widget do gesto iOS na M2.1.

> Pendente: se **Fechar** com ≥1 card respondido pede a mesma confirmação «Sair da revisão?».
> Pendente: copy e métricas exatas da tela de resumo da sessão.
