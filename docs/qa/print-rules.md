# Regras de print

Prints de QA **não** entram em `docs/assets/`. Vão para a branch `pr-assets`:

```text
docs/pr-assets/pr-N/<head>/<plataforma>/
```

Branch `pr-assets`. `N` = número do PR. `<head>` = SHA-1 **curto** do **head final** do PR. `<plataforma>` = `android` | `ios` | `desktop` | `macos`. A print de celular vai **sempre** em `android/`, venha do emulador ou da janela Linux. `linux/` e `desktop/` o `gen_telas` trata como desktop (`tool/telas/telas_index.dart`): uma 390×844 nessas pastas sai **fora da regra**.

`docs/assets/` no `main` só recebe prints **oficiais e finais**.

## Quando é obrigatório

Todo PR que mexe em **design, telas ou tema** precisa de print nos tamanhos da regra no corpo do PR.

Obrigatórios na **nuvem** (todo PR que mexe em tela): **390×844** (retrato, sem hover) e **desktop Linux 1280×800**. Widget/golden sozinho **não conta**. Sem esses dois o PR **não** é squash-mergeado. A print **390×844** pode vir do emulador Android ou de uma janela Linux redimensionada — [emulador Android (2026-11-03)](#emulador-android-2026-11-03).

Prints e `integration_test` que **só rodam no Mac** (macOS / iOS): ver [Mac offline](#mac-offline-2026-10-21).

`<head>` no caminho e no `print_sizes.txt` é sempre o **head final** do PR. Print de head antigo não vale: se o head mudar, refazer.

## Tamanho e recorte (obrigatório)

| Plataforma | Tamanho | Recorte |
| --- | --- | --- |
| **Android** | **obrigatório 390×844** lógico, retrato, **sem hover** | 390×844 lógico; o PNG pode ser 390×844 ou múltiplo inteiro exato (ex.: 780×1688 em DPR 2), só a área do app, sem moldura nem title bar — emulador Android **ou** janela Linux redimensionada, pasta `android/` |
| **Desktop Linux** | **obrigatório 1280×800** | **só a área do app** — sem moldura de janela, sem title bar; cantos opacos |
| **macOS** | **obrigatório 1x 1280×800**, sRGB, **sem** perfil Display P3 | **só a área do app** — sem moldura de janela, sem title bar; cantos opacos |
| **iOS** | simulador **iPhone 17**, qualquer resolução | retrato |

**390×844** (emulador ou janela Linux, pasta `android/`) e desktop Linux 1280×800 **não** são opcionais (nuvem). Formato macOS (1x 1280×800 sRGB sem P3) vale **quando** o print macOS é capturado; se o worker do Mac estiver desligado, ver [Mac offline](#mac-offline-2026-10-21).

**iOS (Murilo, 13/10):** prints de iOS podem vir do simulador do **iPhone 17**, em **qualquer resolução**. Os prints **obrigatórios** continuam sendo o **390×844** em retrato (emulador ou janela Linux, pasta `android/`) e o **Linux desktop 1280×800**, sem moldura nem barra de título. Continuam valendo: SHA-1 completo (40 caracteres) no `print_sizes.txt`; nada de arquivo pessoal; com Mac offline, `n/a: Mac offline (#54)` ([Mac offline](#mac-offline-2026-10-21)).

Telas que **só existem no layout largo** (sidebar, paleta Ctrl+K, rail) **não** vão no bloco Android. Ver a seção no fim.

## Emulador Android (2026-11-03)

Decisão do dono do projeto.

O layout de celular vs. tela larga depende só da largura: `ShellLayout.isWide` é verdadeiro quando a largura é ≥ 900 (`AppBreakpoints.wide`). A print de layout em formato celular (**390×844** lógico, retrato, **sem hover**) pode vir do emulador Android **ou** de uma janela Linux desktop redimensionada. Não é obrigatório que venha da tela do emulador.

**390×844 lógico;** o PNG pode ser 390×844 ou múltiplo inteiro exato (ex.: 780×1688 em DPR 2), só a área do app, sem moldura nem title bar. O `gen_telas` aceita `largura = 390×n` e `altura = 844×n` com o mesmo inteiro `n ≥ 1` (`androidDimensionsOk`). Na janela Linux: redimensionar até a área do app ter 390×844 lógicos e capturar só essa área; se a captura for DPR 2, o PNG sai 780×1688 — o `print_sizes.txt` registra os pixels do arquivo.

A print de celular vai sempre em `android/`, venha do emulador ou da janela Linux. `linux/` conta como desktop. Quando a origem for a janela Linux, o corpo do PR registra `fonte: janela Linux` — não é aparelho Android.

A janela Linux **não** cobre: status bar, safe area, teclado na tela, voltar do sistema, share vindo de outro app, galeria e câmera.

Rodar no emulador Android é **obrigatório** quando o PR:

1. mexe em fluxo de plataforma (share, galeria, voltar, câmera, teclado, status bar/safe area); ou
2. traz um ajuste maior de UI/UX.

> Pendente: o que conta como «ajuste maior de UI/UX». Default proposto, aguardando confirmação do dono do projeto: mudança na navegação principal (nav bar/rail, rotas raiz) ou fluxo novo que dependa de comportamento do sistema; tela ou aba nova dentro de uma área existente não conta. O [#88](https://github.com/murilinhoPs/MangaJP/pull/88) (aba Kanji nova no Caderno + ficha de kanji) fica só com a janela Linux.

Se o PR precisa do emulador e a VM não tem, o bloco do PR é:

```text
n/a: sem emulador (#93)
```

O item (PR, head, fluxo) vai como comentário na fila [#93](https://github.com/murilinhoPs/MangaJP/issues/93) (mesmo papel da [#54](https://github.com/murilinhoPs/MangaJP/issues/54) para o Mac). No corpo do PR a linha é `n/a: sem emulador (#93)`; o **link do comentário é opcional**. **Sem o comentário na #93 o review bloqueia** em fluxo de plataforma. A print 390×844 da janela Linux **continua obrigatória**. Este `n/a` **bloqueia o merge** em fluxo de plataforma e **não bloqueia** em ajuste maior de UI/UX.

macOS / iOS: `n/a: Mac offline (#54)` — [Mac offline (2026-10-21)](#mac-offline-2026-10-21).

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
- **Recortar** é exceção. O print recortado pode sair do tamanho padrão **só** se o PR declarar o recorte e o motivo **e** a linha do `print_sizes.txt` tiver o token `recorte` ou `recorte=<motivo>` (`<motivo>` opcional). Sem o token, `gen_telas` marca o print **fora da regra** em [`telas.md`](telas.md). O parser só aceita o token exato `recorte` ou um token que começa com `recorte=`; variações (`recortex`) não contam. O token entra na linha do print, depois de `<largura>x<altura>`, separado por espaço — o mesmo resto da linha que aceita `coral=` / `sha256:`.

  ```text
  macos/nsopenpanel.png 900x800 recorte=sidebar-Finder sha256:3251d918bc0e257eb5a7ff85207547052a05a1d55c034ed1aeb50ce3ded39a17
  ```
- Em qualquer caso, o que o critério de aceite pede continua **legível**.
- O `sha256` no `print_sizes.txt` é o do arquivo **final**, já editado.

O ideal continua sendo capturar já sem conteúdo sensível, com a pasta neutra `~/MangaJP-QA/` e a fixture.

Print sensível já publicado em `pr-assets`: substituir pela versão editada. Force-push na `pr-assets` precisa da **aprovação do Murilo**. Antes de qualquer push novo, todo clone faz `git fetch && git reset --hard origin/pr-assets`.

O recorte da sidebar de Favorites no `nsopenpanel.png` do #50 foi resolvido com **borrão** em 22/10.

## `integration_test` no corpo do PR

Bloco = **saída real** de um run no **head final**. Nunca escrito à mão.

Incluir a saída de `git rev-parse --short HEAD` **junto** da saída do teste, para provar que rodou nesse head.

Se o PR **não** toca `integration_test/` **nem** o fluxo que a suíte cobre, o bloco é `n/a` + **uma linha** de motivo.

Se a suíte **só roda no Mac** e o worker está desligado: `n/a: Mac offline (#54)` — ver [Mac offline](#mac-offline-2026-10-21).

## Mac offline (2026-10-21)

Decisão do Murilo: todo trabalho roda na **nuvem** por padrão.

`integration_test` e prints de **macOS** ou **iOS** que só rodam no Mac **não bloqueiam** o PR enquanto o worker do Mac estiver desligado.

Nesse caso o bloco do PR fica:

```text
n/a: Mac offline (#54)
```

O item (PR, o que rodar, head) vai como comentário na fila [#54](https://github.com/murilinhoPs/MangaJP/issues/54). **Sem o comentário na #54 o review bloqueia.**

Quando o worker do Mac for ligado, a fila da #54 é rodada **inteira** e o review revalida esses itens.

Prints de **390×844** (emulador ou janela Linux, pasta `android/`) e **desktop Linux 1280×800** continuam obrigatórios — rodam na nuvem.

## macOS — entitlement do picker

CI **falha** se `com.apple.security.files.user-selected.read-only` sair dos `.entitlements` do macOS (`macos/Runner/DebugProfile.entitlements` e `Release.entitlements`). Sem essa key o `NSOpenPanel` não abre no Runner com sandbox.

## Bundle ID

Fonte: [convenções em `docs/README.md`](../README.md#convenções). Bundle ID / `applicationId` é **`dev.murilinhops.mangajp`** em todas as plataformas — Android, iOS, macOS, Linux (Murilo, 22/10). Linux alinhado no [#66](https://github.com/murilinhoPs/MangaJP/pull/66), com migração da pasta de dados antiga.

## Layout largo (desktop)

Só aqui: telas e chrome que **não existem** no Android 390×844.

- Rail / sidebar
- Paleta **Ctrl+K** / ⌘K
- Barra flutuante, kbd `G` / `R`, grid de capturas em coluna

Prints: desktop **1280×800** (só área do app) e, quando couber, macOS 1x 1280×800 sRGB sem P3. Não misturar com o bloco Android.
