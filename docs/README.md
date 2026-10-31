# `/docs`

Spec viva do MangaJP. O que muda junto com o código mora aqui. O Notion é vitrine: não é fonte de verdade.

O README da raiz explica o que o app faz e como rodar. Não copie comportamento pra lá — atualize a spec.

## Origem

PRD v1.3, snapshot 2026-10-14c. Versões seguintes do PRD curto (`prd.md`) são **git tag** (`prd-vX.Y`), não sha manual no texto.

Medição OCR M0.3 (números, protocolo): [`m0.3-cer-bakeoff.md`](m0.3-cer-bakeoff.md). O bake-off e o README da raiz registram o default de trabalho; a decisão de produto fechada no PRD é [ADR-0001](adr/0001-ocr-default-manga-ocr.md).

## Pastas

| Pasta | Conteúdo |
| --- | --- |
| [`prd.md`](prd.md) | Visão, escopo, jornadas, stack. Linka as specs. |
| [`roadmap.md`](roadmap.md) | Visão das milestones (sem tasks). |
| [`processo.md`](processo.md) | Processo de desenvolvimento reutilizável (issues, labels, Project, fluxo, gates). |
| [`specs/`](specs/captura.md) | Uma spec por feature. Comportamento atual. |
| `milestones/` | Plano da milestone em execução (`m<n>.md`). Criada na etapa 2; não misturar com `specs/`. |
| [`adr/`](adr/README.md) | Decisões. Índice e template. |
| [`qa/print-rules.md`](qa/print-rules.md) | Como tirar e anexar print. |
| [`qa/telas.md`](qa/telas.md) | Índice gerado das telas (`print_sizes.txt` em `pr-assets`). |
| `assets/` | Só prints oficiais e finais. |
| `m0.3-cer-bakeoff.md` | Bake-off CER (medição). Não reescrever números. |

Índice de telas: [`qa/telas.md`](qa/telas.md). Regenerar à mão em PR de manutenção: `dart run tool/gen_telas.dart`. Pode ficar atrás do `pr-assets` — isso não é erro.

QA de PR não entra em `docs/assets/`. Prints de QA ficam na branch `pr-assets`.

Templates GitHub (fora de `/docs`): [`.github/pull_request_template.md`](../.github/pull_request_template.md), [`.github/ISSUE_TEMPLATE/feature.yml`](../.github/ISSUE_TEMPLATE/feature.yml), [`.github/ISSUE_TEMPLATE/bug.yml`](../.github/ISSUE_TEMPLATE/bug.yml). Labels `type:feature` / `type:bug` e área `area:*` (capture, ocr, dictionary, review, shell, platform).

## Regras

1. **PR que muda comportamento** atualiza a spec ou o ADR correspondente **no mesmo PR**. O review cobra.
2. **Decisão nova ou revertida** vira ADR. Nunca editar um ADR aceito em silêncio: status `Superada` + ADR novo.
3. **Versão do PRD** = git tag, não sha no markdown.
4. **`docs/assets/`** só prints oficiais e finais. Prints de QA: branch `pr-assets` em `pr-N/<head>/<plataforma>/`.
5. **Notion** é vitrine. Se Notion e `/docs` divergirem, vale `/docs`.

## Specs

- [Captura](specs/captura.md)
- [OCR](specs/ocr.md)
- [Recorte](specs/recorte.md)
- [Dicionário](specs/dicionario.md)
- [Palavras / Caderno](specs/caderno.md)
- [Flashcards](specs/flashcards.md)
- [Revisão / SM-2](specs/revisao.md)
- [Home](specs/home.md)
- [Galeria](specs/galeria.md)
- [Leitor](specs/leitor.md)
- [Ajustes](specs/settings.md)

## ADRs deste D1

- [ADR-0001](adr/0001-ocr-default-manga-ocr.md) — Q-B1 OCR default
- [ADR-0002](adr/0002-licenca-gpl-yomitan.md) — Q-B3 GPL + Yomitan
- [ADR-0003](adr/0003-ios-plataforma-secundaria.md) — Q-N1 iOS
- [ADR-0004](adr/0004-nav-design-system.md) — Q-N8 nav
- [ADR-0005](adr/0005-saida-revisao.md) — saída da revisão

Outras decisões já fechadas no PRD (Q-B2, Q-N2, Q-N5, Q-N6, Q-N7) ficam nas specs até virarem ADR.

## Convenções

- UI em pt-BR. Study-day: `04:00 America/Sao_Paulo`.
- IDs de feature (F1…) e AC (AC-share…) são os do PRD. Não renomear.
- Onde o PRD for ambíguo: `> Pendente:` na spec. Não inventar.
- Bundle ID / `applicationId`: **`dev.murilinhops.mangajp`** em todas as plataformas — Android, iOS, macOS, Linux (Murilo, 22/10). Linux alinhado no [#66](https://github.com/murilinhoPs/MangaJP/pull/66), com migração da pasta de dados antiga.
