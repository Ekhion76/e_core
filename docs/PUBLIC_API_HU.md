# e_core – publikus API (szerződés v0.4)

Ez a fájl a **külső hívható** `exports.e_core:*` felületet és az **`eCore:`** facade **névsorát** rögzíti (forrásfájl szerint). Az alábbi táblákban **exportonként egy rövid „mire való”** sor is van (ugyanaz a szemantika, mint az **`export_examples_client.md`** / **`export_examples_server.md`** fájlokban – ott angolul, példakóddal). Viselkedés-részletek, paraméterek, GYIK: **`docs/AI_SUPPORT_REFERENCE_HU.txt`**. **`eCoreErr` / hibanyomozás lépésenként:** **`docs/ECORE_ERR_HIBA_NYOMON_HU.md`**. **Dokumentáció navigáció:** **`docs/INDEX_HU.md`**.

| Meta | Érték |
|------|--------|
| **Resource verzió** | `fxmanifest.lua` → `version` |
| **Változások** | `changelog.md` – breaking változás = changelogban kiemelve |
| **Indulás** | `exports.e_core:isReady()` – item registry kész-e (client + server) |

**ConVarok (keret / legacy core resource):** `e_core:framework` = `auto` \| `esx` \| `qb` (alap: `auto`). **`e_core:framework_resource`** – nem üres és **kényszerített** `esx` \| `qb` mellett felülírja az alap resource nevet (`es_extended` vagy `qb-core`); `auto` mellett nem érvényes (figyelmeztető log). Belső registry: `ecore_framework_resource_*` (`framework_resource_registry.lua`). Részlet: `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md`, `docs/AI_SUPPORT_REFERENCE_HU.txt`.

**Override:** ugyanazon `eCore:` név felülírható `standalone/overrides/<mappa>/` alatt; a betöltési sorrend a mappanevek lexikografikus `**/shared.lua` / `client.lua` / `server.lua` globja szerint dől el.

---

## 1. Mindkét oldalon (client + server)

Forrás: `bridge/main.lua` + `bridge/ecore_lifecycle.lua`. Exportok: **`getFrameWork`**, **`getCore`**, **`getHelperBase`**, **`getHelperEcore`**; opcionálisan dev módban **`getInternal`** (lásd lentebb). A QB/ESX ciklusok **kizárólag** `RegisterNetEvent`-et hívnak, nem rejtett export-elágazás. **`eCore.helper`** a base **`hf`**-re (`libs/helper.lua`) mutat, **`eCore.Err`** a globális **`eCoreErr`**-re (azonos string értékek a visszaadott `reason`-ökkel). Az e_core-specifikus helper (`hfe`) dedikált exporton érhető el.

**`getCore()` kurált mezők (0.1.3+):** az `eCore` táblára – a bridge metódusok mellett – **merge**-elve kerülnek: **`eCore.framework`** (string \| `nil`, ugyanaz mint `getFrameWork()`), **`eCore.config`** (referencia a futó `Config` táblára), **`eCore.i18n`** (`translate`, `translateU`), **`eCore.util`** (`cLog`, `print_r`, `createBlip`, `animDictLoader`, `modelLoader`, `fxLoader`). **Szerveren**, ha a Discord modul betöltött: **`eCore.log.discord.create(webhook, botName?, opts?)`** → thin wrapper a belső `createDiscordLog` köré. Részlet: `docs/EXTENSION_CONTRACT_HU.md`.

| Export | Mire való | Visszatérés | Megjegyzés |
|--------|-----------|-------------|------------|
| `getFrameWork` | Aktív keretrendszer azonosítója (ESX vagy QB). | `string` \| `nil` | `'esx'`, `'qb'`. Nincs core induláskor: `nil`. |
| `getCore` | Az egyesített **`eCore`** API / facade objektum (inventory, notify, target, stb. – lásd §6–§10), plusz a fenti kurált mezők. | `table` | |
| `getHelperBase` | Base, framework-agnostic helper tábla (`hf`). | `table` | `libs/helper.lua` |
| `getHelperEcore` | e_core-specifikus helper tábla (`hfe`). | `table` | `libs/helper_ecore.lua` |
| `getInternal` | Csak ha **`e_core_dev`** convar igaz: belső **`_eCoreInternal`** debug tábla. | `table` | Productionben ne használd; ne építs rá consumer logikát. |

