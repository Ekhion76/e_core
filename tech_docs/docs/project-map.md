---
id: project-map
title: "Project Map (Nexus AI)"
sidebar_position: 2
---

# Project Map a Nexus AI szamara

Ez a technikai terkep azt mutatja, hogyan kommunikal az e_core Lua oldala a Svelte frontenddel.

## 1) High-level kommunikacios modell

Az adatut nem kozvetlenul `server.lua -> Svelte`, hanem tobb lepcsobol all:

1. **Server Lua** kuld kliens net eventet (`TriggerClientEvent`).
2. **Client Lua** fogadja a net eventet, majd NUI uzenetet kuld (`SendNUIMessage`).
3. **Svelte frontend** `window.addEventListener('message', ...)` listenerrel feldolgozza az actiont.

Visszafele:

1. **Svelte** `fetch("https://${resourceName}/{callbackName}")` hivassal NUI callbacket triggerel.
2. **Client Lua** `RegisterNUICallback(...)` fogadja.
3. Szukseg szerint **Client Lua -> Server Lua** (`TriggerServerEvent`), majd **Server Lua -> Client Lua** valasz event.

## 2) Lua -> Svelte (NUI message action nevek)

### Altalanos UI actionok (`NuiApp.svelte` kezeli)

| Action | Ki kuldi | Hol | Jelentes |
|---|---|---|---|
| `INIT` | Client Lua | `src/client/main.lua` | Kezdeti hydrate (`metadata`, `levels`, `locale`, limitek, display config). |
| `OPEN` | Client Lua | `src/client/main.lua` | UI panel nyitas (`subject`: `page` vagy `hud`). |
| `CLOSE` | Client Lua | `src/client/main.lua` | UI panel zaras (`subject`: `page`/`hud`/`all`). |
| `UPDATE` | Client Lua | `src/client/main.lua` | Meta adat frissites (`subject`: `page` vagy `hud`). |
| `POPUP` | Client Lua | `src/client/main.lua` | Level-up popup adat. |
| `WEB_OPEN` | Client Lua | `src/client/web.lua` | Admin overlay megnyitasa. |
| `WEB_CLOSE` | Client Lua | `src/client/web.lua` | Admin overlay bezarasa. |

### Diagnostics/Integrity actionok (`IntegrityPanel.svelte` kezeli)

| Action | Ki kuldi | Hol | Jelentes |
|---|---|---|---|
| `DIAGNOSTICS_RUN_START` | Client Lua | `src/client/integrity_check.lua` (net push) | Inline diagnostics futas indul. |
| `DIAGNOSTICS_CHECKLIST_INIT` | Client Lua | `src/client/integrity_check.lua` (net push) | Checklist inicializalas. |
| `DIAGNOSTICS_CHECKLIST_SET` | Client Lua | `src/client/integrity_check.lua` | Lepes status frissites (`running/ok/fail/cancelled`). |
| `DIAGNOSTICS_LIVE_HINT` | Client Lua | `src/client/integrity_check.lua` | Elo status hint szoveg. |
| `DIAGNOSTICS_LOG_SET` | Client Lua | `src/client/integrity_check.lua` (net push) | Teljes naplo csere. |
| `DIAGNOSTICS_APPEND` | Client Lua | `src/client/integrity_check.lua` | Progress naplo frissites. |
| `DIAGNOSTICS_INLINE_LOG` | Client Lua | `src/client/integrity_check.lua` | Inline naplo append. |
| `DIAGNOSTICS_CLOSE` | Client Lua | `src/client/integrity_check.lua` | Diagnostics UI bezaras. |

## 3) Server-Client net event nevek (NUI-hoz kapcsolodo)

### Admin web konzol nyitas

| Irany | Event nev | Hol |
|---|---|---|
| Client -> Server | `e_core:web:requestOpen` | `src/client/web.lua` -> `src/server/web.lua` |
| Server -> Client | `e_core:web:open` | `src/server/web.lua` -> `src/client/web.lua` |
| Server -> Client | `e_core:web:deny` | `src/server/web.lua` -> `src/client/web.lua` |

