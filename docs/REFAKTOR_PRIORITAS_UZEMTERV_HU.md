# e_core – refaktor és modernizáció üzemterv (rögzített prioritás)

A sorrend a **kockázat / függőség** alapján van felállítva. Állapot: jelölés frissíthető PR-ekkel.

| # | Terület | Rövid leírás | Állapot |
|---|---------|----------------|---------|
| **A** | Keretrendszer-config egy belépési pont | `bridge/framework_config.lua`, ConVar `e_core:framework`, explicit 0/2 core; `ESX_CORE` / `QB_CORE` = választott ág | **Kész** – `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md` |
| **B** | Publikus API szerződés | `docs/PUBLIC_API_HU.md` v0.3 (+ `eCoreErr` / `eCore.Err`); deprec szabály | **Kész** (opcionális: `PUBLIC_API.json`) |
| **C** | Item registry indulás | Timeout, `isReady` export, ConVarok | Kész (`libs/helper.lua`, `server/main.lua`, `client/main.lua`) |
| **D** | Inventory / adapter | `docs/SUPPORTED_STACK_MATRIX_HU.md` + `libs/errors.lua` (`eCoreErr`, `eCore.Err`) | **Kész** |
| **E** | Meta / DB / labor | `server/labor.lua` refaktor (guard, syncRequest), kliens `getLabor` védelem; **labor tick:** online lista (`GetPlayers`) + opc. `e_core:labor_tick_chunk` | **Kész** |
| **F** | DX (lint, annotáció, CI) | LuaLS + luacheck + GHA; **maradék:** `scripts/validate_fxmanifest.py` a CI-ben (útvonalak / glob) | **Kész** (stub / luacheck további szigorítás opcionális) |
| **G** | Biztonság / net események | `docs/NET_EVENTS_AUDIT_HU.md`, loadMeta limit, playerLoaded AddEventHandler, createVehicle net eltávolítva | **Kész** (ACE / további audit opcionális) |

## Első kódrefaktor (A) célja

- Egy helyen dől el: **melyik** legacy core az aktív.
- **Két core + `auto`:** indulás **megáll** (`error`), üzenet a ConVar beállítására.
- **Két core + kényszerített `esx` / `qb`:** csak a választott ág bridge kódja tekinthető aktívnak (`ESX_CORE` / `QB_CORE`).

## Kapcsolódó dokumentumok

- Architektúra és SDK elv: `docs/MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md`
- Framework részletek és item registry ConVarok: `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md`
- Publikus API + eCore névsor: `docs/PUBLIC_API_HU.md`
- Stack mátrix: `docs/SUPPORTED_STACK_MATRIX_HU.md`
- Net audit: `docs/NET_EVENTS_AUDIT_HU.md`
