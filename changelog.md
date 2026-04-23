0.0.28
- Labor auto tick (`server/labor.lua` → `laborIncrease`): céljátékosok **`GetPlayers()`** + `hf.isValidPlayerSource` + betöltött `ECO.meta[id].labor` alapján (nem a teljes `ECO.meta` bejárása). Opcionális szerver ConVar: **`e_core:labor_tick_chunk`** (alap **0** = egy hullámban mind; **>0** = legfeljebb ennyi fő / `SetTimeout(0)` hullám nagy online létszámnál). Doksi: `docs/LABOR_KEZELES_MUNKAFIL_HU.md`, `docs/SZERVER_OPERATOR_CHECKLIST_HU.md`.

0.0.27
- Luacheck 1.2.0: a **131** figyelmeztetéshez **`-- luacheck: push ignore 131`** / **`pop`** az `imports/*.lua` (4) + `types/fivem_ox_stubs.lua` fájlokban; a `.luacheckrc` `files[…].ignore` + globális `ignore` nem mindig illeszkedik. Megjegyzés: önmagában `-- luacheck: ignore 131` üres sorban 022 „unpaired push”-ot okozhat.

0.0.26
- Luacheck: `.luacheckrc` – a maradék 11× „unused global” valójában **131** (*Unused implicitly defined global*); `unused` / `unused_globals` **nem** kapcsolja ki. Megoldás: `imports/core|discordlog|locale|utils.lua` + `types/fivem_ox_stubs.lua` → **`files[…].ignore = { "131" }`**. Eltávolítva a hatástalan `unused_globals = false`.

0.0.25
- Luacheck: `.luacheckrc` – globális **`unused_globals = false`** (a `unused = false` önmagában nem mindig szünteti a 13x globál „unused” zajt). `libs/meta.lua`: **`table.clone` → helyi `shallow_copy`** (fájl-specifikus `read_globals` merge helyett, 0 warning stabilan).

0.0.24
- Luacheck: `.luacheckrc` – a `table.clone` leírást **nem** a globális `read_globals` tömbbe tesszük (régebbi luacheck: „string expected … got table”); vissza: `files['libs/meta.lua']` táblás `read_globals` + `clone = {}`.

0.0.23
- Luacheck: `.luacheckrc` – `table.clone` a globális `read_globals`-ben; `_PlayerPedId` **globals** (írható); Cfx manifest kulcsszavak `read_globals`; `fxmanifest` / `types` **exclude** minták bővítve (`**/…`); könyvtári + stub fájlok `unused_globals = false`. Példa override: `_ = CUSTOM_INVENTORY` helyett no-op `(function(_inv) end)(CUSTOM_INVENTORY)` (3 fájl). Cél: **`luacheck .` → 0 warning**.

0.0.22
- Luacheck: `.luacheckrc` – `libs/meta.lua` `read_globals.table.fields.clone` leíró **tábla** (`{}`), nem boolean; különben a config betöltése elhasal („field description table expected”).

0.0.21
- Biztonság: `e_core:methodCaller` kliens **whitelist** (`methodCallerAllowed` a `bridge/global/events/client.lua`-ban). Nem engedélyezett `method` esetén nincs dinamikus hívás; **mindig** `print` a kliens konzolra, opcionálisan `cLog` (debug).

0.0.20
- Bridge / net audit: `docs/NET_EVENTS_AUDIT_HU.md` – §5–§7 táblázatok (keretrendszer NetEvent regisztrációk, `e_core:sync` / `levelChange`, `e_core:methodCaller` kockázat és mitigáció javaslat). Kliens: `e_core:onPlayerLoaded` / `e_core:onPlayerUnload` **`AddEventHandler`** (a bridge lokális `TriggerEvent`-et használ; korábbi `RegisterNetEvent` miatt a labor HUD nem futott a bridge útvonalon).

