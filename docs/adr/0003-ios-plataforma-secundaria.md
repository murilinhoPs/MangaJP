# ADR-0003 — iOS secundário na M2.1

- Status: Aceita
- Data: 2026-10-12
- Questão: Q-N1

## Contexto

MVP é Android-first. iOS no M1 atrasaria o loop de estudo. Murilo fecha Q-N1 em 2026-10-12: iOS fora da M1. Em 2026-10-13: prints iOS no simulador iPhone 17, qualquer resolução — detalhe em [`print-rules`](../qa/print-rules.md).

## Decisão

iOS entra como **plataforma secundária na M2.1**, logo após a M1 (F40, NF7). Android first.

Prints de iOS: fonte [`docs/qa/print-rules.md`](../qa/print-rules.md) (simulador **iPhone 17**, qualquer resolução). Os obrigatórios continuam Android 390×844 retrato e Linux desktop 1280×800.

M2.1: Mac do Murilo como worker Cursor; teste de widget do gesto de voltar (PopScope) em Captura e Review; PRs com código de plataforma declaram o comportamento no iOS. Até a M1 fechar, telas e prints continuam no Linux/Android.

Sideload / debug OK. App Store pública é não-objetivo da v1.

## Consequências

- M1 não bloqueia em job iOS no CI Linux.
- Specs de captura/share: F2 é Android Must. PR com código de plataforma declara o comportamento no iOS (F40).
- Prints: [print-rules](../qa/print-rules.md) é a fonte. Não repetir a regra de simulador neste ADR.
