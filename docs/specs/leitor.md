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
- **F26 Should:** cada crop guarda `engineId`; a página mostra um chip do motor, **misto** se os crops diferirem — [cloud-vision](cloud-vision.md).
- **F21 Should:** lista `/pages` (histórico). M1 exige `/pages/:id` pós-OCR. Capturas recentes na Home permanecem e não substituem esta lista.
- **Linha da lista (decisão do dono do projeto, 2026-11-04, PR [#101](https://github.com/murilinhoPs/MangaJP/pull/101)):** por enquanto a linha mostra um **placeholder com o título** (o título/OCR da página; sem OCR, «Página» com ícone — o que o #101 já faz). Nenhuma imagem de thumb é gerada nem salva agora.
- Thumb de imagem: depende de `thumb_path` (migração de schema); issue a abrir.

**Continuar lendo** na Home só abre esta tela, não `/review` ([ADR-0005](../adr/0005-saida-revisao.md)).

Não-objetivo: reader completo tipo Mokuro.

## Critérios de aceite

- Pós-OCR o app mostra `/pages/:id` com `ocr_text` persistido.
- Tap em token abre a sheet de lookup (AC-lookup / AC-homógrafo).
- Novos crops na página existente respeitam dedupe (AC-dedupe).
- `/pages` (lista) é Should F21: deixa de redirecionar pra Home e lista as páginas persistidas. Linha = placeholder com título (decisão 2026-11-04); sem imagem de thumb nesta entrega.
- Rail Leitor: página mais recente, ou desabilitado se não houver páginas.
- Back/swipe pop sem o diálogo da Review.

> Pendente: meta do dock (o que a pílula mostra).
> Pendente: lista `/pages` (F21 / M2) além da linha — empty state, copy, data; ver [`m2.md`](../milestones/m2.md). A thumb da linha está fechada (placeholder com título, 2026-11-04).
> Pendente: overlay F22 (M2) — quando liga e o que o tap na box faz; ver [`m2.md`](../milestones/m2.md).
> Pendente: chip do motor OCR (F26) — [cloud-vision](cloud-vision.md).
