# Changelog

A projekt új fázist kezd: a korábbi verziós napló helyett innen a **kiadás szerinti** rövid összegzés. Breaking változásnál emeld a `fxmanifest.lua` `version` mezőjét, és frissítsd a `docs/PUBLIC_API_HU.md` + `export_examples_*.md` fájlokat, ahol kell.

## [0.1.16]

- **Runtime modularity hardening:** `web_bridge`, `integrity`, `admin` NUI bridge és `diagnostics` NUI bridge fájlok pure modulokra lettek szétválasztva (`register...()`), a side-effect regisztráció külön init entrypointokba került (`init.lua` / `init_client.lua`).
- **HUD client registry:** a top-level net event / command kötés `ECoreHudLayout.registerClientBindings()` függvénybe került; új `src/runtime/hud/client/init.lua` kezeli a tényleges regisztrációt.
- **Manifest:** új init entryk felvéve a client/server script sorrendbe; `fxmanifest.lua` verzió: **0.1.16**.

## [0.1.15]

- **Dokumentáció (SDK + modularchitektúra):** `docs/PUBLIC_API_HU.md` §4.1 — teljes **consumer SDK fájl ↔ manifest** mátrix (7 fájl); profession exportok **`feature_disabled`** szerződés rögzítve §3-ban. Új kanonikus oldalak: `docs/ECORE_IMPORTS_SDK_LAYER_TERVEZES_HU.md`, `docs/ECORE_ARCHITECTURE_MODULARITY_HU.md`, `docs/ECORE_SIDE_EFFECT_AUDIT_HU.md`; `docs/INDEX_HU.md` §4 bővítve. `docs/LUA_ANNOTATION_MAINTENANCE_EN.md` §6 — hivatkozás a modularity policy-re.

## [0.1.0]

- Dokumentáció: belső munkanaplók és lezárt tervdokik eltávolítva; belépési pont: `docs/INDEX_HU.md`. A teljes Docusaurus fa helyett `tech_docs/README.md` helykitöltő. `fxmanifest` verzió **0.1.0** (új fázis jelzés; nem kötelező semver-folytonosság a korábbi 0.0.x-szel).

## [0.1.14]

- **Könyvtárszerkezet:** a lapos `src/server/` és `src/client/` üzemi Lua moduljai **`src/runtime/<domain>/`** alá kerültek (bootstrap, exports, meta, hud, labor, db, professions, diagnostics, admin, integrity, web_bridge, quote). A **`fxmanifest.lua` betöltési sorrendje** változatlan; részletes fa: [`docs/PROJECT_STRUCTURE.txt`](docs/PROJECT_STRUCTURE.txt).
- **Libs fájlnév:** `src/libs/GroupAccess.lua` → `src/libs/group_access.lua` (snake_case). A globális / facade API: `GroupAccess` / `eCore.GroupAccess` **változatlan**.
- **Config könyvtár:** `src/standalone/config/` → **`src/config/`** (`main.lua`, `levels.lua`). A **`src/standalone/usableitem.lua`** példa és az `overrides/**` sorrend változatlan; doksi/README útvonalak frissültek.

## [Unreleased]

- **Profession levels (refactor):** `src/libs/profession_levels.lua` — szintgörbe / normalizálás / `levels_json` decode / admin payload feloldás (`eCoreProfessionLevels.*`); `src/runtime/professions/server.lua` ezt hívja. Export szerződés változatlan.

- **Denied audit (0.1.13):** új modul `src/runtime/admin/server_denied_audit.lua` (lista/purge/schedule + `adminDenied` író export + NUI snapshot). `Config.operator.deniedAudit`: **`storage`** `mysql`|`discord`, **`webhookUrl`** (discord), **`discordBotName`** opcionális; `config_check` érvénytelen discord URL → `mysql` + `cLog`. `hfe.auditAdminApiDenied`: szerveren `mysql` = INSERT tábla, `discord` = `createDiscordLog` embed; ütemezett purge csak `mysql` mellett. **Admin NUI:** „Denied audit” fül (`DeniedAuditPanel.svelte`), actionök: `getDeniedAuditConfig`, `listDeniedAudit`, `purgeDeniedAudit`. Export átnevezés: `adminDeniedAuditList` / `adminDeniedAuditPurge` (korábbi `adminApiDeniedAudit*` név eltávolítva). `PUBLIC_API_HU.md`, `ECORE_ERR`, `export_examples_server.md`, `web` build `dist`.

- **Admin inventory minta:** ox blokk **csak** ha `ox_inventory` `started` (UI nem említ nem futó stacket); szerver hint ox nélkül rövidebb.

- **Admin inventory minta:** `adminGetInventorySamples` játékbeli NUI-ban **mindig** szerver RPC (nem takarja a `VITE_USE_MOCK_REGISTRY` mock); mock csak böngészőben, NUI nélkül.

- **NUI dev:** `fxmanifest.lua` `ui_page` → `http://127.0.0.1:5173/` + `vite.config.ts` `server` (host/port); élesen állíts vissza `dist`-re és build. `README` / `src/web/README.md` frissítve.

