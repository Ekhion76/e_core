# e_core – hibakódok (`eCoreErr`) és rendszerezett nyomozás

**Cél:** egy helyen lásd, mit jelent minden visszaadott ok-string, honnan jöhet, és **milyen sorrendben** érdemes ellenőrizni – anélkül, hogy minden kódra külön kérdeznél.

**Mérvadó definíció:** `libs/errors.lua` → `eCoreErr` (és `eCore.Err` a `bridge/main.lua`-ban ugyanerre mutat).

**Kapcsolódó:** `docs/PUBLIC_API_HU.md` §5 (összefoglaló tábla), `export_examples_client.md` / `export_examples_server.md`, `docs/AI_SUPPORT_REFERENCE_HU.txt` (részletes API + GYIK).

**Dokumentáció navigáció:** `docs/INDEX_HU.md`.

---

## 1. Gyors módszer a hívó oldalon

```lua
local ok, reason = exports.e_core:setMeta(src, 'crafting', t)
if not ok then
    -- reason == exports.e_core:getCore().Err.meta_value_must_be_table
    -- vagy: reason == 'meta_value_must_be_table'  (string egyezés)
end
```

- **`reason` mindig ugyanaz a string**, mint az `eCoreErr.<kulcs>` értéke (kivétel: `there_are_no_items_to_remove`, `vehicle_no_plate_data` – lásd táblázat).
- **Ne** a kulcsnevet várd vissza Lua táblaként; **string** jön vissza második értékként.

---

## 2. Általános ellenőrzési sorrend (minden rejtélyhez)

Ezt a sorrendet végigfuttatva a legtöbb „véletlen” hiba kiszűrhető **funkció-specifikus kérdés nélkül**:

| # | Lépés | Mit nézel |
|---|--------|-----------|
| 1 | **Resource indulás** | `ensure` sorrend: legacy core → `e_core` → consumer. `changelog.md` / `fxmanifest` `version`. |
| 2 | **Keretrendszer** | `e_core:framework` ConVar (két core esetén). |
| 3 | **Kész állapot** | `exports.e_core:isReady()` – item registry (0.1.7+: mindig **boolean**, `true` csak ha kész); meta/labor előtt is érdemes. |
| 4 | **Oldal** | Client export vs server export – pl. `setMeta` **csak szerveren** van. |
| 5 | **Játékos** | Van-e `source` / betöltött meta (`e_core:playerLoaded` után)? `not_found_metadata` gyakran „még nincs sor” vagy rossz `playerId`. |
| 6 | **Config** | `standalone/config/main.lua` – `systemMode`, `labor`, `abilityLimit`, `metaFields`. |
| 7 | **Override ág** | Melyik inventory fut (`standalone/overrides/...`) – más bridge, más hibakód-minta. |
| 8 | **Repro** | Pontos export + argumentumok + `reason` string másolása → táblázat §3 alapján forrás. |

---

## 3. `eCoreErr` táblázat – hol keresd a kódot

Az `exports.e_core:*` **vékony réteg** (`client/exports.lua`, `server/exports.lua`, `bridge/main.lua` – lásd `docs/PUBLIC_API_HU.md` §1–§3) **nem** hoz létre új `reason` stringet; a második visszatérési érték mindig a mögöttes függvényből jön (pl. `server/meta.lua`, `client/main.lua`). A `getCore().Err` ugyanarra mutat, mint a globális `eCoreErr` (`bridge/main.lua`).

