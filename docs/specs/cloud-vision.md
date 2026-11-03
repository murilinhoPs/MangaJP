# Cloud Vision (F26)

Rota: `/settings` (Ajustes › OCR). Sem rota nova. Issue: [#59](https://github.com/murilinhoPs/MangaJP/issues/59). Specs ligadas: [ocr](ocr.md), [settings](settings.md), [leitor](leitor.md), [ADR-0001](../adr/0001-ocr-default-manga-ocr.md). Plano: [`m2.md`](../milestones/m2.md).

Os defaults abaixo são **propostos**, para o dono do projeto confirmar neste PR. Não são decisão até o ok.

## Objetivo

Oferecer Cloud Vision como `OcrEngine` opcional, atrás de um toggle em Ajustes. O default oficial continua **manga-ocr** (Q-B1 / ADR-0001). No GT kanji (44 crops, 530 chars): manga-ocr **20,75%** CER, Cloud Vision **44,53%** — [`m0.3-cer-bakeoff.md`](../m0.3-cer-bakeoff.md). ML Kit não entra. Filtro de ruby unofficial do Vision não é default.

## Comportamento

### Motor

Cloud Vision entra como `OcrEngine`: `DOCUMENT_TEXT_DETECTION`, `languageHints: ["ja"]`. Contrato igual aos outros: `fullText`, `blocks` (text, confidence, `Rect?`), `engineId`. Não é o default.

### Chave (default proposto)

O usuário cola a chave num campo em **Ajustes › OCR**. O toggle «Usar OCR na nuvem» **só liga depois que houver chave**. A chave fica no armazenamento seguro do sistema (Keychain, Keystore, libsecret no Linux). **Nunca** no Drift, no backup da F25, em log, em print ou no repo. Na UI aparece mascarada, com botão **Testar chave** e **Remover chave**. Nenhuma chave embutida no app. Prints do campo usam valor fake mascarado; se algum trecho vazar, borrão declarado.

### Erros (default proposto)

- Sem chave, o toggle não liga.
- Chave inválida (401/403), cota estourada (429 / `RESOURCE_EXHAUSTED`), rede fora ou timeout: a página **roda no manga-ocr** e aparece um aviso **não bloqueante** com o motivo. A chave **não** é apagada.

### Fallback (default proposto)

Fallback **automático** para manga-ocr, **visível**. A página guarda e mostra num chip qual motor fez o OCR. O default do app continua manga-ocr; o toggle escolhe se o Cloud Vision é tentado primeiro.

### Privacidade (default proposto)

Na **primeira vez** que o toggle liga, um diálogo explica que a imagem da página vai para o Google Cloud Vision, com a chave e a cobrança do próprio usuário, e **só ativa se ele aceitar**. Desligar volta a ser tudo local. Só a imagem da página sai do aparelho; nada do Caderno nem do SRS. NF6: com o toggle desligado, nenhuma imagem sai.

Review + dict já baixado continuam offline (AC-offline / F18) mesmo com o toggle presente.

## Critérios de aceite

- **AC-cv-engine:** Cloud Vision implementado como `OcrEngine` (`fullText` / `blocks` / `engineId`), `DOCUMENT_TEXT_DETECTION`, `languageHints: ["ja"]`.
- **AC-cv-default:** default do app = manga-ocr (ADR-0001). Nenhum caminho de produto chama ML Kit. Filtro de ruby do Vision não é default.
- **AC-cv-key:** chave colada em Ajustes › OCR; toggle só liga com chave; armazenamento seguro do sistema; nunca Drift / backup F25 / log / print / repo; mascarada; **Testar chave** e **Remover chave**; nenhuma chave embutida. (Default proposto.)
- **AC-cv-errors:** sem chave o toggle não liga; 401/403, 429/`RESOURCE_EXHAUSTED`, rede fora ou timeout → manga-ocr + aviso não bloqueante, chave permanece. (Default proposto.)
- **AC-cv-fallback:** fallback automático visível para manga-ocr; a página guarda e mostra o motor num chip. (Default proposto.)
- **AC-cv-privacy:** diálogo na primeira ligação; só ativa com aceite; desligar = tudo local; só a imagem da página sai. (Default proposto.)
- **AC-cv-offline:** toggle Cloud não quebra review + dict offline (F18).
- **AC-cv-mock:** testes mockam o HTTP; **sem chave real** (nem de exemplo que pareça real).

## Como verificar

- Teste de domínio / widget com HTTP mockado: toggle sem chave; toggle com chave fake; 401/403; 429; timeout; chip do motor; diálogo de privacidade; Remover chave. Phone **390×844** e wide ≥900.
- Prints conforme [`print-rules.md`](../qa/print-rules.md): **390×844** (emulador ou janela Linux, pasta `android/`) e Linux **1280×800** só a área do app. Telas: toggle desligado; diálogo de privacidade; toggle ligado; chave mascarada; aviso de erro; chip do motor na página. Campo da chave mascarado / fake — **nunca** chave real nem de exemplo que pareça real. Digitar a chave é fluxo de teclado: emulador Android, ou `n/a: sem emulador (#93)` com item na [#93](https://github.com/murilinhoPs/MangaJP/issues/93). macOS / iOS: print ou `n/a: Mac offline (#54)`.
- `integration_test`: saída real no head, ou `n/a` com motivo.

> Pendente: limite diário de chamadas no app. Default proposto: nenhum; a cota é do Google. Q-N3 (USD/mês) permanece aberta no PRD.
> Pendente: Cloud Vision roda por página ou em lote. Default proposto: por página, sob demanda.
