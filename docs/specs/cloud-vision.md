# Cloud Vision (F26)

Rota: `/settings` (Ajustes › OCR). Sem rota nova. Issue: [#59](https://github.com/murilinhoPs/MangaJP/issues/59). Specs ligadas: [ocr](ocr.md), [settings](settings.md), [leitor](leitor.md), [ADR-0001](../adr/0001-ocr-default-manga-ocr.md). Plano: [`m2.md`](../milestones/m2.md).

Os 7 defaults abaixo foram **aprovados** pelo dono do projeto em 2026-11-04:

1. Chave colada em Ajustes › OCR; toggle só liga com chave; armazenamento seguro do sistema; nunca Drift / backup F25 / log / print / repo; mascarada; **Testar chave** e **Remover chave**; nenhuma chave embutida.
2. Sem chave o toggle não liga. 401/403, 400 com reason `API_KEY_INVALID`, 429/`RESOURCE_EXHAUSTED`, rede fora ou timeout (15 s): aquele **crop** roda no manga-ocr com aviso não bloqueante; a chave permanece. 400 sem esse reason (e JSON malformado) vira erro inesperado, sem crash; o crop também cai no manga-ocr; a chave permanece. Se o manga-ocr daquele recorte também falha, a Captura **não** confirma; permanece na tela de crop com «OCR indisponível: Cloud Vision e manga-ocr falharam.» (`OcrBothUnavailable`).
3. Fallback automático visível **por crop**; `crops.engineId`; chip na página, estado **misto** se os crops diferirem. Schema não muda. Quando o Vision falha e o manga-ocr sucede: SnackBar não bloqueante com `fallbackMessage` no Leitor/Página.
4. Diálogo na primeira ligação fala em **recortes**; só ativa com aceite; recusar = toggle desligado e chave continua guardada; desligar = tudo local; só a imagem do recorte sai.
5. O Vision roda no **mesmo crop** que o manga-ocr (não na página inteira). Cota = 1 chamada por crop.
6. Sem keyring / secure storage: o campo da chave fica desabilitado com aviso; nada é salvo em texto puro. Web fora da F26.
7. A chave vai no header `X-Goog-Api-Key`, nunca em query string. AC: a chave nunca aparece em log.

Requisito da [#59](https://github.com/murilinhoPs/MangaJP/issues/59): adicionar `com.apple.security.network.client` no macOS (hoje ausente). Verificação: `n/a: Mac offline (#54)`.

## Objetivo

Oferecer Cloud Vision como `OcrEngine` opcional, atrás de um toggle em Ajustes. O default oficial continua **manga-ocr** (Q-B1 / ADR-0001). No GT kanji (44 crops, 530 chars): manga-ocr **20,75%** CER, Cloud Vision **44,53%** — [`m0.3-cer-bakeoff.md`](../m0.3-cer-bakeoff.md). ML Kit não entra. Filtro de ruby unofficial do Vision não é default.

O Vision **não** substitui o default: no GT o CER é o dobro do manga-ocr. Vale ligar quando o manga-ocr falha no recorte ou quando o usuário quer as boxes do Vision (F22); cada chamada é paga na cota do próprio usuário.

## Comportamento

### Motor / crop (aprovado, 2026-11-04)

Cloud Vision entra como `OcrEngine`: `DOCUMENT_TEXT_DETECTION`, `languageHints: ["ja"]`. Contrato igual aos outros: `fullText`, `blocks` (text, confidence, `Rect?`), `engineId`. Não é o default.

Roda no **mesmo crop** que o manga-ocr, depois do confirm dos recortes. **Não** envia a página inteira. Cota = **1 chamada por crop** (não por página, não em lote). O `engineId` fica em `crops.engineId` (`lib/core/database/tables/captured_crops.dart`). Schema **não** muda.

### Chave (aprovado, 2026-11-04)

O usuário cola a chave num campo em **Ajustes › OCR**. O toggle «Usar OCR na nuvem» **só liga depois que houver chave**. A chave fica no armazenamento seguro do sistema (Keychain, Keystore, libsecret no Linux). **Nunca** no Drift, no backup da F25, em log, em print ou no repo. Na UI aparece mascarada, com botão **Testar chave** e **Remover chave**. Nenhuma chave embutida no app.

Sem armazenamento seguro (Linux sem Secret Service / keyring, ou plataforma sem Keychain/Keystore/libsecret): o campo da chave fica **desabilitado** com aviso; **nada** é salvo em texto puro. A web (F33 / M3) fica **fora** da F26. Timeout de **400 ms** no plugin **não** é esse caso — a chave não é tratada como ausente. Ver **Keyring lento**.

A chave vai no header `X-Goog-Api-Key`. **Nunca** em query string (`?key=`).

**Testar chave** (HTTP mockado nos testes):

- ok — aviso de sucesso; chave permanece
- 401/403, ou 400 com reason `API_KEY_INVALID` — aviso «Chave inválida.»; chave permanece
- 400 sem `API_KEY_INVALID`, ou JSON malformado — aviso «Não foi possível falar com o Cloud Vision.»; chave permanece; não crasha
- 429 / `RESOURCE_EXHAUSTED` — aviso de cota; chave permanece
- rede fora ou timeout **15 s** — aviso; chave permanece
- timeout do keyring **400 ms** — aviso «Armazenamento seguro demorou para responder. A chave não foi apagada — tente de novo.»; chave permanece

Prints do campo usam valor fake mascarado; se algum trecho vazar, borrão declarado.

### Erros (aprovado, 2026-11-04)

- Sem chave, o toggle não liga.
- Chave inválida (401/403, ou 400 com reason `API_KEY_INVALID`), cota estourada (429 / `RESOURCE_EXHAUSTED`), rede fora ou timeout **15 s**: aquele **crop** roda no manga-ocr e aparece um aviso **não bloqueante** com o motivo. A chave **não** é apagada. Outros crops da mesma página podem ter usado Vision — o chip pode ficar **misto**. 400 sem `API_KEY_INVALID` (e JSON malformado) vira erro inesperado («Cloud Vision falhou. Recorte lido com manga-ocr.»), sem crash; o crop também cai no manga-ocr; a chave permanece.
- Se o Cloud Vision falha com fallback local e o manga-ocr daquele recorte também falha, a Captura **não** confirma o recorte (`OcrBothUnavailable`): permanece na tela de crop e mostra «OCR indisponível: Cloud Vision e manga-ocr falharam.», acima do dock (**390×844**) e acima da command bar no wide. A chave permanece. (Atualizado pelo #109, 2026-11-12.)

### Keyring lento (atualizado pelo #109, 2026-11-12)

Leitura, escrita e remoção da chave no armazenamento seguro (`FlutterCloudVisionStore`) têm timeout de **400 ms** (`pluginTimeout`). `readApiKey`, `writeApiKey` e `deleteApiKey` lançam `KeyringSlowException`. `_guard` ignora o future do plugin que completa depois do timeout (`future.ignore()`), para uma conclusão tardia (sucesso ou erro) não virar unhandled async. `MemoryCloudVisionStore` (`keyringSlow: true`) simula o caminho.

A chave **não** é tratada como ausente nem apagada. Cópia: «Armazenamento seguro demorou para responder. A chave não foi apagada — tente de novo.» (`CloudVisionLabels.keyringSlow`).

Captura: `CloudVisionOcrEngine` mapeia `KeyringSlowException` para `CloudVisionKeyringSlow` (`fallsBackToLocal: false`). Aquele crop **não** cai no manga-ocr; a Captura permanece na tela de crop com o aviso no mesmo lugar do erro de ambos os OCRs (acima do dock em **390×844**, acima da command bar no wide).

Ajustes › OCR: aviso na seção OCR; campo e toggle continuam usáveis (diferente de keyring indisponível). **Remover chave** / salvar com timeout mostram o mesmo aviso; a chave permanece; o toggle **não** desliga. Se o toggle estava ligado, `hasKey` segue `enabled` — a UI não trata a chave como ausente.

### Fallback (aprovado, 2026-11-04)

Fallback **automático por crop**, **visível**. Cada crop guarda o próprio `engineId`. Quando o Vision falha e o manga-ocr daquele recorte sucede, a Captura confirma, abre o Leitor/Página (`/pages/:id`) e mostra um SnackBar **não bloqueante** com `fallbackMessage` (ex. «Chave inválida. Recorte lido com manga-ocr.»). O chip do motor fica **manga-ocr**, ou **misto** se outros crops da mesma página tiverem usado Vision. Aparece em **390×844** e **1280×800**. O SnackBar no wide ainda sobrepõe a command bar (follow-up conhecido). O default do app continua manga-ocr; o toggle escolhe se o Cloud Vision é tentado primeiro em cada crop. (Atualizado pelo #109, 2026-11-12.)

### Privacidade (aprovado, 2026-11-04)

Na **primeira vez** que o toggle liga, um diálogo explica que a **imagem de cada recorte** vai para o Google Cloud Vision, com a chave e a cobrança do próprio usuário, e **só ativa se ele aceitar**. Se recusar: o toggle volta a desligado e a chave continua guardada. Desligar volta a ser tudo local. Só a imagem do recorte sai do aparelho; nada do Caderno nem do SRS. A página inteira (fora dos crops) **não** sobe. NF6: com o toggle desligado, nenhuma imagem sai.

Review + dict já baixado continuam offline (AC-offline / F18) mesmo com o toggle presente.

### macOS (requisito da #59)

Hoje `macos/Runner/Release.entitlements` (e DebugProfile) só têm `app-sandbox` e `files.user-selected.read-only`. Sem `com.apple.security.network.client` a chamada ao Vision no macOS falha sempre e cai no fallback. A implementação da [#59](https://github.com/murilinhoPs/MangaJP/issues/59) **adiciona** `com.apple.security.network.client` nos dois arquivos, e o job `macOS entitlements` do CI passa a exigir essa key. Verificação no Mac: print ou `n/a: Mac offline (#54)`, com item na [#54](https://github.com/murilinhoPs/MangaJP/issues/54). Este PR de docs **não** mexe no entitlement.

## Critérios de aceite

- **AC-cv-engine:** Cloud Vision implementado como `OcrEngine` (`fullText` / `blocks` / `engineId`), `DOCUMENT_TEXT_DETECTION`, `languageHints: ["ja"]`.
- **AC-cv-default:** default do app = manga-ocr (ADR-0001). Nenhum caminho de produto chama ML Kit. Filtro de ruby do Vision não é default.
- **AC-cv-crop:** Vision no mesmo crop que o manga-ocr; 1 chamada por crop; `engineId` em `crops`; schema inalterado; chip **misto** se os crops da página diferirem. (Aprovado, 2026-11-04.)
- **AC-cv-key:** chave colada em Ajustes › OCR; toggle só liga com chave; armazenamento seguro do sistema; nunca Drift / backup F25 / log / print / repo; mascarada; **Testar chave** e **Remover chave**; nenhuma chave embutida. (Aprovado, 2026-11-04.)
- **AC-cv-keyring:** sem secure storage o campo fica desabilitado com aviso; nada em texto puro; web fora da F26. (Aprovado, 2026-11-04.)
- **AC-cv-keyring-slow:** timeout **400 ms** no plugin (`FlutterCloudVisionStore.pluginTimeout`); `readApiKey` / `writeApiKey` / `deleteApiKey` lançam `KeyringSlowException`; `_guard` ignora o future tardio; `MemoryCloudVisionStore` simula o caminho. A chave não é tratada como ausente nem apagada. Cópia: «Armazenamento seguro demorou para responder. A chave não foi apagada — tente de novo.» Captura: `CloudVisionKeyringSlow` (`fallsBackToLocal: false`), aquele crop não cai no manga-ocr, fica na tela de crop com o aviso no mesmo lugar do erro de ambos os OCRs. Ajustes › OCR: aviso na seção OCR; campo e toggle continuam usáveis (diferente de keyring indisponível); Remover/salvar com timeout mostram o mesmo aviso e a chave permanece. Se o toggle estava ligado, `hasKey` segue `enabled`. (Atualizado pelo #109, 2026-11-12.)
- **AC-cv-header:** chave no header `X-Goog-Api-Key`; nunca em query string. (Aprovado, 2026-11-04.)
- **AC-cv-nolog:** testes interceptam logger e texto de erro; a chave **nunca** aparece. (Aprovado, 2026-11-04.)
- **AC-cv-errors:** sem chave o toggle não liga; 401/403, 400 com reason `API_KEY_INVALID`, 429/`RESOURCE_EXHAUSTED`, rede fora ou timeout 15 s → aquele crop no manga-ocr + aviso não bloqueante, chave permanece. 400 sem esse reason (e JSON malformado) → erro inesperado, sem crash, crop no manga-ocr, chave permanece. Se o Vision falha com fallback local e o manga-ocr daquele recorte também falha → Captura não confirma; permanece na tela de crop com «OCR indisponível: Cloud Vision e manga-ocr falharam.» (`OcrBothUnavailable`), acima do dock (**390×844**) e acima da command bar no wide; chave permanece. (Aprovado, 2026-11-04.) (Atualizado pelo #106, 2026-11-11.) (Atualizado pelo #109, 2026-11-12.)
- **AC-cv-fallback:** fallback automático visível por crop; quando o manga-ocr sucede, Captura confirma, abre o Leitor/Página e mostra SnackBar não bloqueante com `fallbackMessage` (ex. «Chave inválida. Recorte lido com manga-ocr.»); chip **manga-ocr** (ou **misto**); **390×844** e **1280×800**. O SnackBar no wide ainda sobrepõe a command bar. (Aprovado, 2026-11-04.) (Atualizado pelo #109, 2026-11-12.)
- **AC-cv-privacy:** diálogo na primeira ligação fala em recortes; só ativa com aceite; recusar = toggle desligado, chave continua; desligar = tudo local; só a imagem do recorte sai. (Aprovado, 2026-11-04.)
- **AC-cv-test-key:** **Testar chave** cobre ok, 401/403, 400 com reason `API_KEY_INVALID` («Chave inválida.»), 400 sem esse reason / JSON malformado («Não foi possível falar com o Cloud Vision.», sem crash), 429, rede fora e timeout 15 s. Timeout do keyring (400 ms) → «Armazenamento seguro demorou para responder. A chave não foi apagada — tente de novo.»; chave permanece. (Aprovado, 2026-11-04.) (Atualizado pelo #106, 2026-11-11.) (Atualizado pelo #109, 2026-11-12.)
- **AC-cv-macos-network:** a #59 adiciona `com.apple.security.network.client` (DebugProfile + Release) e o CI passa a checar essa key. Verificação no Mac: print ou `n/a: Mac offline (#54)`.
- **AC-cv-offline:** toggle Cloud não quebra review + dict offline (F18).
- **AC-cv-mock:** testes mockam o HTTP; **sem chave real** (nem de exemplo que pareça real).

## Como verificar

- Teste de domínio / widget com HTTP mockado: toggle sem chave; toggle com chave fake; **Testar chave** (ok / 401 / 400 `API_KEY_INVALID` / 400 sem esse reason / JSON malformado / 429 / sem rede / timeout 15 s / keyring lento); 401/403 no OCR; 400 `API_KEY_INVALID` no OCR; 400 sem esse reason; JSON malformado; 429; timeout 15 s; ambos os OCRs falharam (`OcrBothUnavailable`); SnackBar de fallback (`fallbackMessage`); keyring lento na Captura (`CloudVisionKeyringSlow`) e em Ajustes; timeout da chave (400 ms — `KeyringSlowException` em `readApiKey` / `writeApiKey` / `deleteApiKey`); chip de um motor e chip **misto**; diálogo de privacidade (aceitar e recusar); Remover chave; campo desabilitado sem keyring; request com `X-Goog-Api-Key` e sem `?key=`; logger e texto de erro **sem** a chave. Phone **390×844** e wide ≥900.
- Prints conforme [`print-rules.md`](../qa/print-rules.md): **390×844** (emulador ou janela Linux, pasta `android/`) e Linux **1280×800** só a área do app. Telas: toggle desligado; diálogo de privacidade; toggle ligado; chave mascarada; aviso de erro; chip do motor (e **misto**); campo desabilitado sem keyring; ambos os OCRs falharam; SnackBar de fallback; keyring lento na Captura e em Ajustes; timeout da chave. Campo da chave mascarado / fake — **nunca** chave real nem de exemplo que pareça real. Digitar a chave é fluxo de teclado: emulador Android, ou `n/a: sem emulador (#93)` com item na [#93](https://github.com/murilinhoPs/MangaJP/issues/93). macOS / iOS: print ou `n/a: Mac offline (#54)`.
- Entitlement `com.apple.security.network.client`: o PR da #59 acrescenta a key e o check do CI. Com Mac offline: `n/a: Mac offline (#54)`.
- `integration_test`: saída real no head, ou `n/a` com motivo.

Limite diário de chamadas no app: **nenhum** (decisão do dono do projeto, 2026-11-04). A cota é do Google Cloud do usuário. Q-N3 (USD/mês) permanece aberta no PRD.