---

## 2. Csak kliens (`client/exports.lua`)

A tábla névsora = a fájlban lévő `exports(...)` sorok sorrendje; közvetlen függvény-hivatkozás, nincs rejtett üzleti ág (a viselkedés a `client/main.lua` és a shared segédekben van).

| Export | Mire való | Paraméterek | Megjegyzés |
|--------|-----------|-------------|------------|
| `getAbility` | Szakértelem (meta érték) lekérése egy kategóriában; név nélkül az egész kategória. | `category`, `name?` | Saját játékos cache. `category` / megadott `name`: **string**, **trim**; üres trim után vagy nem string → `false`, `no_valid_meta_name`. Nincs kategória a cache-ben → `category_does_not_exist`. Név megadva, nincs ilyen mező → `meta_does_not_exist`. Sikertelen: `false`, `reason`. |
| `getMeta` | A saját játékos teljes meta adatbázisa (vagy egy kategória, ha megadod a `meta` kulcsot). | `meta?` | Ha `meta` meg van adva: csak **nem üres string** (trim után); különben `false`, `no_valid_meta_name`. Hiányzó kategória kulcsnál a visszatérés **`nil`** lehet (nincs ilyen kulcs a cache-ben). |
| `getLabor` | Munkapont (labor) lekérése a saját karakterhez. | – | Siker: **`true`, szám** (a **0** egyenleg is így jön vissza). Hiba: `false`, `reason`. |
| `getLevel` | Szint számítása adott pontszámból (`standalone/config/levels.lua` tartományok). | `value` | |
| `getDiscounts` | Kedvezmények százalékban, a pontszám / szint alapján. | `value` | |
| `getConfig` | Teljes e_core `Config` tábla olvasása. | – | |
| `isReady` | Item registry betöltve-e és a core késznek tekinti-e magát; itemhez kötött logika előtt érdemes ellenőrizni. | – | `true` csak ha kész. Részletesebb háromállapot: `eCore:isReady()` (`nil` / `false` / `true`). |
| `registerHudElement` | HUD elem regisztrálása a hibrid DnD proxy réteghez (e_core edit mode + lokális preview sync). | `id`, `data` | `id`: nem üres string. `data.defaultPos`: normalizált `x,y,w,h` + `anchor` (`top-left`, `top-right`, `bottom-left`, `bottom-right`, `center`). Siker: `true`, effektív pozíció; hiba: `false`, reason. |
| `unregisterHudElement` | HUD elem levétele az e_core edit/sync regiszterből. | `id` | Resource stopnál ajánlott hívni. |

---

## 3. Csak szerver (`server/exports.lua`)

A tábla névsora = a fájlban lévő `exports(...)` sorok sorrendje; közvetlen hivatkozás a szerver implementációkra, nincs rejtett üzleti ág (`getConfig` / `isReady` / `getDbSchemaVersion` csak vékony burkoló).