### Admin RPC (professions/level profiles)

| Irany | Event nev | Hol |
|---|---|---|
| Client -> Server | `e_core:nuiAdminRpc` | `src/client/nui_admin_bridge.lua` -> `src/server/nui_admin_bridge.lua` |
| Server -> Client | `e_core:nuiAdminRpcResult` | `src/server/nui_admin_bridge.lua` -> `src/client/nui_admin_bridge.lua` |

### Diagnostics RPC

| Irany | Event nev | Hol |
|---|---|---|
| Client -> Server | `e_core:nuiDiagnosticsRpc` | `src/client/nui_diagnostics_bridge.lua` -> `src/server/nui_diagnostics_bridge.lua` |
| Server -> Client | `e_core:nuiDiagnosticsRpcResult` | `src/server/nui_diagnostics_bridge.lua` -> `src/client/nui_diagnostics_bridge.lua` |

### Meta/integritas feed (NUI-re hat)

| Irany | Event nev | Hol | NUI-hatas |
|---|---|---|---|
| Server -> Client | `e_core:sync` | `src/server/meta.lua`/`src/server/db.lua` -> `src/client/main.lua` | `INIT`/`UPDATE` message path |
| Server -> Client | `e_core:levelChange` | `src/libs/meta.lua` -> `src/client/main.lua` | `POPUP` message |
| Server -> Client | `e_core:integrityCheck:nuiPush` | `src/server/integrity_check.lua` -> `src/client/integrity_check.lua` | diagnostics actionok tovabbitasa NUI fele |
| Server -> Client | `e_core:integrityCheck:clientPrint` | `src/server/integrity_check.lua` -> `src/client/integrity_check.lua` | diagnostics log actionok |
| Server -> Client | `e_core:integrityCheck:progressTest` | `src/server/integrity_check.lua` -> `src/client/integrity_check.lua` | progress status actionok |

## 4) Svelte -> Lua NUI callback endpointok (fetch utvonalak)

| NUI callback nev | Honnan jon | Client oldali handler | Tovabbitas |
|---|---|---|---|
| `nuiReady` | `NuiApp.svelte` (`postNui('nuiReady')`) | `src/client/main.lua` | NUI readiness jelzes |
| `exit` | `NuiApp.svelte` (`postNui('exit')`) | `src/client/main.lua` | stat UI bezaras |
| `webAdminExit` | `AdminConsole` close (`postNui('webAdminExit')`) | `src/client/web.lua` | `WEB_CLOSE` |
| `eCoreAdminApi` | `src/web/src/lib/registry.ts` | `src/client/nui_admin_bridge.lua` | `e_core:nuiAdminRpc` szerver RPC |
| `eCoreDiagnosticsApi` | `src/web/src/lib/diagnostics.ts` | `src/client/nui_diagnostics_bridge.lua` | `e_core:nuiDiagnosticsRpc` szerver RPC |
| `integrityDiagnosticsRun` | `IntegrityPanel.svelte` | `src/client/integrity_check.lua` | `e_core:integrityCheck:request` szerver futtatas |
| `diagnosticsExit` | diagnostics close flow | `src/client/integrity_check.lua` | `DIAGNOSTICS_CLOSE` |

## 5) Gyors mentális modell Nexus AI-nak

- **UI allapot action-orientalt:** a Svelte oldal action stringeket fogad (`INIT`, `UPDATE`, `OPEN`, ...).
- **Server never talks directly to DOM:** mindig net event -> client bridge -> `SendNUIMessage`.
- **Admin API ket csatornan fut:** `eCoreAdminApi` (registry) es `eCoreDiagnosticsApi` (diagnostics).
- **Request/response minta:** NUI callback -> client pending map/requestId -> server -> result event -> callback resolve.
