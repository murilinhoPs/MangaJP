# Ajustes (`/settings`)

Nav card **Ajustes** (mobile) / rodapé do rail (desktop). Abre `/settings` direto — sem engrenagem no header ([ADR-0004](../adr/0004-nav-design-system.md)).

## Objetivo

Controles do motor OCR, ritmo de estudo, dicionário, backup e atribuições de licença.

## Comportamento

O PRD lista o destino e os temas, não o layout:

- OCR engine (default manga-ocr; Cloud Vision só com toggle «Usar OCR na nuvem» — F26 / [cloud-vision](cloud-vision.md)). Campo da chave em Ajustes › OCR, mascarada, **Testar chave** / **Remover chave**; toggle só liga com chave. Sem keyring o campo fica desabilitado. ML Kit não aparece. Defaults aprovados em 2026-11-04; implementação na [#59](https://github.com/murilinhoPs/MangaJP/issues/59).
- `new_per_day` e virada de study-day 04:00 America/Sao_Paulo (F20; default 15).
- Download / versão do dict (`jmdict.sqlite`).
- **F25 Should:** export/import backup JSON em Ajustes › Backup (**Exportar JSON** / **Restaurar JSON**). Comportamento, formato e ACs: [backup](backup.md). Um arquivo JSON com `format_version` (2; ainda aceita 1) e `schema_version` (Drift, hoje 10). Restore **substitui** Caderno + SRS + `saved_kanji` depois de confirmação; `crop_words` só volta se o crop ainda existe. Zip de imagens opcional e separado; **sem** export SQLite nesta entrega (Q6/Q7 fechadas). Limpeza manual de storage: pendente.
- Atribuições (seção Sobre / Fontes **dentro de `/settings`**, sem rota nova, NF8): JMdict/EDICT CC BY-SA 3.0; **KANJIDIC2 © EDRDG, [CC BY-SA 4.0](https://www.edrdg.org/wiki/index.php/KANJIDIC_Project)**; Yomitan/GPL ([ADR-0002](../adr/0002-licenca-gpl-yomitan.md)).
- NF6: imagens não sobem à cloud salvo o toggle Cloud OCR.
- **F30 Could:** toggle «mostrar reading na frente» (default off).
- **F31 Could:** export Anki (.apkg ou TSV).
- **F32 Could:** sync HTTP (Q-N4).

## Critérios de aceite

- Ajustes é destino do shell (F17) e abre `/settings`.
- Review + dict já baixado funcionam offline (AC-offline / F18) mesmo sem rede — o toggle Cloud não quebra isso.
- Sem ML Kit nas opções.
- **AC-kanjidic-attr:** a seção Sobre / Fontes **dentro de `/settings`** (sem rota nova) mostra «KANJIDIC2 © EDRDG, CC BY-SA 4.0» com link para https://www.edrdg.org/wiki/index.php/KANJIDIC_Project. Entregue no [#118](https://github.com/murilinhoPs/MangaJP/pull/118).
- ACs de backup (export, round-trip, `crop_words`, schema antigo, `origin_page_id`, recusa, atômico, `normalizeKanjiLiteral`): [backup](backup.md).

> Pendente: layout, ordem e copy dos controles além de Backup / Sobre / Fontes / OCR.
> Pendente: se motores Could (F29) aparecem no picker de OCR.
> Pendente: limpeza manual de storage.
> Pendente: Q-N4 — backend japanese-reader vivo para sync.
