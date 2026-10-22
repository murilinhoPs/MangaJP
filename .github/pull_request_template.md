Closes #N

Head final (SHA-1, 40 caracteres):

## Prints

Conforme [`docs/qa/print-rules.md`](../docs/qa/print-rules.md). Obrigatório se o PR mexe em design, telas ou tema (widget/golden sozinho não conta).

- [ ] Android **390×844**, retrato, **sem hover**
- [ ] Desktop **1280×800**, **só a área do app** (sem moldura / title bar; cantos opacos)
- [ ] macOS **1x 1280×800** sRGB, **sem** Display P3, só a área do app
- [ ] iOS retrato — resolução ver print-rules (`> Pendente:`)
- [ ] Cores: fundo `#0E0D12` **sempre**; coral `#FF5C7A` **só** se a tela tiver elemento coral
- [ ] `print_sizes.txt` — `head:` SHA-1 completo (40) + sha256 (64) de cada arquivo
- [ ] Prints no **head final** (head antigo não vale)
- [ ] File picker: pasta neutra `~/MangaJP-QA/` + fixture `test/fixtures/manga_test_page.png` (nunca arquivo pessoal)
- [ ] Layout largo (sidebar, Ctrl+K) em 1280×800, **não** no bloco Android — se couber

Branch `pr-assets`: `docs/pr-assets/pr-N/<head>/<plataforma>/`.

## `integration_test`

Saída **real** do run no head final (nunca escrita à mão), **junto** de `git rev-parse --short HEAD`. Se o PR não toca `integration_test/` nem o fluxo coberto: `n/a` + uma linha de motivo.

```
$ git rev-parse --short HEAD


$ flutter test integration_test …

```
