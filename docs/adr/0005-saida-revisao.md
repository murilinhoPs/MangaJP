# ADR-0005 — Saída da revisão

- Status: Aceita
- Data: 2026-10-14
- Questão: F17 (Review exit / PopScope)

## Contexto

Swipe da borda (iOS) e back (Android) popam a rota. Sair de `/review` no meio da sessão perde o contexto da fila. «Continuar lendo» na Home não pode herdar esse guard — é Leitor, não Review (#46 / M1.29).

## Decisão

- Saída explícita da sessão = botão **Fechar**.
- A sessão **não** sai direto por swipe da borda nem pelo back.
- Swipe / back passam pelo `PopScope`:
  - se **≥1 card foi respondido** na sessão → confirmação **«Sair da revisão?»**;
  - se **nenhum** card foi respondido → sai direto.
- O card **Continuar lendo** na Home **só** abre o Leitor (`/pages/:id`), com swipe-back normal.

M2.1: teste de widget PopScope cobre também a Review.

## Consequências

- Spec: [revisao](../specs/revisao.md). Home: [home](../specs/home.md).
- Leitor e detalhe do Caderno não usam o diálogo da Review.
- Mudar Fechar (se pede o mesmo diálogo com ≥1 resposta) exige fechar o Pendente na spec ou ADR novo.
