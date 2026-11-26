# OCR

Motor pluggable (`OcrEngine`). Default e bake-off: [ADR-0001](../adr/0001-ocr-default-manga-ocr.md). Protocolo e tabelas: [`m0.3-cer-bakeoff.md`](../m0.3-cer-bakeoff.md).

## Objetivo

Ler japonês de crops de balão o bastante para lookup, sem ML Kit no app.

## Comportamento

- **F4:** `OcrEngine.recognize`; default **manga-ocr** (serviço local). ML Kit **não entra** no app.
- OCR roda **automaticamente** depois do confirm dos crops ([captura](captura.md)).
- **F5:** texto OCR **editável por crop** + lista de termos. Persistido em `crops.ocr_text` / `ocr_raw_json`.
- Contrato: `fullText`, `blocks` (text, confidence, `Rect?`), `engineId`.
- **F26 Should:** Cloud Vision opcional — spec em [cloud-vision](cloud-vision.md). `DOCUMENT_TEXT_DETECTION`, `languageHints: ["ja"]`. Só com toggle «Usar OCR na nuvem». Chave não embutida. Não é o default. Roda no mesmo crop que o manga-ocr (1 chamada por crop).
- Filtro de ruby do Vision (CER 21,32%) é **unofficial** e não é default.
- **F27 Should:** filtrar furigana por altura relativa **se** o engine der boxes. Não usar como reading automática (Q-N5).
- **F22 Should:** overlay de bounding boxes sobre a imagem da página — UI, toggle e lookup em [leitor](leitor.md). Sem `Rect` (manga-ocr), a box é o retângulo do crop. Com `Rect` (Cloud Vision), as boxes vão em `crops.ocr_blocks_json`. Toggle `reader.ocrOverlay` (default on). Dashed **só** com confidence < 0.5 (omitido → sólido). Fallback crop-rect usa os mesmos tokens/estados; não tem estilo próprio.
- **F22 — schema Drift 9→10.** `addColumn` de `pages.image_path` (nullable) e `crops.ocr_blocks_json` (nullable); `app_meta.schema_version` = `'10'`. Linhas antigas sobrevivem com null. O [#120](https://github.com/murilinhoPs/MangaJP/pull/120) (JPEG/WebP→PNG no confirm + magic bytes no leitor) **não** migra: schema permanece **10**. Imagem da página: [captura](captura.md), [leitor](leitor.md).
- **F22 — JSON em `crops.ocr_blocks_json`.** Array de objetos. Coordenadas **normalizadas no crop** (0..1), não na página e não em pixels. Pixel `Rect` do Vision é dividido pelo tamanho do PNG do crop na persistência (`OcrBlocksJson.fromResult`). `normalizedVertices` passam com `OcrBlock.normalized == true` — **nunca** se infere o espaço de `abs(valor) <= 1` (1 px também divide). O objeto grava `"space": "crop"` quando há Rect. `encode` devolve `null` se nenhum bloco tem Rect (manga-ocr). Coluna `null` ou `[]` = engine não deu boxes.

Formato (`OcrBlocksJson`):

```json
[
  {
    "text": "食べた",
    "confidence": 0.92,
    "space": "crop",
    "left": 0.10,
    "top": 0.20,
    "width": 0.80,
    "height": 0.40
  }
]
```

Campos: `text` (string, obrigatório; vazio é mantido e a overlay ainda desenha); `confidence` (number, opcional; < 0.5 → dashed; omitido → sólido); `space` sempre `"crop"` quando há Rect (ausente em rows antigas ainda é crop 0..1; valor diferente descarta o Rect); `left` / `top` / `width` / `height` (os quatro finitos). Bloco sem Rect é ignorado no mapeamento; se nenhum bloco do crop tem Rect, a overlay usa o retângulo salvo do crop. No overlay, Rect de engine vira coordenada de **página**: `crop.left + block.left * crop.width` (idem top/width/height). Hit target mínimo 44 px; badge 1-based.

- **F29 Could:** mokuro / ONNX / PP-OCR via serviço local. manga-ocr em si é Must, não Could.
- NF2: p50 < 5 s, p95 < 15 s (página ~2 MP / crop típico).
- NF6: imagens não sobem à cloud salvo o toggle Cloud OCR (só o recorte; ver [cloud-vision](cloud-vision.md)).
- Offline: manga-ocr = serviço local; texto cacheado em `crops.ocr_*`. Cloud exige rede.

## Critérios de aceite

- Default do app = manga-ocr (ADR-0001). Nenhum caminho de produto chama ML Kit.
- Confirm crop → OCR auto → `ocr_text` visível e editável em `/pages/:id` ([leitor](leitor.md)).
- F22: schema 10; `ocr_blocks_json` com `"space": "crop"` quando há Rect; manga-ocr deixa a coluna null e a overlay usa o retângulo do crop.
- Cloud Vision só existe atrás do toggle (F26), quando implementado — [cloud-vision](cloud-vision.md).

> Pendente: UX do editor de `ocr_text` (inline, sheet, teclado).
> Pendente: Q-N3 — orçamento Cloud Vision (USD/mês); ver [cloud-vision](cloud-vision.md).
> Pendente: limiar numérico da altura no filtro de furigana (Q-N5).