- **Admin NUI — Inventory minta (0.1.12):** új fül „Inventory minta”; `eCoreAdminApi` action `getInventorySamples` (`src/runtime/admin/server_inventory_sample.lua`): legfeljebb 3 sor a bridge `eCore:getInventory(target)` listából + opcionálisan 3 nyers slot az `ox_inventory:GetInventory` `items` táblájából, JSON dump (mélység/méretkorlát) a `Config.fields` override-hoz. `registry.adminGetInventorySamples`, mock ha `VITE_USE_MOCK_REGISTRY`.

- **Dokumentáció — `Config` sekély merge (0.1.11):** kanonikus szabály (`fxmanifest` sorrend, top-level tábla csere, `Config.operator` példa, `config_check` szintézis), operátori checklist §1.1 + kockázat tábla sor; `PUBLIC_API_HU.md` §1; `BRIDGE_LAYER_QUALITY_REVIEW_HU.md` config bekezdés frissítve.

- **eCoreErr finomítás (0.1.10):** Új kulcsok: `invalid_item_name` (`global/shared.lua` `hasItem`), `inventory_export_exception`, `inventory_operation_failed`. ESX `removeItems` pcall hiba → `inventory_export_exception` (korábban `unknown_error`). **ox_inventory / qs_inventory / avp_grid_inventory** szerver override: érvénytelen játékos → `invalid_player`; export **Lua hiba** (`pcall`) → `inventory_export_exception`; ox/qs **falsy** `RemoveItem` válasz → `inventory_operation_failed`. Doksi: `PUBLIC_API` §5, `ECORE_ERR` §3.

- **`getCore()` szerződés (0.1.9):** `eCoreLifecycle_buildPublicAPI()` merge-el **`ecoreVersion`** (`GetResourceMetadata(..., 'version', 0)`, üres esetén `0.0.0`) és **`bridgeContract`** (`schemaVersion`, `resource`, `lifecycleMergedKeys`) mezőket a facade-ra. Consumer gépi ellenőrzéshez; `bridgeContract.schemaVersion` változik, ha a tábla alakja / szemantikája változik. Doksi: `PUBLIC_API` §1, `BRIDGE_LAYER_QUALITY_REVIEW_HU.md` §2.

- **Bridge / kliens jármű stubok (0.1.8):** ESX és QB `bridge/*/client.lua` — `setFuelLevel`, `vehicleKeys`, `setVehicleProperties`, `setVehiclePropertiesFromNetId` egységes **`true` / `false, eCoreErr.*`** szerződés (korábbi csupasz `false` vagy csendes `return`). Új `eCoreErr`: `invalid_vehicle_entity`, `invalid_vehicle_plate`, `invalid_vehicle_props`, `vehicle_network_timeout`; üzemanyag mennyiség: `not_valid_amount`. Doksi: `PUBLIC_API` §5, `ECORE_ERR` §3.
- **Bridge / szerver `createVehicle`:** ha a negyedik param (`props`) meg van adva, de nem tábla → **`eCoreErr.invalid_vehicle_props`** (`bridge/global/server.lua`; korábban `unknown_error`).

- **Ready állapot (0.1.7):** `CORE_READY` indulás **`false`** (`src/runtime/bootstrap/client/main.lua`, `src/runtime/bootstrap/server/main.lua`); `eCore:isReady()` mindig **boolean** (`CORE_READY == true`), nem ad `nil`-t (`bridge/global/shared.lua`). Export `isReady` továbbra is boolean. Típus stubok + doksik frissítve.

- **ESX bridge (0.1.6):** `addMoney` / `removeMoney` nil `xPlayer` → `false`, `invalid_player` (korábban csak `false`). `getAccounts`: `source` szám → `GetPlayerFromId`. `getInventory` / `getInventoryWeight`: szám feloldás; nil → `{}` / `0`. `addItem` / `removeItem` / `removeItems`: szám feloldás + `invalid_player` (removeItems korábbi `unknown_error` nil helyett). Doksi: `PUBLIC_API` §5, `ECORE_ERR` §3, `AI_SUPPORT` ESX szerver blokk.

- **QB bridge (0.1.5):** `removeMoney` nil játékos → `invalid_player` (mint `addMoney`). `getAccounts` / `getInventory`: `source` szám feloldás + nil-safe (`0` / `{}`). `addItem` / `removeItem` / `removeItems`: szám feloldás + `invalid_player`; `removeItems` korábbi `unknown_error` nil helyett `invalid_player`. Doksi: `PUBLIC_API` §5, `ECORE_ERR` §3.

- **Bridge / init (0.1.4):** Ha induláskor egyik legacy core sem `started`, `_ECORE_INIT_FAILED = true` (korábban false maradt). ESX kliens `getRegisteredItems` nem használ játékos inventoryt; szerver `lib.callback.register('e_core:getRegisteredItems', …)` (`bridge/global/callbacks/server.lua`) + `eCoreErr.not_ready`. QB `addMoney` nil játékos: `false`, `eCoreErr.invalid_player`. ESX `getAccounts` nil-safe. `helper_ecore.awaitItemRegistryReady`: csak nem üres táblát ír `REGISTERED_ITEMS`-be. Új `eCoreErr`: `not_ready`, `invalid_player`. Doksi: `PUBLIC_API` §5/§9, `NET_EVENTS` §4, `ECORE_ERR` §3.

