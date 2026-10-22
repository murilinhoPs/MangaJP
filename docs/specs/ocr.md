# OCR

Motor pluggable (`OcrEngine`). Default e bake-off: [ADR-0001](../adr/0001-ocr-default-manga-ocr.md). Protocolo e tabelas: [`m0.3-cer-bakeoff.md`](../m0.3-cer-bakeoff.md).

## Objetivo

Ler japonês de crops de balão o bastante para lookup, sem ML Kit no app.

## Comportamento

- **F4:** `OcrEngine.recognize`; default **manga-ocr** (serviço local). ML Kit **não entra** no app.
- OCR roda **automaticamente** depois do confirm dos crops ([captura](captura.md)).
- **F5:** texto OCR **editável por crop** + lista de termos. Persistido em `crops.ocr_text` / `ocr_raw_json`.
- Contrato: `fullText`, `blocks` (text, confidence, `Rect?`), `engineId`.
- **F26 Should:** fallback Cloud Vision (`DOCUMENT_TEXT_DETECTION`, `languageHints: ["ja"]`). Só com toggle «Usar OCR na nuvem». Chave não embutida. Não é o default.
- Filtro de ruby do Vision (CER 21,32%) é **unofficial** e não é default.
- **F27 Should:** filtrar furigana por altura relativa **se** o engine der boxes. Não usar como reading automática (Q-N5).
- **F22 Should:** overlay de bounding boxes quando o OCR fornecer.
- **F29 Could:** mokuro / ONNX / PP-OCR via serviço local. manga-ocr em si é Must, não Could.
- NF2: p50 < 5 s, p95 < 15 s (página ~2 MP / crop típico).
- NF6: imagens não sobem à cloud salvo o toggle Cloud OCR.
- Offline: manga-ocr = serviço local; texto cacheado em `crops.ocr_*`. Cloud exige rede.

## Critérios de aceite

- Default do app = manga-ocr (ADR-0001). Nenhum caminho de produto chama ML Kit.
- Confirm crop → OCR auto → `ocr_text` visível e editável em `/pages/:id` ([leitor](leitor.md)).
- Cloud Vision só existe atrás do toggle (F26), quando implementado.

> Pendente: UX do editor de `ocr_text` (inline, sheet, teclado).
> Pendente: Q-N3 — orçamento Cloud Vision (USD/mês).
> Pendente: limiar numérico da altura no filtro de furigana (Q-N5).
> Pendente: interação do overlay F22 (tap, toggle, sempre visível).
