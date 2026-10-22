# Regras de print

Prints de QA **não** entram em `docs/assets/`. Vão para a branch `pr-assets`:

```text
docs/pr-assets/pr-N/<head>/<plataforma>/
```

Branch `pr-assets`. `N` = número do PR. `<head>` = SHA-1 **curto** do **head final** do PR. `<plataforma>` = `android` | `ios` | `desktop` | `macos`.

`docs/assets/` no `main` só recebe prints **oficiais e finais**.

## Quando é obrigatório

Todo PR que mexe em **design, telas ou tema** precisa de print de **emulador/simulador** no corpo do PR.

Teste de widget ou golden **sozinho não conta**. Sem esses prints o PR **não** é squash-mergeado.

`<head>` no caminho e no `print_sizes.txt` é sempre o **head final** do PR. Print de head antigo não vale: se o head mudar, refazer.

## Tamanho e recorte (obrigatório)

| Plataforma | Tamanho | Recorte |
| --- | --- | --- |
| **Android** | **obrigatório 390×844**, retrato, **sem hover** | tela do emulador |
| **Desktop** | **obrigatório 1280×800** | **só a área do app** — sem moldura de janela, sem title bar; cantos opacos |
| **macOS** | **obrigatório 1x 1280×800**, sRGB, **sem** perfil Display P3 | **só a área do app** — sem moldura de janela, sem title bar; cantos opacos |
| **iOS** | retrato; resolução **Pendente** | ver nota abaixo |

Android 390×844 e desktop 1280×800 **não** são opcionais. macOS 1x 1280×800 sRGB sem P3 **não** é opcional.

> Pendente (confirmação do Murilo): «iPhone 17 ou qualquer simulador em retrato, sem exigência de resolução». Há divergência entre iPhone 17 (iOS 27) **exclusivo** e **qualquer** simulador. [ADR-0003](../adr/0003-ios-plataforma-secundaria.md) registra a decisão 2026-10-13; este D1 não escolhe um dos lados.

Telas que **só existem no layout largo** (sidebar, paleta Ctrl+K, rail) **não** vão no bloco Android. Ver a seção no fim.

## Cores

A checagem vale para os **elementos que aparecem no print**, iguais a [`lib/core/theme/tokens.json`](../../lib/core/theme/tokens.json):

- Fundo **`#0E0D12`** (`color.bg`) — **sempre**.
- Coral **`#FF5C7A`** (`color.coral`) — **só** quando houver elemento coral na tela. Não exigir coral em print sem CTA / tile / kbd coral.

## `print_sizes.txt`

No mesmo diretório do PR/head. Uma linha `head:` com o **SHA-1 completo do commit** (40 caracteres hex). Em cada print, o **sha256 do arquivo** (64 caracteres hex) — não o hash do commit.

```text
head: <SHA-1 completo do commit, 40 caracteres>

<plataforma>/<arquivo>.png <largura>x<altura> sha256:<64 caracteres do arquivo>
```

O `head:` tem que ser o SHA-1 do **head final**. Se o PR ganhar commit novo, apagar os prints do head antigo e refazer.

## Seletor de arquivos

Prints do picker usam a pasta neutra **`~/MangaJP-QA/`** com a fixture `test/fixtures/manga_test_page.png`. Nunca arquivo pessoal (repo público).

## Captura original

> Proposta, pendente de confirmação do Murilo: o print é a captura original, sem edição (crop externo, blur, tarja). Para esconder algo, ajuste a cena **antes** de capturar.

## `integration_test` no corpo do PR

Bloco = **saída real** de um run no **head final**. Nunca escrito à mão.

Incluir a saída de `git rev-parse --short HEAD` **junto** da saída do teste, para provar que rodou nesse head.

Se o PR **não** toca `integration_test/` **nem** o fluxo que a suíte cobre, o bloco é `n/a` + **uma linha** de motivo.

## macOS — entitlement do picker

CI **falha** se `com.apple.security.files.user-selected.read-only` sair dos `.entitlements` do macOS (`macos/Runner/DebugProfile.entitlements` e `Release.entitlements`). Sem essa key o `NSOpenPanel` não abre no Runner com sandbox.

## Layout largo (desktop)

Só aqui: telas e chrome que **não existem** no Android 390×844.

- Rail / sidebar
- Paleta **Ctrl+K** / ⌘K
- Barra flutuante, kbd `G` / `R`, grid de capturas em coluna

Prints: desktop **1280×800** (só área do app) e, quando couber, macOS 1x 1280×800 sRGB sem P3. Não misturar com o bloco Android.
