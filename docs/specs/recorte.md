# Recorte (crop)

Tela: `/capture`. Imagens: PRD §9.4 (Q-B2 fechada). Ligado a [captura](captura.md) e [ocr](ocr.md).

## Objetivo

Um ou mais retângulos de balão, recortados do original, antes de qualquer OCR.

## Comportamento

- **F3:** ≥1 retângulo obrigatório antes do OCR. Multi-crop → N rows em `crops`.
- Recortes numerados em ordem **RTL**.
- Dois recortes com a **mesma geometria** na mesma página = um só: retry de OCR reaproveita o recorte, não duplica.
- Recorte inicial automático **não** conta como edição. Criar, mover ou apagar conta. Sair da Captura só pede confirmação se houve edição.
- Crop PNG a partir da imagem de página salva. Sem downscale extra do crop.

**Imagens (Q-B2):**

| Artefato | Política |
| --- | --- |
| Página (`pages.image_path`) | Bytes recebidos. Exceção: lado mais longo > **3000 px** → esse lado a 3000 px (JPEG q~90); hash/salva o resultado. |
| Thumbnail (`pages.thumb_path`) | JPEG ~**400 px** no lado longo, q~75. |
| Crop (`crops.image_path`) | PNG do recorte (do original ou já reduzido pela exceção 3000 px). |

F22 (schema 10, na `main`): o confirm grava a **PNG da página** em `{documents}/pages/{pageId}.png` (`path_provider`) **sem** a redução 3000 px desta tabela — JPEG/WebP passam por `encodePagePng` (`bakeOrientation` + `encodePng`); PNG de entrada não é re-encodado. O leitor do overlay usa magic bytes, então arquivos antigos JPEG/WebP com extensão `.png` ainda ligam a overlay — [captura](captura.md), [leitor](leitor.md). `crops.image_path` e `pages.thumb_path` continuam pendentes.

Não downscalear screenshot de telefone com lado longo ≤ ~2400 px.

**Dedupe:** `image_sha256 = sha256(bytes recebidos)` (ou pós-redução 3000 px). `UNIQUE`.

Em colisão: não cria segunda `pages`; abre a existente; permite novos crops; aviso «Página já importada — adicionando recortes.»

## Critérios de aceite

- **AC-crop:** ≥1 crop obrigatório antes do OCR; multi-crop grava N rows em `crops`.
- **AC-dedupe:** reimportar a mesma imagem reabre a página + aviso; novos crops ok.
- Geometria igual na mesma página não duplica row; retry reusa o recorte.
- Numeração RTL.
- Sair sem edição (só o recorte inicial) não pede confirmação; sair depois de criar/mover/apagar pede.

> Pendente: copy exato do diálogo de descarte / sair com edição.
> Pendente: o recorte inicial automático — tamanho, posição, um vs. vários.
