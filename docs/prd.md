# PRD curto — MangaJP Study

Ferramenta pessoal para estudar japonês via manga. Flutter only. Single-user (Murilo).

Versão viva deste recorte: **v1.3**. Atualizado **2026-10-22** (print/QA). Origem: snapshot 2026-10-14c. Cortes seguintes: git tag `prd-vX.Y`. Texto completo do PRD não mora no repo.

## Visão

> “Compartilhei o screenshot do Silent Hill f → confirmei o balão → salvei o vocab → revisei no metrô sem internet.”

Share/galeria → crop de balão → OCR → lookup com deinflexão → Caderno → flashcard SM-2 offline. Sem Anki no fluxo diário.

## Público

Murilo. Estuda com manga (ex.: 《サイレントヒルf》 no Comic Walker). Quer captura rápida, OCR bom o suficiente, SRS offline.

## Não-objetivos (v1)

- Marketplace, multi-usuário, social.
- Reader tipo Mokuro (volume HTML).
- Scraping / integração automática do Comic Walker (só screenshot/upload do usuário).
- TTS, grammar parsing, pitch accent.
- Sync em nuvem obrigatório (API de review é opcional / Q-N4).
- FSRS como algoritmo primário.
- Learning steps Anki-like (1 min / 10 min).
- Flashcards de kanji (salvar kanji no Caderno = Should F45/M2, fora do SRS).
- Edição de texto ou notas no Caderno (somente consulta).
- iOS App Store / Play Store públicos (sideload / debug OK). iOS entra na M2.1 — [ADR-0003](adr/0003-ios-plataforma-secundaria.md).
- LLM para gloss PT (gloss EN + `user_note` PT — Q-N2).

## Escopo MoSCoW

Must, Should, Could, Won't do PRD. Spec por feature:

| Área | Spec | Must | Should / Could / Won't |
| --- | --- | --- | --- |
| Captura | [captura](specs/captura.md) | F1 galeria, F2 share Android | F28 câmera Could |
| Recorte | [recorte](specs/recorte.md) | F3 crop ≥1, F19 imagens | — |
| OCR | [ocr](specs/ocr.md) | F4 manga-ocr, F5 texto editável | F22 boxes, F26 Cloud, F27 furigana Should; F29 outros motores Could |
| Dicionário | [dicionario](specs/dicionario.md) | F6–F9 lookup | F24 KANJIDIC2 Should; F34 tokenização Could |
| Palavras / Caderno | [caderno](specs/caderno.md) | F10, F12, F41–F44 | F45 kanji Should/M2; F46 export Could |
| Flashcards | [flashcards](specs/flashcards.md) | F11 CRUD vocab | F23 suspender Should; F38 kanji cards Won't |
| Revisão | [revisao](specs/revisao.md) | F13–F15, F18, F20 | F30 reading na frente Could; F39 steps Won't |
| Home / nav | [home](specs/home.md) | F17 shell | — |
| Galeria | [galeria](specs/galeria.md) | F1 + entrada F21 | — |
| Leitor | [leitor](specs/leitor.md) | `/pages/:id` pós-OCR | F21 lista `/pages` Should (hoje redireciona) |
| Ajustes | [settings](specs/settings.md) | destino F17, F18 offline | F25 backup Should; F31 Anki Could |

Won't de produto: F35 contas, F36 scraping, F37 multi-deck sharing, F40 iOS só na M2.1.

## Jornadas

1. **Share → estudo** — share abre [`/capture`](specs/captura.md) (sem Home) → ≥1 crop → OCR auto → [`/pages/:id`](specs/leitor.md) → tap → Salvar / Aprendendo / Conhecido / Ignorar ([caderno](specs/caderno.md)).
2. **Revisão offline** — Home **Revisar** → fila due → Again/Hard/Good/Easy → resumo ([revisao](specs/revisao.md)).
3. **Releitura** — página recente: crops + `word_state`; promover, known, novos crops.
4. **Caderno** — lista, busca, filtros; detalhe read-only; Aprender / remover.
5. **Backup (Should)** — export JSON/SQLite. Sync HTTP é Could (Q-N4).

O4: ≤ 2 taps in-app share → texto OCR (confirm/nav contam; drag/pinch do crop não).

## Stack fechada

- Flutter only (não CLJS). Android first. iOS = M2.1. Web = experimental (F33).
- Feature-first + MVVM + Riverpod codegen + go_router + Drift.
- Domain SRS + deinflect em Dart puro (sem Flutter).
- OCR default **manga-ocr** — [ADR-0001](adr/0001-ocr-default-manga-ocr.md). ML Kit fora do app. Cloud Vision = F26/M2.
- Dict: `jmdict.sqlite` próprio (`entries` / `forms` / `sense_pos` / `kanji`).
- Deinflexão: transforms Yomitan. App **GPL** — [ADR-0002](adr/0002-licenca-gpl-yomitan.md).
- SRS: `engine_id = sm2-jr@1` (porta `sm2.clj`). Onde o PRD e o Clojure divergirem, **`sm2.clj` vence**.
- Nav: Design System — [ADR-0004](adr/0004-nav-design-system.md).
- Persistência local-first. Imagens não sobem à cloud salvo toggle Cloud OCR.
- Bundle ID / `applicationId`: **`dev.murilinhops.mangajp`** em todas as plataformas (Murilo, 22/10). Linux ainda `dev.murilinhops.manga_jp` — [#62](https://github.com/murilinhoPs/MangaJP/issues/62).

## Prints e QA (2026-10-22)

Fonte detalhada: [`docs/qa/print-rules.md`](qa/print-rules.md).

1. **iOS** — prints do simulador **iPhone 17**, qualquer resolução. Obrigatórios na nuvem: Android **390×844** retrato e Linux desktop **1280×800** (sem moldura nem title bar). [ADR-0003](adr/0003-ios-plataforma-secundaria.md) aponta pra essa regra.
2. **Edição** — print sem edição, salvo esconder dado sensível, **declarado no PR** com motivo. Padrão: borrar ou cobrir (mantém 390×844 / 1280×800). Recortar é exceção e só sai do tamanho padrão se o PR declarar; o gate de tamanho só aceita com esse aviso. `print_sizes.txt` registra o sha256 do arquivo **final**.
3. **Bundle ID** — `dev.murilinhops.mangajp` em todas as plataformas. Linux ainda `manga_jp` em `linux/CMakeLists.txt` ([#62](https://github.com/murilinhoPs/MangaJP/issues/62)).

## Questões abertas (não-bloqueantes)

- Q-N3 — orçamento Cloud Vision (USD/mês).
- Q-N4 — backend japanese-reader para sync.

Bloqueantes: nenhuma. Q-B1 e Q-B3 fechadas.