0.0.19
- Luacheck: `.luacheckrc` – `fxmanifest.lua` és `types/**` kizárva; `ESX`/`QBCore` írható **globals**; FiveM natív `read_globals` bővítés; `libs/meta.lua` `table.clone`; `example_custom_inventory` üres `if` zaj; `imports/utils.lua` `print_r` árnyékolt változó átnevezve. Cél: **0 warning** `luacheck .`-nál.
- 3E MySQL: `hf.mysqlAwait(tag, fn)` (`libs/helper.lua`) – `pcall` + `cLog`. `server/db.lua`: `MySQL.update.await` / `prepare.await` / `scalar.await` + hibánál korai return; `server/db_migrations.lua`: minden `query.await` ugyanígy; `getDbSchemaVersion` figyelmeztet ha `alkalmazott_max < ECORE_DB_SCHEMA_TARGET`. Doksi: `DB_MIGRATIONS_HU.md`, `MODERNIZACIOS_…` 3E.

0.0.18
- DX (Fázis 4): LuaLS `.luarc.json`; típus stubok `types/` (`fivem_ox_stubs.lua`, `e_core_facade.lua`, `resource_globals.lua`). Luacheck `.luacheckrc` (lua54, html kizárva, FiveM + e_core globálok; `unused` zaj egyelőre ki). GitHub Actions `lua_ci.yml` – `luacheck .`. Doksi: `docs/LUA_LS_AND_CI_HU.md`; terv: `MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` Fázis 4 / 3F frissítve.

0.0.17
- DB (Fázis 3): `server/db_migrations.lua` – `e_core_migrations` tábla, soronkénti migrációk; `#1` = `users` / `players` `e_core` LONGTEXT oszlop (korábbi `db.lua` ALTER átkerült ide). `MySQL.ready` először `e_core_run_db_migrations()`, majd a megszokott meta CRUD. Új szerver export: `exports.e_core:getDbSchemaVersion()`. Doksi: `docs/DB_MIGRATIONS_HU.md`; terv: `MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` Fázis 3 pipa.

0.0.16
- Docs: Fázis 2 – `docs/AI_SUPPORT_REFERENCE_HU.txt` teljes audit: fejléc + kapcsolódó linkek (operátor checklist, NET_EVENTS), globális `events/server` leírás javítva (createVehicle csak callback), kliens indulás = `awaitItemRegistryReady`, **2. export** szekció bővítve (`isReady`, kliens `getLabor` + `not_found_metadata`), **3. eCore** szekció: PUBLIC_API mint névsor-forrás, **5. GYIK** kitöltve; szerver `getAbility` név kötelező megjegyzés. `docs/PUBLIC_API_HU.md`: szerver `getAbility` paraméter `name` kötelező. `MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` Fázis 2 AI_SUPPORT pipa.

0.0.15
- Docs: Fázis 0 lezárás – `docs/SZERVER_OPERATOR_CHECKLIST_HU.md` (kockázatlista + egy oldalas szerver operátori checklist, ensure példa, ConVarok). `MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md` Fázis 0 jelölések frissítve; hivatkozások: `README_HU.md`, `SUPPORTED_STACK_MATRIX_HU.md`, `PROJECT_STRUCTURE.txt`, `e_core-context.mdc`.

0.0.14
- Net security (G): `hf.isValidPlayerSource` + `hf.netRateLimit`; `e_core:loadMeta` validates source, rate limit via ConVar `e_core:loadmeta_rate_ms` (default 2500, min 500). `e_core:playerLoaded` switched to `AddEventHandler` (server-only; not client-triggerable). Removed duplicate `e_core:createVehicle` RegisterNetEvent entry; vehicle spawn only via `e_core:createVehicle` callback with source check. AVP inventory callbacks validate source. See `docs/NET_EVENTS_AUDIT_HU.md`.
- **Breaking (ritka):** ha külső script kliensről `TriggerServerEvent('e_core:playerLoaded', …)`-t használt, az **nem** fut tovább – a betöltést a keretrendszer + `TriggerEvent` szerver oldalon kezeli.

0.0.13
- Unified startup log line: `hf.logEcoreStartupSummary('server'|'client')` after item registry wait — prints resource version, `FRAMEWORK`, active inventory override label (`ox_inventory`, `qs-inventory`, `avp_grid_inventory`, combinations, or `framework`), and `items=ready|timeout|pending`.

0.0.12
- Labor refactor (`server/labor.lua`): shared guards `laborRequireSystem` / `laborPlayerRow`; auto `laborIncrease` uses `syncRequest` instead of direct `TriggerClientEvent`; skips tick when labor system disabled; `addOfflineLabor` validates meta/labor row. Client `getLabor` returns `false, not_found_metadata` if labor block not synced yet.

