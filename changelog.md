# Changelog

A projekt új fázist kezd: a korábbi verziós napló helyett innen a **kiadás szerinti** rövid összegzés. Breaking változásnál emeld a `fxmanifest.lua` `version` mezőjét, és frissítsd a `docs/PUBLIC_API_HU.md` + `export_examples_*.md` fájlokat, ahol kell.

## [0.1.0]

- Dokumentáció: belső munkanaplók és lezárt tervdokik eltávolítva; belépési pont: `docs/INDEX_HU.md`. A teljes Docusaurus fa helyett `tech_docs/README.md` helykitöltő. `fxmanifest` verzió **0.1.0** (új fázis jelzés; nem kötelező semver-folytonosság a korábbi 0.0.x-szel).

## [Unreleased]

- **HUD DnD (hibrid proxy):** új kliens-szerver alapok a per-player HUD layout mentéshez (`hudLayout` meta kulcs, normalizált `x,y,w,h` + `anchor`, rate-limited `e_core:hud:commit`).
- **Új kliens exportok:** `registerHudElement`, `unregisterHudElement` (consumer HUD elemek regisztrációja az e_core edit/sync réteghez).
- **Edit mode NUI réteg:** Svelte 5 ghost layer + throttled preview callback (`hudPreview`), pointer-trap szabály (`ghost layer: pointer-events: all`, háttér: `none`), fókusz guard `openMeta` / admin web útvonalon.
- **Import helper frissítés:** `src/imports/core.lua` most automatikusan továbbítja az `e_core:hud:clientPreview` eseményt `ECORE_HUD_SYNC` NUI üzenetté a regisztrált elemekre.

- **Keretrendszer:** `src/bridge/framework_config.lua` újraírva (egyszerű ágak). ConVar: `e_core:framework_resource` – üres = nincs override; csak **kényszerített** `esx`|`qb` mellett írja felül az alap resource nevet; `auto` + nem üres override → figyelmen kívül + log. **`e_core:esx_resource` / `e_core:qb_resource` eltávolítva.** Registry: `src/bridge/framework_resource_registry.lua` (`ecore_framework_resource_set`, `ecore_framework_resource_esx`, `ecore_framework_resource_qb`) – nincs `_G._ECORE_LEGACY_*`.
- **Fatális init:** stub (`Config`/`eCore`/`_ECORE_INIT_FAILED`) + `error('[e_core] …', 0)` – a shared betöltés **azonnal** megáll (a `StopResource` önmagában gyakran nem szakítja meg a futó chunkot). Szerveren a `StopResource(GetCurrentResourceName())` **következő tickben** (`CreateThread` + `Wait(0)`). `usableitem.lua` + `client/main.lua` guardok változatlanul érvényesek.
- `overrides/**/config.lua`: ha a cél resource nincs `started`, korai `return` (a korábbi `if … then … end` helyett), így a `Config` felülírás nem fut le.
- `overrides/**/shared.lua`, `client.lua`, `server.lua`: a resource-flag (`OX_INVENTORY`, `AVP_*`, `HUD17`, stb. / `ox_progressbar`: `OX_LIB`) alatt a bridge felülírások csak `if not … then return end` után futnak, nem `if X then` blokkban.
