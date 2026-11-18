# Captura

Rota: `/capture`. Não é tab. Specs ligadas: [recorte](recorte.md), [ocr](ocr.md), [galeria](galeria.md).

## Objetivo

Entrar no pipeline com uma imagem e chegar em texto OCR com ≤ 2 taps in-app (O4 / NF10).

## Comportamento

- **F2 / AC-share:** share de screenshot no Android abre `/capture` com a imagem, **sem** passar pela Home.
- **F1:** seleção via galeria (`image_picker`) — ver [galeria](galeria.md).
- Crop obrigatório (≥1 retângulo) antes do OCR — [recorte](recorte.md).
- 1 tap **Confirmar crop(s)** dispara OCR automático. Drag/pinch **não** contam como tap. O share sheet do sistema não conta.
- Galeria (tile / **Galeria +**): pick do sistema + confirm crop ≤ 2 taps in-app.
- Pós-OCR: navega para `/pages/:id` ([leitor](leitor.md)).
- No confirm, os **bytes recebidos** vão para `{documents}/pages/{pageId}.png` (`path_provider` / `getApplicationDocumentsDirectory`) — hoje gravados como `.png`, **sem** recodificar. O caminho entra em `pages.image_path` (só preenche se ainda for null — páginas antigas ficam null). Web: o save devolve `null`. Boxes do motor (quando houver `Rect`) vão em `crops.ocr_blocks_json` via `OcrBlocksJson.fromResult` com o tamanho do PNG do crop (`cropToPng` / `encodePng`) — [ocr](ocr.md), [leitor](leitor.md).
- Tela de tarefa: esconde os nav cards; dock próprio (F17 / [ADR-0004](../adr/0004-nav-design-system.md)).
- Sair (Esc, X do dock, back Android): confirmação **só** se a pessoa editou algum recorte (criou, moveu ou apagou). O recorte inicial automático **não** conta como edição.

**F28 Could:** captura via câmera (`image_picker`).

## Critérios de aceite

- **AC-share:** share de screenshot abre `/capture` com a imagem (sem Home).
- **AC-taps:** share → confirm crop → texto OCR ≤ 2 taps in-app (drag/pinch não contam).
- **AC-crop:** ≥1 crop antes do OCR — detalhe em [recorte](recorte.md).
- **AC-dedupe:** mesma imagem (mesmo sha dos bytes recebidos) reabre a página existente + aviso; novos crops permitidos — [recorte](recorte.md).

> Pendente: copy exato do diálogo ao sair com recorte editado.
> Pendente: share no iOS é Must na M1 ou só na M2.1 (Q-N1 / F2 é Android).
> Pendente (follow-up de código, F22): o confirm grava os bytes crus com extensão `.png`. JPEG/WebP da galeria ou do share falham o IHDR (`pageImagePixelSize`) e `/pages/:id` cai nos cards de texto como path órfão. Overlay só aparece com entrada PNG (screenshot). Normalizar (`encodePng` do `decoded` já existente) ou gravar com a extensão e o leitor de tamanho certos para cada formato; falta teste com entrada JPEG.