| Kulcs (`eCoreErr.*`) | Visszaadott string (összehasonlításhoz) | Tipikus ok | Fő forrás |
|----------------------|----------------------------------------|-------------|-----------|
| `ok` | `'ok'` | Többes item eltávolítás siker vége (QB / override) | `bridge/qb/server.lua`, override `removeItems` |
| `too_heavy` | ugyanaz | Csere / súly szabály | `bridge/global/shared.lua` (`canSwapItems` / `canCarryItem`); **avp** szerver override: stack csak boolean → „nem fér” ág |
| `not_enough_space` | ugyanaz | Slot / súly | `bridge/global/shared.lua` |
| `invalid_item_data` | ugyanaz | Rossz `itemData` / swap sor vagy nem tábla `swappingItems`; **`removeItems`** listaelem nem tábla / üres név / nem pozitív **`amount`** (NaN elutasítva); **override** ox/qs/avp `removeItems` ugyanígy; **avp** `removeItem` / `addItem` rossz **`item`** / **`count`** | `bridge/global/shared.lua`; `bridge/esx/server.lua`, `bridge/qb/server.lua` (`removeItems`); `standalone/overrides/ox_inventory|qs_inventory|avp_grid_inventory/server.lua` |
| `item_not_registered` | ugyanaz | Item név nincs a registry-ben | `bridge/global/shared.lua` |
| `not_ready` | `'not_ready'` | ESX kliens `getRegisteredItems`: szerver callback nem adott nem üres katalógust | `bridge/esx/client.lua` |
| `invalid_player` | `'invalid_player'` | ESX / QB: offline játékos (`addMoney`, `removeMoney`, `addItem`, `removeItem`, `removeItems`); **ox / qs / avp** szerver override: érvénytelen forrás | `bridge/esx/server.lua`, `bridge/qb/server.lua`; `standalone/overrides/ox_inventory|qs_inventory|avp_grid_inventory/server.lua` |
| `inventory_full` | ugyanaz | QB addItem | `bridge/qb/server.lua` |
| `no_items_to_remove` | ugyanaz | Üres lista / nincs mit | `bridge/qb/server.lua` |
| `inventory_is_empty` | ugyanaz | QB | `bridge/qb/server.lua` |
| `not_enough_items` | ugyanaz | QB kevesebb mennyiség | `bridge/qb/server.lua` |
| `there_are_no_items_to_remove` | **`'there are no items to remove'`** (szóköz!) | ESX / ox / qs / avp üres remove | `bridge/esx/server.lua`, override `server.lua` |
| `invalid_item_name` | ugyanaz | Globális `hasItem`: `itemName` nem string | `bridge/global/shared.lua` |
| `inventory_export_exception` | ugyanaz | ESX `removeItems` `pcall` körül `removeInventoryItem` kivétel; ox/qs/avp override: inventory export `pcall` hiba | `bridge/esx/server.lua`; `standalone/overrides/ox_inventory|qs_inventory|avp_grid_inventory/server.lua` |
| `inventory_operation_failed` | ugyanaz | ox / qs override: `RemoveItem` sikeres `pcall` mellett falsy válasz | `standalone/overrides/ox_inventory|qs_inventory/server.lua` |
| `unknown_error` | ugyanaz | Fallback; **override** `asEcoreInventoryReason` nem `eCoreErr` string; avp egyedi üzenet; `createVehicle` egyéb ág; stb. | `standalone/overrides/...`; `bridge/global/server.lua` |
| `vehicle_no_plate_data` | hosszú angol szöveg | Jármű létrehozás, rendszám adat | `bridge/global/server.lua` (`createVehicle`) |
| `invalid_vehicle_entity` | ugyanaz | ESX / QB kliens: `setFuelLevel` / `setVehicleProperties` — nincs érvényes jármű entitás | `bridge/esx/client.lua`, `bridge/qb/client.lua` |
| `invalid_vehicle_plate` | ugyanaz | ESX / QB kliens: `vehicleKeys` — üres / nem tartalmas rendszám | `bridge/esx/client.lua`, `bridge/qb/client.lua` |
| `invalid_vehicle_props` | ugyanaz | ESX / QB kliens: `setVehicleProperties` / `setVehiclePropertiesFromNetId` — üres vagy hiányzó `props` tábla; **szerver** `createVehicle`: `props` nem tábla és nem `nil` | `bridge/esx/client.lua`, `bridge/qb/client.lua`; `bridge/global/server.lua` |
| `vehicle_network_timeout` | ugyanaz | ESX / QB kliens: `setVehiclePropertiesFromNetId` — `netId` nem oldódott fel a várakozási ciklusban | `bridge/esx/client.lua`, `bridge/qb/client.lua` |
| `the_system_is_turned_off` | ugyanaz | `Config.systemMode` kikapcsolva | `server/labor.lua`, `client/main.lua` (`getLabor`) |
| `not_found_metadata` | ugyanaz | Nincs `PlayerMetaStore.get(player)` sor / nincs kulcs / sync előtt (kliens: üres cache) | `server/meta.lua`, `server/labor.lua`, kliens `getLabor` |
| `no_valid_meta_name` | ugyanaz | Nem string / üres név trim után | `server/meta.lua` (meta segédek); kliens `client/main.lua` (`getAbility`, `getMeta` param) |
| `not_valid_amount` | ugyanaz | Labor: `addLabor` / `removeLabor` nem pozitív mennyiség (vagy NaN); jártasság `value` nem szám; **ESX / QB kliens** `setFuelLevel`: `amount` nem szám (`tonumber` nil) | `server/labor.lua`, `server/meta.lua` (`addAbility` / `removeAbility` / `setAbility`); `bridge/esx/client.lua`, `bridge/qb/client.lua` |
| `not_enough_labor` | ugyanaz | `removeLabor`: kevesebb a egyenleg, mint a levonandó | `server/labor.lua` |
| `not_levels_data` | ugyanaz | Hiányzó / üres `Config.levels` | `libs/meta.lua` (`getDiscounts`) |
| `has_already_reached_the_limit` | ugyanaz | `abilityLimit` / labor plafon | `server/meta.lua`, `server/labor.lua` |
| `category_does_not_exist` | ugyanaz | Kliens cache-ben nincs kategória | `client/main.lua` (`getAbility`) |
| `meta_does_not_exist` | ugyanaz | Kliens: nincs ilyen jártasság név | `client/main.lua` |
| `reserved_meta_category` | ugyanaz | `login` / `logout` / `labor` tiltott írás / jártasság export | `server/meta.lua` |
| `meta_default_must_be_table` | ugyanaz | `registerMeta` 3. param nem tábla és nem `nil` | `server/meta.lua` |
| `meta_value_must_be_table` | ugyanaz | `setMeta` érték nem tábla | `server/meta.lua` |
| `meta_category_not_table` | ugyanaz | Meglévő kategória slot sérült (nem tábla) | `server/meta.lua` (`registerMeta` merge) |
| `diagnostics_run_not_found` | ugyanaz | `diagnosticsAdminGetRun` / `diagnosticsAdminCancelRun`: nincs ilyen `runId` a memóriabeli diagnosztikai futás tárolóban | `src/server/diagnostics.lua` |
| `profession_key_validation_failed` | ugyanaz | Admin diagnostics `profession-key-validation` teszt eredményében (`run.results[]`), ha invalid / hiányzó profession kulcsok voltak; **nem** a `getProfessionRegistry` / `getProfessionLevelProfile` exportok hibakódja | `src/server/diagnostics.lua` (`runProfessionKeyValidationAudit`) |
| `cleanup_scan_failed` | `'scan_failed'` | Profession meta cleanup: DB sorok beolvasása sikertelen | `src/server/professions.lua` (`cleanup_job_step`) |
| `mysql_missing` | `'mysql_missing'` | MySQL / oxmysql nem áll készen a `mysqlAwait` híváskor | `src/libs/helper_ecore.lua` |
| `admin_missing_auth_source` | angol szöveg (lásd `errors.lua`) | Admin API policy: hiányzik a kötelező `auth.source` | `src/libs/helper_ecore.lua` (`hf.adminApiCanAccess`) |
| `admin_invalid_auth_source` | angol szöveg | Admin API policy: érvénytelen / offline `auth.source` | `src/libs/helper_ecore.lua` |
| `admin_api_policy_denied` | angol szöveg | Admin API policy: egyik engedélyezési út sem engedélyezett | `src/libs/helper_ecore.lua` |
| `admin_invalid_web_player` | angol szöveg | Web admin NUI: érvénytelen játékos forrás | `src/libs/helper_ecore.lua` (`hf.webConsoleAccess`) |
| `admin_console_disabled` | angol szöveg | Web admin NUI ki van kapcsolva a configban | `src/libs/helper_ecore.lua` |
| `admin_web_unconfigured` | angol szöveg | `Config.web` jog policy nincs kitöltve (nincs engedélyezési út) | `src/libs/helper_ecore.lua` |
| `admin_web_denied` | angol szöveg | Web admin: policy elutasította a játékost | `src/libs/helper_ecore.lua` |
| `admin_audit_dual_policy_denied` | magyar szöveg | Denied audit lista: sem cleanup, sem diagnostics admin policy nem engedélyezett | `src/server/admin_denied_audit.lua` |
| `integrity_invalid_player` | magyar szöveg | Integritás futtatás: érvénytelen `source` | `src/server/integrity_check.lua` |
| `integrity_check_disabled` | magyar szöveg | `Config.integrityCheck.enabled` kikapcsolva | `src/server/integrity_check.lua` |
| `integrity_cooldown_active` | magyar szöveg | Integritás parancs cooldown alatt | `src/server/integrity_check.lua` |
| `integrity_progress_busy` | magyar szöveg | Már fut progress teszt ugyanahhoz a forráshoz | `src/server/integrity_check.lua` |
| `integrity_policy_misconfigured` | magyar szöveg | Integritás policy nincs konfigurálva (üres engedélyezési út) | `src/server/integrity_check.lua` |
| `integrity_policy_denied` | magyar szöveg | Integritás policy elutasította a játékost | `src/server/integrity_check.lua` |

