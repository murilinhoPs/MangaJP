# Roadmap

Visão das milestones do MangaJP, sem lista de tasks. Fonte: recorte da PRD v1.3 §18 (fora do repo) e o estado do GitHub em 31/10/2026. Detalhe de produto: [`prd.md`](prd.md). Como planejar a próxima fase: [`processo.md`](processo.md#7-planejamento-em-duas-etapas). O plano detalhado de uma milestone, quando existir, mora em `docs/milestones/m<n>.md`, não em `specs/`.

## M0 — Spike

**Objetivo.** Provar o stack (Flutter, dict, deinflect, SM-2) e escolher o OCR default com CER medido, ou documentar o melhor motor + plano.

**Features.** Spike, sem IDs F# de produto: app hello, GT Silent Hill f, bake-off CER (ML Kit / Cloud Vision / manga-ocr), `tools/build_jmdict_sqlite` (`forms` + `sense_pos`), deinflector Yomitan (≥50 vetores), smoke share + crop, suíte SM-2 `engine_id=sm2-jr@1`.

**Saída.** Go/no-go registrado antes da M1. Q-B1 fechada em [ADR-0001](adr/0001-ocr-default-manga-ocr.md) (manga-ocr default; nenhum motor ≤ 10% CER). Q-B3 fechada em [ADR-0002](adr/0002-licenca-gpl-yomitan.md). Medição: [`m0.3-cer-bakeoff.md`](m0.3-cer-bakeoff.md).

**Dependências.** Nenhuma. Decisões de produto do spike já fechadas.

**Tamanho.** P (5–7 dias no recorte antigo).

**Status.** Fechada. Sem milestone no GitHub.

## M1 — MVP

**Objetivo.** O loop diário roda de ponta a ponta no Android: share/galeria → crop ≥1 → OCR → lookup → Caderno de palavras → revisão SM-2 offline.

**Features.** F1, F2, F3, F4, F5, F6–F9, F10, F11, F12, F13–F15, F17, F18, F19, F20, F41–F44.

**Saída.** Share ou galeria produz `/pages/:id` com texto OCR; Salvar / Aprendendo / Conhecido / Ignorar grava o Caderno; Home **Revisar** abre a fila SM-2 offline. ACs Must do recorte antigo (AC-save … AC-remove) verdes.

**Dependências.** Go da M0. iOS ficou de fora ([ADR-0003](adr/0003-ios-plataforma-secundaria.md)).

**Tamanho.** G.

**Status.** Entregue na `main` (loop de estudo). Sem milestone no GitHub. O README da raiz ainda marca lista `/pages`, `/deck` e `/settings` como stub de tela.

## D — Docs e processo

**Objetivo.** Spec, ADRs, print-rules e tasks moram no GitHub; Notion vira vitrine.

**Features.** Nenhuma F#. Migração D1: [`/docs`](README.md), templates, labels, Project.

**Saída.** [`prd.md`](prd.md) e specs no repo; issue template cria task no Project; PR de comportamento atualiza a spec no mesmo PR.

**Dependências.** Nenhuma de produto.

**Tamanho.** P.

**Status.** Aberta no GitHub — [milestone D](https://github.com/murilinhoPs/MangaJP/milestone/1) (0 issues abertas; [#57](https://github.com/murilinhoPs/MangaJP/issues/57) fechada).

## M2.1 — iOS secundário

**Objetivo.** O app roda no simulador iOS como plataforma secundária, sem bloquear o merge na nuvem quando o Mac está off.

**Features.** F40 (iOS). Prints e PopScope conforme [ADR-0003](adr/0003-ios-plataforma-secundaria.md) e [`qa/print-rules.md`](qa/print-rules.md).

**Saída.** PRs com código de plataforma declaram o comportamento no iOS. Widget do gesto de voltar cobre Captura e Review. Prints iOS: simulador iPhone 17, qualquer resolução. Android 390×844 e Linux 1280×800 continuam obrigatórios na nuvem.

**Dependências.** M1 fechada. Worker Mac do Murilo; enquanto estiver desligado, a fila é a [#54](https://github.com/murilinhoPs/MangaJP/issues/54) e não bloqueia o PR.

**Tamanho.** M.

**Status.** Código e regras de print na `main` (descrição do milestone M2: M2.1 concluída). Sem milestone próprio. Fila Mac/iOS [#54](https://github.com/murilinhoPs/MangaJP/issues/54) ainda aberta.

## M2 — Pós-M1 (v0.9)

**Objetivo.** Shoulds que faltavam depois do MVP: kanji no Caderno, Cloud Vision opcional, e o restante do recorte v0.9.

**Features.** F21 (`/pages` histórico), F22 (bounding boxes), F23 (suspender no Deck), F24 (KANJIDIC2 no lookup), F25 (backup JSON), F26 (Cloud Vision), F45 (`saved_kanji` / aba Kanji).

**Saída.** Kanji salvo aparece na aba Kanji com leituras, significados e traços, fora do SRS ([#58](https://github.com/murilinhoPs/MangaJP/issues/58)). Cloud Vision só existe atrás do toggle ([#59](https://github.com/murilinhoPs/MangaJP/issues/59)). F21, F22, F23 e F25 ainda não têm issue.

**Dependências.** Spec de kanji da [#58](https://github.com/murilinhoPs/MangaJP/issues/58) fechada antes da implementação. Q-N3 (orçamento Cloud Vision) aberta. Fila Mac [#54](https://github.com/murilinhoPs/MangaJP/issues/54) para prints iOS/macOS.

**Tamanho.** G.

**Status.** Aberta — [milestone M2](https://github.com/murilinhoPs/MangaJP/milestone/2), issues [#58](https://github.com/murilinhoPs/MangaJP/issues/58) e [#59](https://github.com/murilinhoPs/MangaJP/issues/59).

## M3 — v1

**Objetivo.** Fechar a v1 com melhorias de OCR/manga, export do Caderno e os Could que sobrarem, sem virar reader nem loja pública.

**Features.** F27 (furigana, se o engine der boxes), F33 (web experimental), F34 (tokenização Could), F46 (export Caderno Markdown/CSV). Opcionais: F31 (Anki), F32 / Q-N4 (sync), polish de UI do KANJIDIC2.

**Saída.** Export do Caderno gera Markdown ou CSV. Web experimental sobe sem substituir o app. Tokenização e Anki só entram se a decisão Could virar Should.

**Dependências.** M2. Q-N3 e Q-N4 continuam abertas. F38 (kanji cards) permanece Won't.

**Tamanho.** G.

**Status.** Não existe milestone no GitHub. Não abrir issues desta fase enquanto a M2 for a atual.
