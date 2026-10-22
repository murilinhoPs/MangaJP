# Galeria

Não é tela própria nem tab. Entrada da [Home](home.md) para [captura](captura.md). Must: **F1** + bloco F21.

## Objetivo

Escolher uma imagem e cair em `/capture` no fluxo de crop, sem hop extra.

## Comportamento

- Home → gallery pick (`image_picker`) → `/capture` com a imagem.
- Cancelar o picker **fica na Home**.
- **1º tile** do carrossel/grid de Capturas: «+ Nova da galeria», mesmo tamanho dos thumbs; borda dashed coral **1,5 px** `#FF5C7A`; ícone image+; label Inter 13 semibold coral; fundo coral 6%; **sem** fill sólido.
- Header da seção: link coral **Galeria +** (no lugar de «3 de 3»). Desktop: atalho `G` como kbd JetBrains Mono coral.
- Card antigo «Galeria / Escolher da galeria» **removido**.
- Prints do seletor de arquivos: pasta neutra `~/MangaJP-QA/` e fixture `test/fixtures/manga_test_page.png` — [print-rules](../qa/print-rules.md). Repo público: nunca arquivo pessoal.

## Critérios de aceite

- Tile «+ Nova da galeria», link **Galeria +** e atalho `G` (desktop) abrem o picker e, com imagem, `/capture`.
- Cancelar o picker permanece em `/home`.
- Visual do tile conforme tokens acima (coral dashed, sem fill sólido).

> Pendente: seletor nativo fora do Android (macOS `NSOpenPanel`, Linux, web). O PRD não fecha plataforma de desktop como produto.
