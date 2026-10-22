# ADRs

Uma decisão por arquivo. ADR aceito é imutável: para reverter, ADR novo + status `Superada` no antigo. Nunca editar a decisão em silêncio.

## Índice

| ID | Título | Questão | Status | Data |
| --- | --- | --- | --- | --- |
| [ADR-0001](0001-ocr-default-manga-ocr.md) | OCR default = manga-ocr | Q-B1 | Aceita | 2026-10-04 |
| [ADR-0002](0002-licenca-gpl-yomitan.md) | GPL + transforms Yomitan | Q-B3 | Aceita | 2026-10-02 |
| [ADR-0003](0003-ios-plataforma-secundaria.md) | iOS secundário na M2.1 | Q-N1 | Aceita | 2026-10-12 |
| [ADR-0004](0004-nav-design-system.md) | Nav do Design System | Q-N8 | Aceita | 2026-10-08 |
| [ADR-0005](0005-saida-revisao.md) | Saída da revisão | F17 | Aceita | 2026-10-14 |

Outras decisões fechadas no PRD (Q-B2 imagens, Q-N2 gloss EN, Q-N5 furigana, Q-N6 Deck×Caderno, Q-N7 tags) ainda não têm ADR — estão nas [specs](../README.md#specs).

## Template

Copiar para `NNNN-titulo-curto.md`. Próximo número livre: **0006**.

```markdown
# ADR-NNNN — Título

- Status: Proposta | Aceita | Superada | Revertida
- Data: YYYY-MM-DD
- Questão: Q-XX (se houver)

## Contexto

Por que a decisão existe. Opções em jogo. Sem inventar números.

## Decisão

O que vale. Imperativo.

## Consequências

O que passa a ser verdade no código, na spec e no review.
```

Status `Superada`: apontar o ADR que substitui. Specs ligadas atualizam no mesmo PR.
