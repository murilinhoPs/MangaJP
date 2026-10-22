# Regras de print

Prints de QA **não** entram em `docs/assets/`. Vão para a branch `pr-assets`:

```text
docs/pr-assets/pr-N/<head>/<plataforma>/
```

Branch `pr-assets`. `N` = número do PR. `<head>` = sha curto do commit dos prints. `<plataforma>` = `android` | `ios` | `desktop` | `macos`.

`docs/assets/` no `main` só recebe prints **oficiais e finais**.

## Tamanho e recorte

| Plataforma | Tamanho | Recorte |
| --- | --- | --- |
| Android phone | **390×844** | obrigatório |
| Desktop | **1280×800** | **só a área do app** |
| iOS | qualquer simulador, **retrato** | resolução **não** importa ([ADR-0003](../adr/0003-ios-plataforma-secundaria.md)) |
| macOS | **1x 1280×800**, sRGB | **só a área do app**; **sem** perfil Display P3 |

## `print_sizes.txt`

No mesmo diretório do PR/head. Head em **sha completo**. Sha256 de **cada** print.

```text
head: <sha256 completo do commit>

<plataforma>/<arquivo>.png <largura>x<altura> sha256:<hex>
```

## Seletor de arquivos

Prints do picker usam a pasta neutra **`~/MangaJP-QA/`** com a fixture `test/fixtures/manga_test_page.png`. Nunca arquivo pessoal (repo público).

## Captura original

> Proposta, pendente de confirmação do Murilo: o print é a captura original, sem edição (crop externo, blur, tarja). Para esconder algo, ajuste a cena **antes** de capturar.

## `integration_test` no corpo do PR

Bloco = **saída real** de um run no **head final**. Nunca escrito à mão.

Se o PR **não** toca `integration_test/` **nem** o fluxo que a suíte cobre, o bloco é `n/a` + **uma linha** de motivo.

## macOS — entitlement do picker

CI **falha** se `com.apple.security.files.user-selected.read-only` sair dos `.entitlements` do macOS (`macos/Runner/DebugProfile.entitlements` e `Release.entitlements`). Sem essa key o `NSOpenPanel` não abre no Runner com sandbox.