0.0.11
- Central reason codes: `libs/errors.lua` (`eCoreErr` global); `eCore.Err` attached in `bridge/main.lua`. Wired through `bridge/global/shared.lua`, `bridge/global/server.lua`, ESX/QB server inventory paths, `ox_inventory` / `qs_inventory` / `avp_grid_inventory` server overrides, `server/meta.lua`, `server/labor.lua`, `client/main.lua`. String values unchanged for consumers. Docs: `docs/PUBLIC_API_HU.md` v0.3, `docs/SUPPORTED_STACK_MATRIX_HU.md`, `docs/REFAKTOR_PRIORITAS_UZEMTERV_HU.md` (D done).

0.0.10
- Framework selection: single shared entry `bridge/framework_config.lua` plus `bridge/esx/config_defaults.lua` and `bridge/qb/config_defaults.lua` (removed `bridge/esx/config.lua`, `bridge/qb/config.lua`). ConVar `e_core:framework` (`auto`|`esx`|`qb`): if both `es_extended` and `qb-core` are started and mode is `auto`, resource fails fast with an error; forced `esx`/`qb` activates only one bridge branch (`ESX_CORE` / `QB_CORE`). Roadmap: `docs/REFAKTOR_PRIORITAS_UZEMTERV_HU.md`.
- Public API contract (initial): `docs/PUBLIC_API_HU.md` – table of all `exports.e_core:*` (client/server/bridge); deep `eCore:` behavior remains in `docs/AI_SUPPORT_REFERENCE_HU.txt` until further merged.
- Public API v0.2: `eCore:` method inventory by bridge file, common `(false, reason)` strings, deprecation policy; new `docs/SUPPORTED_STACK_MATRIX_HU.md` (Tier 0–2 stack outline).

0.0.9
- Item registry boot: `hf.awaitItemRegistryReady` – timeout (`e_core:items_ready_timeout_ms`, default 120s, clamp 30s–600s), throttled wait logs, optional `e_core:items_ready_poll_ms`. On timeout `CORE_READY = false` instead of hanging forever. New `exports.e_core:isReady()` on client and server. See `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md` (section 5) for ConVars and stream vs server start note.
- Quick patch for incorrectly registered item images caused by QBox (QBCore.Shared.Items may contain image = '.png' with missing filenames).
- The translate script received additional validations to handle invalid input values more safely.
- Refactored helper functions.
- Added progress bar handling to scripts_ui.


0.0.8
- Transition to exclusive support for ox_target. If you use a target system, ox_target must be installed.

#### Why is this happening?
Ox_target has discontinued compatibility with qb_target. This currently only affects qb_core and ox_target users.

This means the module responsible for converting options and other parameters has been removed from ox_target. I decided not to integrate this into e_core because the qb_target system is outdated. Moving forward, I have chosen to support the modern ox_target natively.

#### What has changed:
e_core/bridge/global/client.lua: Adds ox exports.

e_core/bridge/esx/client.lua: Removal of qtarget-related functions

e_core/bridge/qb/client.lua: Removal of qb-target-related functions

0.0.7
- extends qb-core item remove function
- small bugfix
0.0.6
- Error: SEND_NUI_MESSAGE: invalid JSON passed in frame (rapidjson error code 3)
- The initial labor value could have been NaN, so the Nui interface did not open, only the cursor was visible.
  The change affects the:
- [lib/config_check.lua] -- added
- [fxmanifest.lua]
- [server/meta.lua] (prepareMeta)

0.0.5
- [e_core/server/labor.lua] (addOfflineLabor) Add offline labor timestamp. When logging in, the player receives the lab points collected during the offline time, with the current time stamp attached.
- [e_core/bridge/qb/shared.lua] (convertItems) Ignore non valid items and non-existent labels

0.0.4
- The getPlayer() function has been extended. It is given two optional parameters.
The change affects the:
- [bridge/esx/client.lua] (getPlayer)
- [bridge/esx/shared.lua] (convertPlayer)

- [bridge/qb/client.lua] (getPlayer)
- [bridge/qb/shared.lua] (convertPlayer)
The changes do not affect the standalone folder. Always copy and overwrite (if necessary) the functions of eCore there!
