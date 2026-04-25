---
id: nui-overview
title: "NUI attekintes (Svelte + TS)"
sidebar_position: 1
---

# NUI attekintes (Svelte + TS)

## Fontos kontextus

A runtime NUI build a `src/web/dist/` alatt van, a tenyleges Svelte + TypeScript forraskod a `src/web/src/` alatt talalhato.

## Fo epitesi blokkok

- **Entry point:** `src/web/src/main.ts` -> `NuiApp.svelte` mount.
- **Fo NUI kontroller:** `src/web/src/NuiApp.svelte`.
- **Admin alrendszer:** `src/web/src/AdminConsole.svelte` + `src/web/src/lib/*Panel.svelte`.
- **NUI transport helper:** `src/web/src/lib/nui.ts` (`postNui`, `getResourceName`).

## Dokumentacios oldalak

- [Store felepites](./stores-architecture)
- [Lua -> NUI message listenerek](./message-listeners)
- [TypeScript interface es tipus referencia](./typescript-interfaces)

## Adataramlas roviden

1. Lua kuld UI uzenetet (`SendNUIMessage`) -> browser `message` event.
2. `NuiApp.svelte` es `IntegrityPanel.svelte` fogadja es feldolgozza az uzenetet.
3. Komponens-szintu Svelte 5 rune allapot (`$state`, `$derived`, `$effect`) frissul.
4. UI callbackok a `postNui(...)` helperen keresztul mennek vissza Lua fele.
