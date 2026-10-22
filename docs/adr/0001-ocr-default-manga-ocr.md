# ADR-0001 — OCR default = manga-ocr

- Status: Aceita
- Data: 2026-10-04
- Questão: Q-B1

## Contexto

M0 exigia bake-off CER no GT kanji (44 crops, 530 chars) entre ML Kit, Cloud Vision e manga-ocr. Alvo de go: alguma engine ≤ 10% **ou** documentar a melhor + plano. Números no PRD v1.3 (mesmo protocolo em [`m0.3-cer-bakeoff.md`](../m0.3-cer-bakeoff.md)):

| Engine | CER (GT kanji) |
| --- | --- |
| manga-ocr | **20,75%** (110/530; 25/44) |
| Cloud Vision | **44,53%** |
| ML Kit | **95,47%** |

Nenhuma ≤ 10%. Filtro de ruby do Vision (**21,32%**) é unofficial. O bake-off registrou a medição e um default de trabalho; o PRD fecha Q-B1 escolhendo o melhor CER medido + plano.

## Decisão

Default oficial = **manga-ocr** (serviço local). ML Kit não entra no app. Cloud Vision é plano de melhoria (F26, Should/M2) ou um motor posterior — não é o default. O filtro de ruby do Vision não é default.

## Consequências

- `OcrEngine` default = manga-ocr. Spec: [ocr](../specs/ocr.md).
- Sem `google_mlkit_*` no produto.
- Q-B1 deixa de bloquear M1.
- Melhoria futura = F26 ou motor novo, com ADR se o default mudar.