- **eCore lifecycle (0.1.3):** `_eCoreInternal` + `src/bridge/ecore_lifecycle.lua` — explicit `registerExtensions` / `initExtensions`, PURE `buildPublicAPI`, merge az `eCore` táblára (`framework`, `config`, `i18n`, `util`, szerveren opcionálisan `log.discord`). Dev: `e_core_dev` + `getInternal` export. Szerver load order: `discord_log.lua` a `bridge/main.lua` elé került. Consumer: `imports/sdk/shared/core.lua` egy sor + legacy alias; opcionális `imports/sdk/shared/full_import.lua`. Doksi: `docs/EXTENSION_CONTRACT_HU.md`, `PUBLIC_API` §1/§4 frissítve.
- **Item convert pipeline (src-first):** új központi modul: `src/libs/itemconvert_pipeline.lua` (`hf.convertItemsWithProfile`). A `convertItems` loop/pcall/diag/normalize logika centralizálva; profil-alapú mapping (`default`, `esx`, `qb`, `ox`, `qs`, `avp`) fut minden inventory esetén.
- **Thin overrides:** `overrides/ox_inventory/shared.lua`, `overrides/qs_inventory/shared.lua`, `overrides/avp_grid_inventory/shared.lua` most csak adatforrás-adaptert tartalmaz (`getRegisteredItems` + pipeline hívás), nincs helyi konverziós ciklus.
- **Guard:** startup warning, ha override-ban custom `convertItems` marad (`hf.itemConvertWarnCustomConvertItems`).
- **HUD DnD (hibrid proxy):** új kliens-szerver alapok a per-player HUD layout mentéshez (`hudLayout` meta kulcs, normalizált `x,y,w,h` + `anchor`, rate-limited `e_core:hud:commit`).
- **Új kliens exportok:** `registerHudElement`, `unregisterHudElement` (consumer HUD elemek regisztrációja az e_core edit/sync réteghez).
- **Edit mode NUI réteg:** Svelte 5 ghost layer + throttled preview callback (`hudPreview`), pointer-trap szabály (`ghost layer: pointer-events: all`, háttér: `none`), fókusz guard `openMeta` / admin web útvonalon.
- **Import réteg szétválasztás (module/side sémára):** canonical consumer útvonalak: `src/imports/sdk/core/shared.lua`, `src/imports/sdk/helper_base/shared.lua`, `src/imports/sdk/hud_drag/client.lua`, `src/imports/sdk/discord_log/server.lua`.
- **Legacy aliasok megszüntetve:** a korábbi gyökérszintű import útvonalak kivezetve; az új canonical importok a `src/imports/shared|client|server/` struktúrában érhetők el.
- **HUD preview opt-in:** az `e_core:hud:clientPreview` sync réteg canonical útvonala `src/imports/sdk/hud_drag/client.lua`; pure modul, automatikus handler-regisztráció nélkül.
- **DiscordLog export factory:** a canonical szerver modul `src/imports/sdk/discord_log/server.lua`; publikus létrehozás: `exports.e_core:createDiscordLog(...)`.
- **Helper szeparáció (base vs e_core):** az e_core-specifikus segédek külön `hfe` objektumba kerültek (`src/libs/helper_ecore.lua`), a generikus utilok `hf`-ben maradtak (`src/libs/helper.lua`). Új exportok: `getHelperBase`, `getHelperEcore`; a `getCore()` továbbra is elérhető.

- **Keretrendszer:** `src/bridge/framework_config.lua` újraírva (egyszerű ágak). ConVar: `e_core:framework_resource` – üres = nincs override; csak **kényszerített** `esx`|`qb` mellett írja felül az alap resource nevet; `auto` + nem üres override → figyelmen kívül + log. **`e_core:esx_resource` / `e_core:qb_resource` eltávolítva.** Registry: `src/bridge/framework_resource_registry.lua` (`ecore_framework_resource_set`, `ecore_framework_resource_esx`, `ecore_framework_resource_qb`) – nincs `_G._ECORE_LEGACY_*`.
- **Fatális init:** stub (`Config`/`eCore`/`_ECORE_INIT_FAILED`) + `error('[e_core] …', 0)` – a shared betöltés **azonnal** megáll (a `StopResource` önmagában gyakran nem szakítja meg a futó chunkot). Szerveren a `StopResource(GetCurrentResourceName())` **következő tickben** (`CreateThread` + `Wait(0)`). `usableitem.lua` + `client/main.lua` guardok változatlanul érvényesek.
- `overrides/**/config.lua`: ha a cél resource nincs `started`, korai `return` (a korábbi `if … then … end` helyett), így a `Config` felülírás nem fut le.
- `overrides/**/shared.lua`, `client.lua`, `server.lua`: a resource-flag (`OX_INVENTORY`, `AVP_*`, `HUD17`, stb. / `ox_progressbar`: `OX_LIB`) alatt a bridge felülírások csak `if not … then return end` után futnak, nem `if X then` blokkban.
