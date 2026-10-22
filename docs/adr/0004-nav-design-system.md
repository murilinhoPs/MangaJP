# ADR-0004 — Nav do Design System

- Status: Aceita
- Data: 2026-10-08
- Questão: Q-N8

## Contexto

O PRD antigo pedia shell «Home · Páginas · Review · Caderno · Mais» com engrenagem no header. O Design System definiu outra chrome. Q-N8: seguir o PRD ou o DS? Murilo fecha: **Design System** (M1.20, PR #34).

## Decisão

A nav do shell segue o Design System.

- Mobile (< 900 px): 4 nav cards no rodapé — **Início · Caderno · Deck · Ajustes**. Ajustes abre `/settings` direto (sem engrenagem no header).
- Desktop (≥ 900 px): rail com Biblioteca, Leitor, Revisar (badge due), Caderno, Deck e Ajustes no rodapé; barra flutuante; paleta Ctrl+K / ⌘K.
- Review **não** é tab: CTA Revisar da Home, atalho `R` ou paleta.
- Telas de tarefa (`/pages/:id`, `/capture`, `/review`) escondem os nav cards e usam dock próprio.
- Capture **não** é tab (share / tile / **Galeria +**).
- `/more` sai. Lista `/pages` vira **Capturas recentes** na Home (M1.21; `/pages` redireciona).
- Atalhos não engolem teclas enquanto o usuário digita.

Substitui «Home · Páginas · Review · Caderno · Mais».

## Consequências

- Specs: [home](../specs/home.md), [settings](../specs/settings.md), [revisao](../specs/revisao.md).
- Review e Captura são rotas de tarefa, não itens do shell.
- Reabrir a nav antiga exige ADR novo.
