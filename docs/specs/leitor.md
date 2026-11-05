# Leitor

Rota: `/pages/:id` (resultado da página). `/pages` lista o histórico completo, com título e data por item (F21). Rail **Leitor** abre a página mais recente (desabilitado sem páginas). Capturas recentes na Home (até 6) permanecem.

## Objetivo

Ver a página com crops, texto OCR e termos; lookup no tap; reler sem perder `word_state`.

## Comportamento

- Imagem + crops + termos + `word_states` coloridos (F5, J3).
- Texto OCR editável por crop — [ocr](ocr.md).
- Tap no texto → lookup (deinflexão + homógrafos) — [dicionario](dicionario.md).
- Pode promover termo, marcar known, ou **adicionar novos crops** na mesma página (dedupe) — [recorte](recorte.md).
- Tela de tarefa: esconde nav cards; dock próprio (voltar · meta). Swipe-back / back **normais** (não é Review; #46 / M1.29).
- **F22 Should:** overlay de bounding boxes quando o OCR fornecer.
- **F26 Should:** cada crop guarda `engineId`; a página mostra um chip do motor, **misto** se os crops diferirem. Defaults aprovados em 2026-11-04; implementação na [#59](https://github.com/murilinhoPs/MangaJP/issues/59) — [cloud-vision](cloud-vision.md).
- **F21 Should:** lista `/pages` (histórico). Título da página, data (`hoje` / `ontem` / `d MMM`; ano se for outro). Sem badges de `word_state`. Newest first. Sem página: «Nenhuma página.» + **Galeria +**. Capturas recentes na Home não substituem esta lista. Header **Ver todas** e paleta **Páginas** abrem `/pages`.
- **Linha da lista (decisão do dono do projeto, 2026-11-04):** por enquanto a linha mostra um **placeholder com o título** (o título/OCR da página; sem OCR, «Página» com ícone — o que o [#101](https://github.com/murilinhoPs/MangaJP/pull/101) já faz). Nenhuma imagem de thumb é gerada nem salva agora.
- Thumb de imagem: depende de `thumb_path` (migração de schema); issue a abrir.

**Continuar lendo** na Home só abre esta tela, não `/review` ([ADR-0005](../adr/0005-saida-revisao.md)).

Não-objetivo: reader completo tipo Mokuro.

## Critérios de aceite

- Pós-OCR o app mostra `/pages/:id` com `ocr_text` persistido.
- Tap em token abre a sheet de lookup (AC-lookup / AC-homógrafo).
- Novos crops na página existente respeitam dedupe (AC-dedupe).
- `/pages` lista todas as páginas persistidas (não só as 6 da Home), newest first. Tap abre `/pages/:id`.
- Empty: «Nenhuma página.» e ação **Galeria +**.
- Linha = placeholder com título (decisão 2026-11-04); sem imagem de thumb nesta entrega.
- Rail Leitor: página mais recente, ou desabilitado se não houver páginas.
- Back/swipe pop sem o diálogo da Review.

> Pendente: meta do dock (o que a pílula mostra).
> Pendente: overlay F22 (M2) — quando liga e o que o tap na box faz; ver [`m2.md`](../milestones/m2.md).
