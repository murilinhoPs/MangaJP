# Leitor

Rota: `/pages/:id` (resultado da página). `/pages` (lista) redireciona pra `/home` desde M1.21a. Rail **Leitor** abre a página mais recente (desabilitado sem páginas).

## Objetivo

Ver a página com crops, texto OCR e termos; lookup no tap; reler sem perder `word_state`.

## Comportamento

- Imagem + crops + termos + `word_states` coloridos (F5, J3).
- Texto OCR editável por crop — [ocr](ocr.md).
- Tap no texto → lookup (deinflexão + homógrafos) — [dicionario](dicionario.md).
- Pode promover termo, marcar known, ou **adicionar novos crops** na mesma página (dedupe) — [recorte](recorte.md).
- Tela de tarefa: esconde nav cards; dock próprio (voltar · meta). Swipe-back / back **normais** (não é Review; #46 / M1.29).
- **F22 Should:** overlay de bounding boxes quando o OCR fornecer.
- Histórico `/pages` com thumbnails = **Should F21**. M1 exige `/pages/:id` pós-OCR. Lista própria saiu; Capturas recentes na Home.

**Continuar lendo** na Home só abre esta tela, não `/review` ([ADR-0005](../adr/0005-saida-revisao.md)).

Não-objetivo: reader completo tipo Mokuro.

## Critérios de aceite

- Pós-OCR o app mostra `/pages/:id` com `ocr_text` persistido.
- Tap em token abre a sheet de lookup (AC-lookup / AC-homógrafo).
- Novos crops na página existente respeitam dedupe (AC-dedupe).
- `/pages` (lista) não é Must; redireciona pra Home.
- Rail Leitor: página mais recente, ou desabilitado se não houver páginas.
- Back/swipe pop sem o diálogo da Review.

> Pendente: meta do dock (o que a pílula mostra).
> Pendente: overlay F22 — quando liga e o que o tap na box faz.
