# Leitor

Rota: `/pages/:id` (resultado da página). `/pages` lista o histórico completo, com thumbnail, título e data por item (F21). Rail **Leitor** abre a página mais recente (desabilitado sem páginas). Capturas recentes na Home (até 6) permanecem.

## Objetivo

Ver a página com crops, texto OCR e termos; lookup no tap; reler sem perder `word_state`.

## Comportamento

- Imagem + crops + termos + `word_states` coloridos (F5, J3).
- Texto OCR editável por crop — [ocr](ocr.md).
- Tap no texto → lookup (deinflexão + homógrafos) — [dicionario](dicionario.md).
- Pode promover termo, marcar known, ou **adicionar novos crops** na mesma página (dedupe) — [recorte](recorte.md).
- Tela de tarefa: esconde nav cards; dock próprio (voltar · meta). Swipe-back / back **normais** (não é Review; #46 / M1.29).
- **F22 Should:** overlay de bounding boxes quando o OCR fornecer.
- Histórico `/pages` com thumbnails (F21): thumbnail (OCR do 1º crop; ícone se não houver texto), título da página, data (`hoje` / `ontem` / `d MMM`). Sem badges de `word_state`. Sem página: «Nenhuma página.» + **Galeria +**.

**Continuar lendo** na Home só abre esta tela, não `/review` ([ADR-0005](../adr/0005-saida-revisao.md)).

Não-objetivo: reader completo tipo Mokuro.

## Critérios de aceite

- Pós-OCR o app mostra `/pages/:id` com `ocr_text` persistido.
- Tap em token abre a sheet de lookup (AC-lookup / AC-homógrafo).
- Novos crops na página existente respeitam dedupe (AC-dedupe).
- `/pages` lista todas as páginas persistidas (não só as 6 da Home), newest first. Tap abre `/pages/:id`.
- Empty: «Nenhuma página.» e ação **Galeria +**.
- Rail Leitor: página mais recente, ou desabilitado se não houver páginas.
- Back/swipe pop sem o diálogo da Review.

> Pendente: meta do dock (o que a pílula mostra).
> Pendente: overlay F22 (M2) — quando liga e o que o tap na box faz; ver [`m2.md`](../milestones/m2.md).
