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
- **F22 Should:** overlay de bounding boxes sobre a **imagem da página** ([#97](https://github.com/murilinhoPs/MangaJP/issues/97) / [#114](https://github.com/murilinhoPs/MangaJP/pull/114)). Toggle global persistido `reader.ocrOverlay` (SharedPreferences; default ligado). Desktop (≥ 900): tecla **B**. Mobile: botão 48 px no TaskDock (copy **Esconder boxes** / **Mostrar boxes**). Sem `pages.image_path` o toggle some e a tela fica nos cards de texto. Tap na box abre o lookup do primeiro termo (índice 0 do texto da box). Desktop: **Tab** / **Shift+Tab** ciclam, **Enter** abre, **Esc** desmarca a box e fecha o lookup.
- **F22 — persistência.** No confirm da captura, a imagem é decodificada, recebe `bakeOrientation` e é gravada como PNG em `{documents}/pages/{pageId}.png` (`path_provider` / `getApplicationDocumentsDirectory`; `encodePagePng`). JPEG/WebP via `compute`; PNG de entrada segue bit-a-bit, nesta isolate. O `sha256` de dedupe continua nos bytes recebidos. Crops também passam por `bakeOrientation` (`cropToPng` / `cropAllToPng`). Detalhe: [captura](captura.md). O caminho entra em `pages.image_path` (nullable). Boxes do motor (quando há `Rect`) entram em `crops.ocr_blocks_json`. Web: o save devolve `null` (sem overlay). Sem migração (schema **10**). JSON: [ocr](ocr.md).
- **F22 — overlay vs cards.** A escolha segue `pages.image_path`. Com path: `detectImageMagic` / `imageSizeFromHeader` leem só o header (até 128 KiB, `kPageImageHeaderCap`) — PNG IHDR, JPEG SOF + EXIF orientation 5–8 (troca w×h), WebP VP8/VP8L/VP8X — sem decode da imagem inteira e sem olhar a extensão. O parser WebP só precisa dos bytes de dimensão (`VP8 ` `payload+10`, `VP8L` `payload+5`, VP8X 10 bytes), não do chunk inteiro, então um WebP simples maior que o prefixo de 128 KiB ainda abre o overlay. Páginas antigas com JPEG/WebP gravados como `.png` abrem o overlay; por isso o schema permanece **10**. JPEG com segmentos APP (XMP/ICC/MPF) enormes antes do SOF pode não achar o tamanho e cair nos cards. Path órfão / formato desconhecido: cards de texto, toggle oculto, sem crash. Overlay desligado **mantém a imagem**, sem boxes — não volta aos cards.
- **F22 — lookup no mobile** (`< 900`) quando a página tem imagem e o overlay está ligado: sheet **inline** (não modal) num `Column` acima do TaskDock; a imagem encolhe no `Expanded`. Altura = `lookupSheetHeightOf` = metade de (`MediaQuery.size.height` − teclado). O `Scaffold` zera o `viewInsets` herdado, então a função também lê o inset do `View`; `WidgetsBindingObserver.didChangeMetrics` reconstrói no Android 15. Clamp em `maxHeight − 96`. Fecha por **X**, handle (flick vertical > 280), `PopScope` / botão voltar do Android, seta da AppBar, **Esc**, ou desligar o overlay (tecla **B** ou o toggle). Salvar / Aprendendo / Conhecido / Ignorar no phone também fecham o lookup. Página **sem** imagem (ou path órfão): sheet **modal**.
- **F22 — lookup no desktop** (`≥ 900`): drawer à direita (400 px). Tap ou **Enter** na box selecionada preenche o drawer (não abre sheet). **Esc** desmarca a box e limpa a sessão. Hover: fill `overlayPrimaria`, borda coral. A área da imagem reserva `commandBarPaddingOf` para a command bar não cobrir a imagem. Depois de uma ação no drawer, a sessão permanece com o `word_state` atualizado (não fecha).
- **F22 — troca de box com lookup aberto.** A seleção do homógrafo volta para a primeira entrada. No phone o sheet fica na árvore (sem barrier do modal) para o segundo tap chegar na box.
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
- Com `pages.image_path` válido (header PNG/JPEG/WebP ok): a tela mostra a imagem da página; overlay ligado desenha as boxes (engine `Rect` mapeado do crop para a página, ou, sem `Rect`, o retângulo do crop). Overlay desligado: a imagem permanece, sem boxes.
- Sem `pages.image_path` (páginas antigas) ou path órfão: cards de texto; toggle de overlay oculto.
- Tap na box → lookup do primeiro termo (o mesmo lookup do tap no texto). Desktop: Tab cicla boxes, Enter abre lookup, Esc desmarca. Mobile: Enter **não** está no mapa de atalhos (só tap / B / Esc com o sheet aberto).
- Mobile com imagem: sheet inline acima do TaskDock; fecha por X, handle, `PopScope`, AppBar, Esc, toggle/B. Sem imagem: sheet modal.
- Trocar de box com o lookup aberto não crasha; a seleção do homógrafo volta para a primeira entrada.

> Pendente: meta do dock (o que a pílula mostra).
> Pendente (follow-up, não bloqueia F22): teste geral de Esc no `AppChrome` (hoje o Esc do overlay está no widget da página + action `close-lookup`; não há teste de shell que cubra o encaminhamento).
> Pendente (follow-up): build de emulador sem `jmdict.sqlite` mostra SnackBar «Dicionário indisponível».
> Pendente (follow-up): com o teclado aberto o sheet desconta `viewInsets` e a imagem fica pequena.
> Pendente (follow-up de código): em páginas JPEG antigas com EXIF 5–8 o overlay pode desalinhar — o header agora troca w×h (certo pro display), mas crops/boxes foram salvos no espaço sem rotação.
