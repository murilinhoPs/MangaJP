# Home

Rota: `/home`. Nav: [ADR-0004](../adr/0004-nav-design-system.md). IA: 4 blocos (2026-10-14b). Motif de 3 blocos (2026-10-01) **supersedido**.

## Objetivo

Abrir o dia de estudo e a captura sem lista de due cards na Home.

## Comportamento

Ordem: **Fila de hoje → Continuar lendo → Capturas recentes → Ritmo da semana**. Capturas **above-the-fold** em 390×844.

1. **Fila de hoje** — CTA **Revisar** (única ação primary sólida) → `/review`. Due count. «Novos» em violet. Sem lista de flashcards.
2. **Continuar lendo** — só abre o Leitor `/pages/:id` (swipe-back normal; #46 / M1.29). Não entra em Review.
3. **Capturas recentes** — carrossel mobile / grid desktop; thumbs → `/pages/:id`. 3–6 thumbs (IA v1.2; o redesign 2026-10-14b não reitera o número). 1º tile «+ Nova da galeria» e header **Galeria +** — [galeria](galeria.md). Badges 1–3 das capturas: **neutros** (bg surface-raised, cor de texto).
4. **Ritmo da semana** — métricas. «3/7 dias» / «Revisados 42» do mock são **ilustrativos, fora de escopo**.

Coral = ação; violet = «novos». Galeria **não** é violet.

Fora de escopo do mock: data, avatar, «3/7 dias», «Revisados 42», logo, kbd 1–4.

`/pages` (lista) redireciona pra `/home` desde M1.21a (#35). Histórico F21 continua Should.

Mobile (< 900 px): 4 nav cards **Início · Caderno · Deck · Ajustes**. Desktop (≥ 900 px): rail (Biblioteca, Leitor, Revisar com badge due, Caderno, Deck, Ajustes no rodapé) + barra flutuante + paleta Ctrl+K / ⌘K. Atalhos não engolem teclas enquanto o usuário digita.

## Critérios de aceite

- Quatro blocos na ordem acima; Capturas above-the-fold em 390×844.
- **Revisar** é a única primary sólida e abre `/review`.
- **Continuar lendo** abre só o Leitor, não a Review ([ADR-0005](../adr/0005-saida-revisao.md)).
- Tile «+ Nova da galeria» / **Galeria +** / atalho `G` (desktop) → [galeria](galeria.md).
- Sem card antigo «Galeria / Escolher da galeria».
- Review não é tab. Capture não é tab.

> Pendente: qual `pages.id` o card **Continuar lendo** abre (a mais recente? última lida?).
> Pendente: métricas reais de **Ritmo da semana** (o mock é ilustrativo).
> Pendente: o rail **Biblioteca** — destino além de `/home`.
