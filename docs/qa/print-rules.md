# Regras de print

Prints de QA **não** entram em `docs/assets/`. Vão para a branch `pr-assets`:

```text
docs/pr-assets/pr-N/<head>/<plataforma>/
```

Branch `pr-assets`. `N` = número do PR. `<head>` = SHA-1 **curto** do **head final** do PR. `<plataforma>` = `android` | `ios` | `desktop` | `macos`.

`docs/assets/` no `main` só recebe prints **oficiais e finais**.

## Quando é obrigatório

Todo PR que mexe em **design, telas ou tema** precisa de print de emulador no corpo do PR.

Obrigatórios na **nuvem** (todo PR que mexe em tela): **Android 390×844** e **desktop Linux 1280×800**. Widget/golden sozinho **não conta**. Sem esses dois o PR **não** é squash-mergeado.

Prints e `integration_test` que **só rodam no Mac** (macOS / iOS): ver [Mac offline](#mac-offline-2026-10-21).

`<head>` no caminho e no `print_sizes.txt` é sempre o **head final** do PR. Print de head antigo não vale: se o head mudar, refazer.

## Tamanho e recorte (obrigatório)

| Plataforma | Tamanho | Recorte |
| --- | --- | --- |
| **Android** | **obrigatório 390×844**, retrato, **sem hover** | tela do emulador |
| **Desktop Linux** | **obrigatório 1280×800** | **só a área do app** — sem moldura de janela, sem title bar; cantos opacos |
| **macOS** | **obrigatório 1x 1280×800**, sRGB, **sem** perfil Display P3 | **só a área do app** — sem moldura de janela, sem title bar; cantos opacos |
| **iOS** | simulador **iPhone 17**, qualquer resolução | retrato |

Android 390×844 e desktop Linux 1280×800 **não** são opcionais (nuvem). Formato macOS (1x 1280×800 sRGB sem P3) vale **quando** o print macOS é capturado; se o worker do Mac estiver desligado, ver [Mac offline](#mac-offline-2026-10-21).

**iOS (Murilo, 13/10):** prints de iOS podem vir do simulador do **iPhone 17**, em **qualquer resolução**. Os prints **obrigatórios** continuam sendo o **Android 390×844 em retrato** e o **Linux desktop 1280×800**, sem moldura nem barra de título. Continuam valendo: SHA-1 completo (40 caracteres) no `print_sizes.txt`; nada de arquivo pessoal; com Mac offline, `n/a: Mac offline — #54 item: <link>` ([Mac offline](#mac-offline-2026-10-21)).

Telas que **só existem no layout largo** (sidebar, paleta Ctrl+K, rail) **não** vão no bloco Android. Ver a seção no fim.

## Cores

A checagem vale para os **elementos que aparecem no print**, iguais a [`lib/core/theme/tokens.json`](../../lib/core/theme/tokens.json):

- Fundo **`#0E0D12`** (`color.bg`) — **sempre**.
- Coral **`#FF5C7A`** (`color.coral`) — **só** quando houver elemento coral na tela. Não exigir coral em print sem CTA / tile / kbd coral.

## `print_sizes.txt`

No mesmo diretório do PR/head. Uma linha `head:` com o **SHA-1 completo do commit** (40 caracteres hex). Em cada print, o **sha256 do arquivo final** (64 caracteres hex) — o PNG já editado, se houve borrão ou recorte. Não é o hash do commit.

```text
head: <SHA-1 completo do commit, 40 caracteres>

<plataforma>/<arquivo>.png <largura>x<altura> sha256:<64 caracteres do arquivo final>
```

O `head:` tem que ser o SHA-1 do **head final**. Se o PR ganhar commit novo, apagar os prints do head antigo e refazer.

Índice gerado dessas linhas: [`telas.md`](telas.md). Regenerar em PR de manutenção com `dart run tool/gen_telas.dart`. Pode ficar atrás do `pr-assets` — isso não é erro.

## Seletor de arquivos

Prints do picker usam a pasta neutra **`~/MangaJP-QA/`** com a fixture `test/fixtures/manga_test_page.png`. Nunca arquivo pessoal (repo público).

## Edição (2026-10-22)

O print vai **sem edição**. A única exceção é esconder dado sensível (nomes de arquivo pessoais, chaves, pastas do Finder etc.). Essa exceção **sempre** vai avisada no PR, com o motivo.

Permitido nessa exceção: **borrar** (ou cobrir a área) e **recortar**. Proibido: redimensionar, retocar, mudar a cor da área do app.

- **Padrão:** borrar ou cobrir a área — mantém **390×844** (Android) e **1280×800** (desktop). O borrão cobre **só** o dado sensível (blocos sólidos ou blur forte, ilegível).
- **Recortar** é exceção. O print recortado pode sair do tamanho padrão **só** se o PR declarar o recorte e o motivo. O gate de tamanho aceita esse print **somente** com esse aviso.
- Em qualquer caso, o que o critério de aceite pede continua **legível**.
- O `sha256` no `print_sizes.txt` é o do arquivo **final**, já editado.

O ideal continua sendo capturar já sem conteúdo sensível, com a pasta neutra `~/MangaJP-QA/` e a fixture.

Print sensível já publicado em `pr-assets`: substituir pela versão editada. Force-push na `pr-assets` precisa da **aprovação do Murilo**. Antes de qualquer push novo, todo clone faz `git fetch && git reset --hard origin/pr-assets`.

O recorte da sidebar de Favorites no `nsopenpanel.png` do #50 foi resolvido com **borrão** em 22/10.

## `integration_test` no corpo do PR

Bloco = **saída real** de um run no **head final**. Nunca escrito à mão.

Incluir a saída de `git rev-parse --short HEAD` **junto** da saída do teste, para provar que rodou nesse head.

Se o PR **não** toca `integration_test/` **nem** o fluxo que a suíte cobre, o bloco é `n/a` + **uma linha** de motivo.

Se a suíte **só roda no Mac** e o worker está desligado: `n/a: Mac offline — #54 item: <link>` — ver [Mac offline](#mac-offline-2026-10-21).

## Mac offline (2026-10-21)

Decisão do Murilo: todo trabalho roda na **nuvem** por padrão.

`integration_test` e prints de **macOS** ou **iOS** que só rodam no Mac **não bloqueiam** o PR enquanto o worker do Mac estiver desligado.

Nesse caso o bloco do PR fica:

```text
n/a: Mac offline — #54 item: <link>
```

O `<link>` aponta para um **item** na issue fila [#54](https://github.com/murilinhoPs/MangaJP/issues/54). Cada item lista PR de origem, o que rodar e o head. **Sem esse link o review bloqueia.**

Quando o worker do Mac for ligado, a fila da #54 é rodada **inteira** e o review revalida esses itens.

Prints de **Android 390×844** e **desktop Linux 1280×800** continuam obrigatórios — rodam na nuvem.

## macOS — entitlement do picker

CI **falha** se `com.apple.security.files.user-selected.read-only` sair dos `.entitlements` do macOS (`macos/Runner/DebugProfile.entitlements` e `Release.entitlements`). Sem essa key o `NSOpenPanel` não abre no Runner com sandbox.

## Layout largo (desktop)

Só aqui: telas e chrome que **não existem** no Android 390×844.

- Rail / sidebar
- Paleta **Ctrl+K** / ⌘K
- Barra flutuante, kbd `G` / `R`, grid de capturas em coluna

Prints: desktop **1280×800** (só área do app) e, quando couber, macOS 1x 1280×800 sRGB sem P3. Não misturar com o bloco Android.