**Új kód** esetén: először `libs/errors.lua`, majd e tábla és a `rg eCoreErr\.kulcs` keresés a repóban.

---

## 4. Terület szerinti „funkció → tipikus ok” (nem minden export, hanem csoportok)

### 4.1 Meta (szerver: `server/meta.lua`)

| Export / művelet | Gyakori `reason` | Ellenőrizd |
|------------------|------------------|-------------|
| `registerMeta` | `not_found_metadata` | Játékos betöltve? |
| | `reserved_meta_category` | Nem `login`/`logout`/`labor` kategória név |
| | `meta_default_must_be_table` | Harmadik param csak `nil` vagy `{}` / tábla |
| | `meta_category_not_table` | DB-ben sérült meta – kézi javítás / migráció |
| `setMeta` | `meta_value_must_be_table` | Második szintű érték mindig tábla |
| `getAbility` / `addAbility` / … | `reserved_meta_category` | Labor helyett labor exportok |
| | `not_found_metadata` | `registerMeta` / DB már létező kulcsok |
| | `not_valid_amount` | `addAbility` / `removeAbility` / `setAbility`: a `value` param nem szám (`tonumber` hiány) |

### 4.2 Labor (`server/labor.lua`)

| | |
|--|--|
| `the_system_is_turned_off` | `Config.systemMode.labor` |
| `not_found_metadata` | Nincs meta sor / nincs `labor` blokk |
| `not_valid_amount` | `addLabor` / `removeLabor`: nem pozitív szám; `setLabor`: nem nem negatív szám / NaN |
| `not_enough_labor` | `removeLabor`: `amount` nagyobb, mint `row.labor.val` |
| `has_already_reached_the_limit` | Labor plafon (`addLabor`) |

