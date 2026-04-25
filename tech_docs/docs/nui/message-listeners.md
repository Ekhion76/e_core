---
id: nui-message-listeners
title: "Lua -> NUI message listenerek"
sidebar_position: 3
---

# Lua -> NUI message listenerek

Ebben a frontendben ket fo `message` listener van, mindketto `window.addEventListener('message', ...)` mintaval.

## Listener inventory

| Fajl | Handler | Szurofeltetel | Fo action-ok |
|---|---|---|---|
| `src/web/src/NuiApp.svelte` | `handleMessage` | `event.data` objektum + `action` string | `INIT`, `UPDATE`, `OPEN`, `CLOSE`, `POPUP`, `WEB_OPEN`, `WEB_CLOSE` |
| `src/web/src/lib/IntegrityPanel.svelte` | `onGameMessage` | `event.data.adminInline === true` | `DIAGNOSTICS_RUN_START`, `DIAGNOSTICS_CHECKLIST_INIT`, `DIAGNOSTICS_CHECKLIST_SET`, `DIAGNOSTICS_LIVE_HINT`, `DIAGNOSTICS_LOG_SET`, `DIAGNOSTICS_APPEND`, `DIAGNOSTICS_INLINE_LOG` |

## `NuiApp.svelte` action szemantika

| Action | UI hatas |
|---|---|
| `INIT` | kezdeti locale/metadata/levels/display config hidratacio |
| `UPDATE` | `metadata` reszleges frissites (`page` vagy `hud`) |
| `OPEN` | oldal vagy HUD megnyitasa |
| `CLOSE` | oldal, HUD vagy minden panel zarasa |
| `POPUP` | idozitett szintlepes popup allapot frissites |
| `WEB_OPEN` / `WEB_CLOSE` | admin overlay nyitas/zaras |

## `IntegrityPanel.svelte` action szemantika

| Action | UI hatas |
|---|---|
| `DIAGNOSTICS_RUN_START` | inline log + status reset |
| `DIAGNOSTICS_CHECKLIST_INIT` | kezdeti checklist status feltoltes (`pending`) |
| `DIAGNOSTICS_CHECKLIST_SET` | egy adott lepes statusanak frissitese (`pass/fail/running/...`) |
| `DIAGNOSTICS_LIVE_HINT` | futasi status hint csik szovege |
| `DIAGNOSTICS_LOG_SET` | teljes naplo csere |
| `DIAGNOSTICS_APPEND` | progress naplo sorok cserelese/frissitese |
| `DIAGNOSTICS_INLINE_LOG` | append a fo naplohoz |

## Lifecycle minta

- `onMount`: listener regisztralas.
- `onDestroy` / cleanup: listener deregisztralas.

Ez jo gyakorlat NUI oldalon, mert overlay nyitas/zaras kozben nem maradnak bent duplikalt listener-ek.
