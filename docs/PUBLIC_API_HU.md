# e_core – publikus API (szerződés v0.3)

Ez a fájl a **külső hívható** `exports.e_core:*` felületet és az **`eCore:`** facade **névsorát** rögzíti (forrásfájl szerint). Az alábbi táblákban **exportonként egy rövid „mire való”** sor is van (ugyanaz a szemantika, mint az **`export_examples_client.md`** / **`export_examples_server.md`** fájlokban – ott angolul, példakóddal). Viselkedés-részletek, paraméterek, GYIK: **`docs/AI_SUPPORT_REFERENCE_HU.txt`**. **`eCoreErr` / hibanyomozás lépésenként:** **`docs/ECORE_ERR_HIBA_NYOMON_HU.md`**. **Területenkénti stabilizálás (sorban, egy chat = egy blokk):** **`docs/TERULET_AUDIT_SORREND_HU.md`**.

| Meta | Érték |
|------|--------|
| **Resource verzió** | `fxmanifest.lua` → `version` |
| **Változások** | `changelog.md` – breaking változás = changelogban kiemelve |
| **Indulás** | `exports.e_core:isReady()` – item registry kész-e (client + server) |

**Override:** ugyanazon `eCore:` név felülírható `standalone/overrides/<mappa>/` alatt; a betöltési sorrend a mappanevek lexikografikus `**/shared.lua` / `client.lua` / `server.lua` globja szerint dől el.

---

## 1. Mindkét oldalon (client + server)

Forrás: `bridge/main.lua`. Itt csak a **`getFrameWork`** és **`getCore`** export van; a QB/ESX ciklusok **kizárólag** `RegisterNetEvent`-et hívnak, nem rejtett export-elágazás. **`eCore.helper`** a globális **`hf`**-re mutat (`libs/helper.lua` + `libs/helper_ecore.lua`), **`eCore.Err`** a globális **`eCoreErr`**-re (azonos string értékek a visszaadott `reason`-ökkel).

| Export | Mire való | Visszatérés | Megjegyzés |
|--------|-----------|-------------|------------|
| `getFrameWork` | Aktív keretrendszer azonosítója (ESX vagy QB). | `string` \| `nil` | `'esx'`, `'qb'`. Nincs core induláskor: `nil`. |
| `getCore` | Az egyesített **`eCore`** API / facade objektum (inventory, notify, target, stb. – lásd §6–§10). | `table` | |

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
| `getMeta` | Egy kategória összes eleme, vagy meta nélkül a teljes meta adatbázis. | `playerId`, `meta?` |
| `setMeta` | Egy kategória értékeinek felülírása táblával. | `playerId`, `meta`, `value` |
| `getLevel` | Szint számítása pontszámból (ugyanaz a logika, mint kliensen). | `value` |
| `getDiscounts` | Kedvezmény tábla pontszám alapján. | `value` |
| `getConfig` | Teljes `Config` olvasása. | – |
| `isReady` | Szerver oldalon is: item registry kész-e indulás / timeout után. | – |
| `getDbSchemaVersion` | Alkalmazott DB migrációk közül a legnagyobb `id` (`e_core_migrations`); séma „verzió” ellenőrzéshez. | – (visszaadás: max. migráció `id`; **0** ha üres tábla, lekérdezés sikertelen, vagy `MAX` `nil` – részlet és operátori sorrend: `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §4.5) |

---

## 4. Nem export – ajánlott belépés

```lua
FRAMEWORK = exports.e_core:getFrameWork()
eCore = exports.e_core:getCore()
eCoreConfig = exports.e_core:getConfig()
```

`imports/core.lua`. **`eCore.helper`** = **`hf`**: `libs/helper.lua` (általános segédek) + `libs/helper_ecore.lua` (e_core kiterjesztés: item normalizálás, registry várakozás, `mysqlAwait`, indulási log, net rate limit, `moneyFormat`). **`eCore.Err`** = `libs/errors.lua` → **`eCoreErr`** (azonos kulcsok / string értékek); külső resource összehasonlíthat: `reason == exports.e_core:getCore().Err.inventory_full`.

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
| `inventory_full`, `no_items_to_remove`, `inventory_is_empty`, `not_enough_items` | ugyanaz | QB bridge inventory |
| `there_are_no_items_to_remove` | `'there are no items to remove'` | ESX / ox / qs `removeItems` üres lista |
| `unknown_error` | ugyanaz | ox / qs removeItems hibaág; **ESX / QB `removeItems`:** hiányzó **`xPlayer`**; **ESX** továbbá **`removeInventoryItem`** kivétel (`pcall`); `eCore:createVehicle` (`bridge/global/server.lua`): érvénytelen `pos` / `model`, nem jött létre entitás, nincs érvényes **network id** (0 / `nil` a várakozás után), **network owner** továbbra is **-1**. **Override inventory szerver:** hiányos **`xPlayer`** / `pcall` kivétel a stack hívásban; **ox / qs `addItem`:** kivétel vagy olyan második érték, ami **nem** szerepel az `eCoreErr` stringek között (`cLog`); **avp** `canCarryItem` hívás kivétel, érvénytelen játékos forrás; **avp** stack egyedi hibaüzenet, ha nem egyezik egyetlen `eCoreErr` értékkel sem |
| `ok` | `'ok'` | sikeres többes remove végén |
| `vehicle_no_plate_data` | hosszú angol szöveg | `createVehicle` (global server) |
| `reserved_meta_category` | ugyanaz | `login` / `logout` / `labor` – szerver: tiltott kategória `registerMeta` / `setMeta` / jártasság exportoknál (`getAbility`, `setAbility`, …); laborhoz `getLabor` / labor exportok |
| `meta_default_must_be_table` | ugyanaz | `registerMeta` – harmadik param nem `nil` és nem tábla |
| `meta_value_must_be_table` | ugyanaz | `setMeta` – érték nem tábla |
| `meta_category_not_table` | ugyanaz | `registerMeta` merge: meglévő kategória slot nem tábla (sérült adat) |

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

**Shared (`bridge/esx/shared.lua`):** `convertPlayer`, `convertItems`.

**Client (`bridge/esx/client.lua`):** `triggerCallback`, `sendMessage`, `drawText`, `hideText`, `progressbar`, `cancelProgressbar`, `isLoggedIn`, `getInventory`, `getPlayerMaxWeight`, `getRegisteredItems`, `getPlayer`, `getAccounts`, `canInteract`, `setFuelLevel`, `vehicleKeys`, `setVehicleProperties`, `setVehiclePropertiesFromNetId`, `deleteVehicle`, `getClosestVehicle`.

**Server (`bridge/esx/server.lua`):** `createCallback`, `createUsableItem`, `sendMessage`, `drawText`, `hideText`, `addMoney`, `removeMoney`, `getAccounts`, `getInventory`, `getInventoryWeight`, `getPlayerMaxWeight`, `addItem`, `removeItem`, `removeItems`, `getRegisteredItems`, `getPlayer`, `itemBox`, `addCommands`.

---

## 10. `eCore:` – QB ág (`QB_CORE`)

**Shared (`bridge/qb/shared.lua`):** `convertItems`, `getRegisteredItems`, `convertPlayer`.

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
- [ ] További return literálok átvezetése `eCoreErr`-re (pl. egyedi override-ok, bridge edge case-ek).

---

## 13. Támogatott stack (összefoglaló)

Részletes mátrix: **`docs/SUPPORTED_STACK_MATRIX_HU.md`**.