### 4.3 Inventory (bridge + override)

| | |
|--|--|
| Globál shared (`canCarryItem` / `canSwapItems`) | `too_heavy`, `not_enough_space`, `invalid_item_data`, `item_not_registered` – lásd §3 |
| QB kulcsok | `bridge/qb/server.lua` – `inventory_full`, `not_enough_items`, `removeItems` + `invalid_item_data` / `unknown_error` (lásd §3) |
| ESX / ox / qs / avp | `there_are_no_items_to_remove` **string** eltér – óvatos összehasonlítás; **ESX alap `removeItems`:** rossz sor → `invalid_item_data`, belső hiba → `unknown_error`. **Override** ox/qs/avp `server.lua`: `removeItems` sor-szerződés és `xPlayer` / `pcall` ugyanilyen minta |

### 4.4 Kliens cache (`client/main.lua`)

| | |
|--|--|
| `no_valid_meta_name` | `getAbility` / `getMeta`: nem string kategória vagy kulcs, illetve trim után üres |
| `category_does_not_exist` / `meta_does_not_exist` | Utolsó `e_core:sync` előtti hívás, rossz kulcs, vagy nincs ilyen jártasság név a kategóriában |
| `not_found_metadata` (`getLabor`) | Nincs labor blokk a cache-ben, nem tábla a `labor` slot, vagy `val` nem érvényes szám (NaN / hiány) |
| `e_core:sync` nem tábla payload / nem alkalmazható | Figyelmeztető `cLog`, a kliens meta cache megmarad (felülírás nélkül) |

