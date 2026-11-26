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
- No confirm, `sha256` de dedupe sai dos **bytes recebidos** (antes da conversão). A imagem é gravada em `{documents}/pages/{pageId}.png` (`path_provider` / `getApplicationDocumentsDirectory`): JPEG/WebP são decodificados, `bakeOrientation` aplica o EXIF, e o resultado vai em PNG (`encodePagePng` / `encodePagePngOffUi`). PNG de entrada volta os **mesmos** bytes, nesta isolate, sem `compute` (screenshot sem re-encode). JPEG/WebP rodam fora da UI via `compute` / isolate (`offUiCompute`). Os crops do confirm partem desses bytes já convertidos (`cropAllToPngOffUi`): um decode + `bakeOrientation` para todos os retângulos, noutro `compute` (lista vazia não spawna). `cropToPng` faz o mesmo bake num recorte só. O caminho entra em `pages.image_path` (só preenche se ainda for null — páginas antigas ficam null). Web: o save devolve `null`. Boxes do motor (quando houver `Rect`) vão em `crops.ocr_blocks_json` via `OcrBlocksJson.fromResult` com o tamanho do PNG do crop (`cropToPng` / `encodePng`) — [ocr](ocr.md), [leitor](leitor.md).
- Tela de tarefa: esconde os nav cards; dock próprio (F17 / [ADR-0004](../adr/0004-nav-design-system.md)).
- Sair (Esc, X do dock, back Android): confirmação **só** se a pessoa editou algum recorte (criou, moveu ou apagou). O recorte inicial automático **não** conta como edição.

**F28 Could:** captura via câmera (`image_picker`).

## Critérios de aceite

- **AC-share:** share de screenshot abre `/capture` com a imagem (sem Home).
- **AC-taps:** share → confirm crop → texto OCR ≤ 2 taps in-app (drag/pinch não contam).
- **AC-crop:** ≥1 crop antes do OCR — detalhe em [recorte](recorte.md).
- **AC-dedupe:** mesma imagem (mesmo sha dos bytes recebidos) reabre a página existente + aviso; novos crops permitidos — [recorte](recorte.md).
- JPEG/WebP da galeria/share: o confirm grava PNG (`encodePagePng`); `/pages/:id` mostra o overlay como nas entradas que já eram PNG — [leitor](leitor.md).

> Pendente: copy exato do diálogo ao sair com recorte editado.
> Pendente: share no iOS é Must na M1 ou só na M2.1 (Q-N1 / F2 é Android).
> Pendente (follow-up de código): `offUiCompute` detecta testes pela chave interna `#test.declarer` do pacote `test`; no `flutter test` o trabalho roda num evento posterior da mesma isolate. O caminho `compute` / `Isolate.run` de produção só é exercitado no QA.
