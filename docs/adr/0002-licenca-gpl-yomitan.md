# ADR-0002 — GPL + transforms Yomitan

- Status: Aceita
- Data: 2026-10-02
- Questão: Q-B3

## Contexto

Lookup de formas flexionadas precisa de deinflexão. Yomitan publica transforms sob GPL. Sem porta dessas regras, o app teria deinflect próprio (risco de qualidade) ou rewrite para evitar a licença.

## Decisão

O app **pode** portar/usar as transforms de deinflexão Yomitan. O app fica sob **GPL**. Sem rewrite e sem deinflect custom-only por motivo de licença.

## Consequências

- `lib/core/deinflect/` é porta Dart das regras Yomitan. Licença do repo: GPL-3.0.
- Filtro `sense_pos` e badge «sem filtro POS» são produto, não desculpa para não portar.
- Atribuição Yomitan + JMdict (CC BY-SA) nos [Ajustes](../specs/settings.md) (NF8).
- Trocar deinflect ou a licença do app exige ADR novo.
