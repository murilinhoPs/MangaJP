# Ajustes (`/settings`)

Nav card **Ajustes** (mobile) / rodapé do rail (desktop). Abre `/settings` direto — sem engrenagem no header ([ADR-0004](../adr/0004-nav-design-system.md)).

## Objetivo

Controles do motor OCR, ritmo de estudo, dicionário, backup e atribuições de licença.

## Comportamento

O PRD lista o destino e os temas, não o layout:

- OCR engine (default manga-ocr; Cloud Vision só com toggle «Usar OCR na nuvem» — F26 / [cloud-vision](cloud-vision.md)). Campo da chave em Ajustes › OCR, mascarada, **Testar chave** / **Remover chave**; toggle só liga com chave. Sem keyring o campo fica desabilitado. ML Kit não aparece. Defaults aprovados em 2026-11-04; implementação na [#59](https://github.com/murilinhoPs/MangaJP/issues/59).
- `new_per_day` e virada de study-day 04:00 America/Sao_Paulo (F20; default 15).
- Download / versão do dict (`jmdict.sqlite`).
- **F25 Should:** export/import backup JSON em Ajustes › Backup. Um arquivo JSON com `format_version` (2; ainda aceita 1) e `schema_version` (Drift, hoje 10) e as tabelas do Caderno + SRS + `saved_kanji` + `crop_words`. Restore **substitui** Caderno + SRS + `saved_kanji` depois de confirmação e re-insere `crop_words` só se o crop ainda existe. Zip de imagens opcional e separado; **sem** export SQLite nesta entrega (Q6/Q7: defaults do [`m2.md`](../milestones/m2.md)). Limpeza manual de storage.
- Atribuições (seção Sobre / Fontes **dentro de `/settings`**, sem rota nova, NF8): JMdict/EDICT CC BY-SA 3.0; **KANJIDIC2 © EDRDG, [CC BY-SA 4.0](https://www.edrdg.org/wiki/index.php/KANJIDIC_Project)**; Yomitan/GPL ([ADR-0002](../adr/0002-licenca-gpl-yomitan.md)).
- NF6: imagens não sobem à cloud salvo o toggle Cloud OCR.
- **F30 Could:** toggle «mostrar reading na frente» (default off).
- **F31 Could:** export Anki (.apkg ou TSV).
- **F32 Could:** sync HTTP (Q-N4).

## Critérios de aceite

- Ajustes é destino do shell (F17) e abre `/settings`.
- Review + dict já baixado funcionam offline (AC-offline / F18) mesmo sem rede — o toggle Cloud não quebra isso.
- Sem ML Kit nas opções.
- **AC-kanjidic-attr:** a seção Sobre / Fontes **dentro de `/settings`** (sem rota nova) mostra «KANJIDIC2 © EDRDG, CC BY-SA 4.0» com link para https://www.edrdg.org/wiki/index.php/KANJIDIC_Project. Dono na M2: PR da F25.
- **AC-backup-export:** exportar produz um JSON que declara `format_version` e `schema_version` e contém Caderno + SRS + `saved_kanji` (vazio se não houver kanji salvo) + `crop_words` (vazio se não houver vínculo).
- **AC-backup-roundtrip:** restaurar um backup da versão corrente devolve as mesmas palavras, cards/SRS, kanji salvos e `crop_words` cujo crop ainda existe. Restore **substitui** (Q7 default).
- **AC-backup-old-schema:** restaurar um backup de schema anterior (ex. schema 8, sem `saved_kanji`) conclui; Caderno + SRS voltam; a aba Kanji fica vazia.
- **AC-backup-origin-page:** kanji com `origin_page_id` null, ou apontando para página inexistente, entra em `saved_kanji` com `origin_page_id` null.
- **AC-backup-unknown-schema:** schema desconhecido ou mais novo, ou `format_version` que o app não conhece, é recusado com mensagem; nada é gravado.
- **AC-backup-atomic:** restore do backup JSON é atômico (uma transação Drift); se falhar, nada é gravado. (F25 / M2)
- **AC-backup-normalize:** cada `literal` de `saved_kanji` passa por `normalizeKanjiLiteral`; inválido não entra, com contagem. (F25 / M2)

> Pendente: layout, ordem e copy dos controles além de Backup / Sobre / Fontes / OCR.
> Pendente: se motores Could (F29) aparecem no picker de OCR.
> Pendente: Q-N4 — backend japanese-reader vivo para sync.