| Export | Mire való | Paraméterek |
|--------|-----------|-------------|
| `getAbility` | Egy meta kulcs értékének olvasása adott játékosnál (csak már létező meta). | `playerId`, `category`, `name` |
| `setAbility` | Egy meta kulcs értékének beállítása / felülírása. | `playerId`, `category`, `name`, `value` |
| `addAbility` | Numerikus meta érték növelése. | `playerId`, `category`, `name`, `value` |
| `removeAbility` | Numerikus meta érték csökkentése. | `playerId`, `category`, `name`, `value` |
| `getLabor` | Játékos labor pontjainak lekérése. | `playerId` | Siker: **`true`, szám**; hiba: `false`, `reason` (lásd §5). |
| `setLabor` | Labor pontok beállítása (korlátozva `Config.laborLimit` szerint). | `playerId`, `amount` |
| `addLabor` | Labor pontok hozzáadása. | `playerId`, `amount` |
| `removeLabor` | Labor pontok levonása. | `playerId`, `amount` |
| `registerMeta` | Új meta kulcsok felvétele egy kategóriába, ha még nem léteznek (nem törli / nem írja felül a meglévőket). | `playerId`, `category`, `defaultValue` |
| `getProfessionRegistry` | Profession registry read modell lekérése DB-alapon, kategória/profession bontásban. | – |
| `isValidProfession` | Annak ellenőrzése, hogy egy profession létezik-e és engedélyezett-e a registryben. | `category`, `name` |
| `getProfessionDefaults` | Kezdő meta map egy kategóriára (`{ [professionName] = 0 }`) az engedélyezett professionökből. | `category` |
| `getProfessionLevelProfile` | Professionhöz rendelt level profile adatai (`profileKey`, `displayName`, `mode`, `levels`). | `category`, `name` |
| `validateProfessionKeys` | Profession kulcslista validálása egy kategórián belül (`valid`, `invalid`, `missingProfile` listákkal). | `category`, `keys[]` |
| `professionAdminList` | Admin read API: profession lista lekérése standard válaszformában (`ok`, `code`, `message`, `data`). | – |
| `professionAdminCreate` | Admin CRUD: új profession létrehozása (`category`, `name`, `profileKey`, opcionális mezők). | `payload` |
| `professionAdminUpdate` | Admin CRUD: profession frissítése kulcs alapján (`category`, `name` + részleges `payload`). | `category`, `name`, `payload` |
| `professionAdminSetEnabled` | Admin CRUD: profession engedélyezés/tiltás rövidített műveletként. | `category`, `name`, `enabled` |
| `professionAdminDelete` | Admin CRUD: profession törlése registryből. | `category`, `name` |
| `professionAdminDeleteDryRun` | Profession törléshez meta cleanup dry-run job létrehozása (batch/cursor, perzisztens job tábla). | `category`, `name`, `payload?` (`auth.source?`) |
| `professionAdminDeleteApply` | Profession meta cleanup apply job létrehozása megerősítéssel (`confirmText`), opcionális profession törléssel. | `category`, `name`, `payload?` (`auth.source?`) |
| `professionAdminCleanupJobList` | Cleanup job lista UI-hoz (`items`, `total`, `limit`, `offset`) szűréssel (`status`, `mode`, `category`, `name`). | `filters?` (`auth.source?`) |
| `professionAdminCleanupJobGet` | Cleanup job állapot és statisztika lekérése `jobId` alapján. | `jobId`, `payload?` (`auth.source?`) |
| `professionAdminCleanupJobAbort` | Futó/queued cleanup job megszakításra jelölése. | `jobId`, `payload?` (`auth.source?`) |
| `professionAdminCleanupJobResume` | Megszakított/hibás cleanup job folytatása az utolsó cursorról. | `jobId`, `payload?` (`auth.source?`) |
| `professionAdminAuditList` | Profession/cleanup admin audit események listája egységes shape-ben (`eventType`, `actor`, `target`, `outcome`, `details`). | `limit?`, `payload?` (`auth.source?`) |
| `adminApiDeniedAuditList` | Admin API jogosultság-elutasítás audit lista lapozással; egységes audit shape (`eventType`, `actor`, `target`, `outcome`) + legacy mezők. | `filters?` (`section?`, `action?`, `limit?`, `offset?`, `auth.source?`) |
| `adminApiDeniedAuditPurge` | Manuális denied audit purge futtatás a retention policy szerint (`dryRun` támogatással). | `payload?` (`auth.source?`, `dryRun?`) |
| `levelProfileAdminList` | Admin read API: level profile lista lekérése (`levels`, használati darabszám). | – |
| `levelProfileAdminCreate` | Admin CRUD: level profile létrehozás (`levels` vagy `easyGenerator` alapú generálás). | `payload` |
| `levelProfileAdminUpdate` | Admin CRUD: level profile frissítés (`displayName`, `mode`, `levels`/`easyGenerator`). | `profileKey`, `payload` |
| `levelProfileAdminDelete` | Admin CRUD: level profile törlése (csak nem használt profile törölhető). | `profileKey` |
| `diagnosticsAdminListTests` | Admin diagnostics tesztlista doc hint metaadatokkal (`docHints`). | `payload?` (`auth.source?`) |
| `diagnosticsAdminRun` | Diagnostics futtatás sorba állítása (run státusz: `queued/running/passed/failed/cancelled`), opcionális célzott profession kulcsvalidációs bemenettel. | `payload` (`tests[]`, `requestedBy?`, `auth.source?`, `professionKeysByCategory?`) |
| `diagnosticsAdminGetRun` | Egy diagnostics futás állapotának és eredményének lekérése `runId` alapján. | `runId`, `payload?` (`auth.source?`) |
| `diagnosticsAdminCancelRun` | Sorban álló / futó diagnostics futás megszakításra jelölése. | `runId`, `payload?` (`auth.source?`) |
| `getMeta` | Egy kategória összes eleme, vagy meta nélkül a teljes meta adatbázis. | `playerId`, `meta?` |
| `setMeta` | Egy kategória értékeinek felülírása táblával. | `playerId`, `meta`, `value` |
| `getLevel` | Szint számítása pontszámból (ugyanaz a logika, mint kliensen). | `value` |
| `getDiscounts` | Kedvezmény tábla pontszám alapján. | `value` |
| `getConfig` | Teljes `Config` olvasása. | – |
| `isReady` | Szerver oldalon is: item registry kész-e indulás / timeout után. | – |
| `getDbSchemaVersion` | Alkalmazott DB migrációk közül a legnagyobb `id` (`e_core_migrations`); séma „verzió” ellenőrzéshez. | – (visszaadás: max. migráció `id`; **0** ha üres tábla, lekérdezés sikertelen, vagy `MAX` `nil` – részlet és operátori sorrend: `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §4.5) |

---

### 3.1 Játékbeli web konzol — profession / level-profile admin (NUI bridge)

A **`SetHttpHandler` alapú külső HTTP admin (`/admin/...`) el lett távolítva.** A beépített Svelte admin (`ecore_admin`, `src/web/src/lib/registry.ts`) a szerver felé **NUI callbacken** (`eCoreAdminApi`) hív: kliens `client/nui_admin_bridge.lua` → szerver `server/nui_admin_bridge.lua`, jogosultság **`hf.webConsoleAccess`** (ugyanaz, mint az admin NUI megnyitásához). Integritás checklist net: `e_core:integrityCheck:*` (`server/integrity_check.lua`).

**Megjegyzés:** az operátori jogosultság és a szerver oldali policy **konfigurációjának** részletei (parancs, azonosítók, `Config.operator` / `Config.web` / `Config.adminApi` stb.) **nem** részei ennek a táblázatos API-szerződésnek — üzemeltetői lépések: **`docs/SZERVER_OPERATOR_CHECKLIST_HU.md`**, forrás: `standalone/config/main.lua` és a `libs/config_check.lua` szintézis.

- Válasz alakja változatlan: `professionAdminList`, `professionAdminCreate`, `levelProfileAdminList`, stb. ugyanazt az `{ ok, code, message, data }` szerződést adják, mint az exportok.
- **Böngészős `npm run dev`:** valós CRUD nélkül használd a mock registry-t (`VITE_USE_MOCK_REGISTRY=true`, lásd `src/web/.env.example`).

---

## 4. Nem export – ajánlott belépés

```lua
eCore = exports.e_core:getCore()
-- eCore.framework, eCore.config, eCore.i18n.*, eCore.util.* már mergeelve (0.1.3+)
-- Szerver: opcionálisan eCore.log.discord.create(...) ha a Discord modul aktív
```

`imports/shared/core.lua` – egy sor `getCore()`, és opcionálisan **deprecated** globál alias: `FRAMEWORK = eCore.framework`, `eCoreConfig = eCore.config` (fokozatos migrációhoz). **Egy soros bootstrap:** `imports/shared/full_import.lua` (`shared_script '@e_core/src/imports/shared/full_import.lua'`) – sorrend: `core` → `locale` → `utils`; a `full_import` a **`e_core` resource nevet** feltételezi (`LoadResourceFile('e_core', …)`).

`imports/shared/helper_base.lua`. Opcionális helper-import: globális `hf = exports.e_core:getHelperBase()` inicializálás consumer oldalon.

`imports/client/hud_drag.lua`. Opcionális HUD drag preview proxy: az import réteg hallgatja az `e_core:hud:clientPreview` eseményt, és ha az `id` benne van a consumer oldali `RegisteredElements` map-ben, `SendNUIMessage({ action = 'ECORE_HUD_SYNC', id, pos })` üzenetet küld. Így a consumer oldali NUI üzenetkezelő egyetlen központi rune-state-ből (`.svelte.ts`) frissíthet minden komponenst.

**Megjegyzés:** **`eCore.helper`** = base **`hf`** (`libs/helper.lua`) – változatlan bridge viselkedés. **`eCore.GroupAccess:check(playerData, data)`**: `src/libs/GroupAccess.lua` (job/gang whitelist–blacklist; lásd §6). **`eCore.Err`** = `libs/errors.lua` → **`eCoreErr`** (azonos kulcsok / string értékek); külső resource összehasonlíthat: `reason == exports.e_core:getCore().Err.inventory_full`.

---

## 5. Gyakori `false, ok` stringek (`eCoreErr` / `eCore.Err`)

Forrás: **`libs/errors.lua`**. Az e_core belső kódja **`eCoreErr.xyz`** formát használ; a **visszaadott string** változatlan maradt (backward compatible).

| Kulcs (`eCoreErr.*`) | Példa string érték | Hol (tipikus) |
|----------------------|-------------------|---------------|
| `category_does_not_exist` | ugyanaz | kliens `getAbility` |
| `meta_does_not_exist` | ugyanaz | kliens `getAbility` (név megadva) |
| `the_system_is_turned_off` | ugyanaz | labor / kliens olvasók |
| `not_found_metadata` | ugyanaz | szerver meta / labor |
| `no_valid_meta_name` | ugyanaz | szerver meta; kliens `getAbility` / `getMeta` (érvénytelen vagy üres kulcs param) |
| `not_valid_amount` | ugyanaz | szerver labor (`addLabor` / `removeLabor`: nem pozitív vagy NaN mennyiség; `setLabor`: hiányzó / negatív / NaN); szerver jártasság (`addAbility` / `removeAbility` / `setAbility`) ha a `value` nem **szám** (`tonumber` szerint) |
| `not_enough_labor` | ugyanaz | szerver `removeLabor`: a levonás nagyobb, mint az aktuális egyenleg |
| `not_levels_data` | ugyanaz | `getDiscounts` (shared `libs/meta.lua`): nincs érvényes `Config.levels` tábla |
| `has_already_reached_the_limit` | ugyanaz | szerver meta / labor |
| `too_heavy`, `not_enough_space` | ugyanaz | `canSwapItems` / `canCarryItem` (global shared). **avp_grid_inventory** szerver override: a stack csak booleant ad — „nem vihető” ág **`too_heavy`** (a kliens override is ezt a mintát használja) |
| `invalid_item_data` | ugyanaz | `canSwapItems` / `canCarryItem`: `itemData` nem tábla; `name` nem üres string (trim után); `amount` nem pozitív szám; `canSwapItems`: `swappingItems` megadva de nem tábla; swap sor ugyanilyen szerződés. **Keretrendszer `removeItems`:** lista elemei nem tábla, üres / hiányzó név, **`amount`** nem pozitív szám vagy NaN. **Override inventory (`ox_inventory` / `qs_inventory` / `avp_grid_inventory` szerver):** `removeItems` ugyanilyen sor-szerződés; **avp** `removeItem` / `addItem`: érvénytelen **`item`** / **`count`** |
| `item_not_registered` | ugyanaz | `canSwapItems` / `canCarryItem`: az item név nincs a registry-ben (`REGISTERED_ITEMS`) |
| `not_ready` | `'not_ready'` | ESX kliens `getRegisteredItems`: nincs még feltölthető katalógus (`REGISTERED_ITEMS` + szerver callback üres / timeout) |
| `invalid_player` | `'invalid_player'` | QB szerver `addMoney`: `QBCore.Functions.GetPlayer` **nil** (offline / rossz id) |
| `inventory_full`, `no_items_to_remove`, `inventory_is_empty`, `not_enough_items` | ugyanaz | QB bridge inventory |
| `there_are_no_items_to_remove` | `'there are no items to remove'` | ESX / ox / qs `removeItems` üres lista |
| `unknown_error` | ugyanaz | ox / qs removeItems hibaág; **ESX / QB `removeItems`:** hiányzó **`xPlayer`**; **ESX** továbbá **`removeInventoryItem`** kivétel (`pcall`); `eCore:createVehicle` (`bridge/global/server.lua`): érvénytelen `pos` / `model`, nem jött létre entitás, nincs érvényes **network id** (0 / `nil` a várakozás után), **network owner** továbbra is **-1**. **Override inventory szerver:** hiányos **`xPlayer`** / `pcall` kivétel a stack hívásban; **ox / qs `addItem`:** kivétel vagy olyan második érték, ami **nem** szerepel az `eCoreErr` stringek között (`cLog`); **avp** `canCarryItem` hívás kivétel, érvénytelen játékos forrás; **avp** stack egyedi hibaüzenet, ha nem egyezik egyetlen `eCoreErr` értékkel sem |
| `ok` | `'ok'` | sikeres többes remove végén |
| `vehicle_no_plate_data` | hosszú angol szöveg | `createVehicle` (global server) |
| `reserved_meta_category` | ugyanaz | `login` / `logout` / `labor` – szerver: tiltott kategória `registerMeta` / `setMeta` / jártasság exportoknál (`getAbility`, `setAbility`, …); laborhoz `getLabor` / labor exportok |
| `meta_default_must_be_table` | ugyanaz | `registerMeta` – harmadik param nem `nil` és nem tábla |
| `meta_value_must_be_table` | ugyanaz | `setMeta` – érték nem tábla |
| `meta_category_not_table` | ugyanaz | `registerMeta` merge: meglévő kategória slot nem tábla (sérült adat) |
| `diagnostics_run_not_found` | ugyanaz | `diagnosticsAdminGetRun` / `diagnosticsAdminCancelRun`: a megadott `runId` nincs a szerver memóriabeli futás tárolójában (pl. szerver restart után, hibás id, már felszámolt futás) |
| `profession_key_validation_failed` | ugyanaz | Admin diagnostics **`profession-key-validation`** teszt **eredmény** objektumának `code` mezője, ha a kulcsvalidáció hibákat talált (NEM ugyanaz, mint DB-beli „nincs ilyen profession” – az továbbra is `profession_not_found` a `getProfessionLevelProfile` stb. exportoknál) |
| `cleanup_scan_failed` | `'scan_failed'` | `cleanup_job_step`: meta cleanup DB scan sikertelen |
| `mysql_missing` | `'mysql_missing'` | `hf.mysqlAwait`: oxmysql nem elérhető |
| `admin_missing_auth_source` … `admin_web_denied` | angol üzenet (kulcsonként egyedi szöveg) | `hf.adminApiCanAccess`, `hf.webConsoleAccess` (`libs/helper_ecore.lua`) |
| `admin_audit_dual_policy_denied` | magyar üzenet (táblázat szerinti szöveg) | `server/professions.lua` (`adminApiDeniedAuditList` / denied audit gate) |
| `integrity_invalid_player` … `integrity_policy_denied` | magyar / vegyes (kulcsonként) | `server/integrity_check.lua` (`integrityCanRun` / policy) |

**Meta szerződés (szerver):** kategória / mező nevek **trim**elve; üres string → `no_valid_meta_name`. `registerMeta` / `setMeta` **nem** írhat a `login`, `logout`, `labor` gyökér kulcsokra. **Jártasság** exportok (`getAbility`, `addAbility`, `setAbility`, `removeAbility`) **nem** használhatók ezekre a kulcsokra – labor olvasásához `getLabor` / `getMeta(playerId, 'labor')`; íráshoz labor exportok.

Új inventory ok: először **`eCoreErr`**-be kulcs + érték, majd hivatkozás a bridge / override fájlokban.

---

## 6. `eCore:` – közös (shared), `bridge/global/shared.lua`

| Metódus |
|---------|
| `getInventoryWeight` |
| `canSwapItems` |
| `canCarryItem` |
| `countFreeSlots` |
| `getItemWeight` |
| `getFirstSlotByItem` |
| `getAmountOfItems` |
| `getRegisteredItem` |
| `isReady` |

**Kiegészítő közös helper (`src/libs/GroupAccess.lua`):**
- Lua oldali osztály/tábla név: **`GroupAccess`**
- Facade elérés: **`eCore.GroupAccess:check(playerData, data)`**
- JS pár (`src/web/copyable/GroupAccess.js`): **`class GroupAccess`** + `GroupAccess.check(playerData, data)`
- Szerződés: `data.whitelist` / `data.blacklist` alapú job+gang hozzáférés a `convertPlayer` szerinti `playerData.job` / `playerData.gang` mezőkre; üres mindkét lista → **true**; kitöltött whitelist esetén a blacklist figyelmen kívül hagyva.

---

## 7. `eCore:` – kliens (globális), `bridge/global/client.lua`

ox_target jellegű globális opciók / zónák: `disableTargeting`, `addGlobalOption`, `removeGlobalOption`, `addGlobalObject`, `removeGlobalObject`, `addGlobalPed`, `removeGlobalPed`, `addGlobalPlayer`, `removeGlobalPlayer`, `addGlobalVehicle`, `removeGlobalVehicle`, `addModel`, `removeModel`, `addEntity`, `removeEntity`, `addLocalEntity`, `removeLocalEntity`, `addSphereZone`, `addBoxZone`, `addPolyZone`, `removeZone`.

---

## 8. `eCore:` – szerver (globális), `bridge/global/server.lua`

| Metódus | Visszatérés |
|---------|-------------|
| `createVehicle` | Param: **`pos`** tábla (`x`,`y`,`z` számok; `w` opcionális, alap **0**), **`model`** nemnulla **szám** (hash) vagy nemüres **string**, **`vType`** a `CreateVehicleServerSetter` ághoz (lásd `AI_SUPPORT_REFERENCE`), **`props`** csak **`nil`** vagy **tábla**. Siker: **`netId`**, jármű **entitás handle** (szerver); hiba: **`false`**, `reason` – **`vehicle_no_plate_data`** (rendszám nem olvasható); egyéb hiba: **`unknown_error`** (lásd §5). A **`e_core:createVehicle`** callback ugyanezt adja át a `cb`-nek. |

---

## 9. `eCore:` – ESX ág (`ESX_CORE`)

**Shared (`bridge/esx/shared.lua`):** `convertPlayer` (egységes `job`/`gang` séma, `charName`, `firstName`/`lastName`, `position`, `metadata`, ESX-en neutral `gang` + opcionális `citizenid` alias), `convertItems` (központi `hf.convertItemsWithProfile(..., 'esx')` pipeline).

**Client (`bridge/esx/client.lua`):** `triggerCallback`, `sendMessage`, `drawText`, `hideText`, `progressbar`, `cancelProgressbar`, `isLoggedIn`, `getInventory`, `getPlayerMaxWeight`, `getRegisteredItems`, `getPlayer`, `getAccounts`, `canInteract`, `setFuelLevel`, `vehicleKeys`, `setVehicleProperties`, `setVehiclePropertiesFromNetId`, `deleteVehicle`, `getClosestVehicle`. **`getRegisteredItems`:** ha a globális `REGISTERED_ITEMS` még üres, a szerver `e_core:getRegisteredItems` **ox_lib callback** (`bridge/global/callbacks/server.lua`) tölti a katalógust; sikertelen / üres válasz: **`false`**, **`eCoreErr.not_ready`** (nem a játékos inventory `convertItems` ága).

**Server (`bridge/esx/server.lua`):** `createCallback`, `createUsableItem`, `sendMessage`, `drawText`, `hideText`, `addMoney`, `removeMoney`, `getAccounts`, `getInventory`, `getInventoryWeight`, `getPlayerMaxWeight`, `addItem`, `removeItem`, `removeItems`, `getRegisteredItems`, `getPlayer`, `itemBox`, `addCommands`.

---

## 10. `eCore:` – QB ág (`QB_CORE`)

**Shared (`bridge/qb/shared.lua`):** `convertItems` (központi `hf.convertItemsWithProfile(..., 'qb')` pipeline), `getRegisteredItems`, `convertPlayer` (ugyanaz a `job`/`gang`/név/`metadata`/`position` szerződés mint ESX ágon, normalizálva).

**Client (`bridge/qb/client.lua`):** ESX-hez hasonló készlet; eltérések: `sendMessage` opcionális `image`; `getPlayer(newJob, newGang)`; további metódusok mint ESX kliensnél (`triggerCallback`, `progressbar`, `getInventory`, jármű, stb.).

**Server (`bridge/qb/server.lua`):** ESX-hez hasonló készlet (`createCallback`, `createUsableItem`, üzenetek, pénz, inventory, `getPlayer`, `itemBox`, `addCommands`). **Megjegyzés:** `removeMoney` aláírása / viselkedése eltérhet az ESX ágtól – részletek az AI_SUPPORT_REFERENCE QB szekcióban.

---

## 11. Deprecálási szabály (e_core repó)

1. **Előjelzés:** changelog „Deprecated” szekció + legalább egy minor verzió.
2. **Futás közben:** régi név maradhat **alias** (thin wrapper), opcionális `print` / `cLog` figyelmeztetés.
3. **Eltávolítás:** következő major vagy kijelentett breaking minor; **`PUBLIC_API_HU.md`**, **`export_examples_*`**, **`AI_SUPPORT_REFERENCE_HU.txt`** egy PR-ben frissül.

Új export vagy szemantika változás: lásd `.cursor/rules/e_core-ai-collaboration.mdc`.

---

## 12. Még opcionális

- [ ] `PUBLIC_API.json` gépi fogyasztásra.
- [ ] További belső gate / hibaág finomhangolása új `eCoreErr` kulcsokra (inventory + override + bridge **kész**; admin/integrity üzenetek részben `eCoreErr`, lásd `libs/errors.lua`).

---

## 13. Támogatott stack (összefoglaló)

Részletes mátrix: **`docs/SUPPORTED_STACK_MATRIX_HU.md`**.