### 4.5 Meta perzisztencia (`server/db.lua`, `server/db_migrations.lua`)

Itt **nincs** `false, reason` export – a hívások belsőek (`loadMeta`, `saveMeta`, migráció indulás).

| Jelenség | Mit jelent | Hol nézd |
|----------|------------|----------|
| Szerver indulás **error** migrációnál | DDL / `migration_applied` SELECT / `mark` sikertelen – részlet a konzolban és `hf.mysqlAwait` `cLog` | `server/db_migrations.lua`, oxmysql |
| `loadMeta: DB hiba` | `MySQL.scalar` nem futott le – játékosnak **nincs** betöltött runtime meta sor → később `not_found_metadata` lehet exportoknál | Ellenőrizd DB / kapcsolat; `e_core:loadMeta` újra játékos betöltéskor |
| `loadMeta: … nem érvényes JSON objektum` | Az `e_core` oszlop sérült / nem objektum JSON – **szándékosan** nem hívunk `prepareMeta` (ne írjon felül üres táblával) | Kézi DB javítás / backup |
| `saveMeta` / `saveAllMeta` DB hiba | Mentés nem történt; a memóriabeli meta változatlan marad (kivéve `saveMeta` siker + `dropMeta`) | Konzol + oxmysql |
| `getDbSchemaVersion` **0** | Üres migráció tábla, lekérdezés hiba, vagy még nem futott le olvasás – lásd `docs/PUBLIC_API_HU.md` §2 | `e_core_get_applied_migration_id`; ha `< ECORE_DB_SCHEMA_TARGET` → `cLog` warning |

---

## 5. „Végigfuttatom lépésenként” – minimális audit lista (fejlesztő)

Egy PR vagy release előtt **opcionálisan** (nem kötelező teljes teszt harness):

- [ ] `libs/errors.lua` ↔ `docs/PUBLIC_API_HU.md` §5 ↔ **ez a fájl** §3 – új kulcs mindhárom helyen.
- [ ] `rg "eCoreErr\."` – minden előfordulás indokolt, nincs elírás.
- [ ] Meta: `export_examples_server.md` **Contract** blokkok egyeznek a kóddal.
- [ ] Inventory: aktív override `server.lua` – `ok` / `unknown_error` ág logol-e (`cLog`).

---

## 6. Nem helyettesíti

- **Részletes paraméterlista** exportonként: `docs/AI_SUPPORT_REFERENCE_HU.txt`.
- **Operátori indulás:** `docs/SZERVER_OPERATOR_CHECKLIST_HU.md`.
- **Net esemény audit:** `docs/NET_EVENTS_AUDIT_HU.md`.

---

*Utolsó bővítés: meta szerződés + `messageIfLevelChange` szerver guard; a táblázatot új `eCoreErr` kulcsoknál frissítsd ugyanabban a PR-ban.*
