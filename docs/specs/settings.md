# Ajustes (`/settings`)

Nav card **Ajustes** (mobile) / rodapé do rail (desktop). Abre `/settings` direto — sem engrenagem no header ([ADR-0004](../adr/0004-nav-design-system.md)).

## Objetivo

Controles do motor OCR, ritmo de estudo, dicionário, backup e atribuições de licença.

## Comportamento

O PRD lista o destino e os temas, não o layout:

- OCR engine (default manga-ocr; Cloud Vision só com toggle «Usar OCR na nuvem» — F26). ML Kit não aparece.
- `new_per_day` e virada de study-day 04:00 America/Sao_Paulo (F20; default 15).
- Download / versão do dict (`jmdict.sqlite`).
- **F25 Should:** export/import backup JSON. Imagens: backup zip opcional. Limpeza manual de storage.
- Atribuições: JMdict/EDICT CC BY-SA 3.0; KANJIDIC2; Yomitan/GPL ([ADR-0002](../adr/0002-licenca-gpl-yomitan.md); NF8).
- NF6: imagens não sobem à cloud salvo o toggle Cloud OCR.
- **F30 Could:** toggle «mostrar reading na frente» (default off).
- **F31 Could:** export Anki (.apkg ou TSV).
- **F32 Could:** sync HTTP (Q-N4).

## Critérios de aceite

- Ajustes é destino do shell (F17) e abre `/settings`.
- Review + dict já baixado funcionam offline (AC-offline / F18) mesmo sem rede — o toggle Cloud não quebra isso.
- Sem ML Kit nas opções.

> Pendente: layout, ordem e copy dos controles.
> Pendente: se motores Could (F29) aparecem no picker de OCR.
> Pendente: formato do JSON de backup (F25) e se o import é round-trip.
> Pendente: Q-N4 — backend japanese-reader vivo para sync.
