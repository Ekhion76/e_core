# e_core – Bridge réteg minőségi áttekintés

**Dátum:** 2026-04-27  
**Scope:** `src/bridge/`, kapcsolódó `fxmanifest.lua`, `src/libs/helper_ecore.lua`, `src/runtime/integrity/server.lua`, `overrides/` minták; kiegészítve: memória, hot reload / migráció / NUI, QBox adapter.  
**Kontextus:** FiveM framework bridge (ESX, QBCore; QBox jegyzetek). A dokumentum **összeállított áttekintés**; részletes üzemeltetési stratégia: [FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md](FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md), [FRAMEWORK_IDLE_GUARD_STRATEGY_HU.md](FRAMEWORK_IDLE_GUARD_STRATEGY_HU.md).

### Státusz jelölés (ebben a fájlban)

| Jel | Jelentés |
|-----|----------|
| **[Orvosolva 0.1.4]** | A szövegben említett konkrét hiba a repóban **meg van oldva** (lásd lenti lista; részletek: `changelog.md` [Unreleased]). |
| **[Orvosolva 0.1.5]** | QB bridge további nil-guard / `source` → `GetPlayer` feloldás (`fxmanifest` **0.1.5**; `changelog.md`). |
| **[Orvosolva 0.1.6]** | ESX szerver: pénz + inventory nil-guard / `source` → `GetPlayerFromId`, `invalid_player` / `0` / `{}` (`fxmanifest` **0.1.6**). |
| **[Orvosolva 0.1.7]** | `CORE_READY` indulás **`false`**; `eCore:isReady()` mindig **boolean** (`fxmanifest` **0.1.7**). |
| **[Nyitott]** | Javaslat vagy technikai adósság; **nincs** hozzá kötött kódjavítás a fenti patchekben. |
| **[Bevált]** | Nem feltétlenül „hiba”; szándékos vagy jó gyakorlat. A fejezetcímben **[Bevált / megfigyelés]** = üzemeltetési megállapítás, nem kódos „javítás”. |

**[Orvosolva 0.1.4] – rövid lista (fájl / viselkedés):**

- `src/bridge/framework_config.lua` – ha induláskor egyik legacy core sem `started`: **`_ECORE_INIT_FAILED = true`** (korábban `false` maradt).
- `src/bridge/esx/client.lua` + `src/bridge/global/callbacks/server.lua` – ESX kliens **`getRegisteredItems`**: szerver callback, nem játékos inventory `convertItems`; üres válas: **`false`**, **`eCoreErr.not_ready`**.
- `src/libs/helper_ecore.lua` – **`awaitItemRegistryReady`**: `REGISTERED_ITEMS` csak **nem üres tábla** esetén íródik (a `false` / `not_ready` nem ragad be).
- `src/bridge/qb/server.lua` – **0.1.4:** `addMoney` → **`invalid_player`** ha nil játékos; **0.1.5:** további QB metódusok – lentebbi lista.
- `src/bridge/esx/server.lua` – **0.1.4:** `getAccounts` tábla nil-safe **`0`**; **0.1.6:** pénz + inventory + `source` szám – lentebbi ESX lista.
- `src/libs/errors.lua` – új kulcsok: **`not_ready`**, **`invalid_player`**.

**[Orvosolva 0.1.5] – rövid lista (`src/bridge/qb/server.lua`):**

- **`removeMoney`:** nil játékos → **`false`**, **`eCoreErr.invalid_player`** (ugyanaz, mint `addMoney`).
- **`getAccounts`:** `source` szám → `GetPlayer`; nil / hiányzó `money` tábla → **`0`**; számla kulcs → **`or 0`**.
- **`getInventory`:** `source` szám → `GetPlayer`; nil / nem tábla `items` → **`{}`**.
- **`addItem` / `removeItem` / `removeItems`:** `source` szám feloldás; nil játékos → **`invalid_player`** (`removeItems` korábban `unknown_error` volt nilnél).

**[Orvosolva 0.1.6] – rövid lista (`src/bridge/esx/server.lua`):**

- **`addMoney` / `removeMoney`:** nil `xPlayer` → **`false`**, **`invalid_player`** (korábban csak `false`).
- **`getAccounts`:** `source` szám → `GetPlayerFromId` (korábban a szám miatt csendben **0**).
- **`getInventory` / `getInventoryWeight`:** szám feloldás; nil → **`{}`** / **`0`**.
- **`addItem` / `removeItem` / `removeItems`:** szám feloldás; nil → **`invalid_player`** (`removeItems` korábbi `unknown_error` nil helyett).

**[Orvosolva 0.1.7] – rövid lista:**

- `src/runtime/bootstrap/client/main.lua`, `src/runtime/bootstrap/server/main.lua` – **`CORE_READY`** indulás **`false`** (korábban `nil`).
- `src/bridge/global/shared.lua` – **`eCore:isReady()`** → **`CORE_READY == true`** (mindig boolean).
- `src/runtime/exports/client.lua`, `src/runtime/exports/server.lua` – **`isReady`** export a facade booleanját adja.

---

## 1. Globális állapot és framework detekció

**Felismerés:** `GetConvar('e_core:framework', 'auto')` (`auto` | `esx` | `qb`), opcionálisan `e_core:framework_resource` (csak ha nem `auto`). A legacy core resource állapota: `GetResourceState(...) == 'started'`.

```30:66:src/bridge/framework_config.lua
local fw = string.lower(trim(GetConvar('e_core:framework', 'auto')))
-- ...
local esx_started = GetResourceState(scan_esx) == 'started'
local qb_started = GetResourceState(scan_qb) == 'started'
```

**Két core + `auto`:** `enterIdle()` – `FRAMEWORK = nil`, üres `eCore`, `_ECORE_INIT_FAILED = true`.

```16:27:src/bridge/framework_config.lua
local function enterIdle(msg)
    _G._ECORE_INIT_FAILED = true
    FRAMEWORK = nil
    ESX_CORE = false
    QB_CORE = false
    Config = {}
    eCore = {}
    print(('^1%s^7'):format(msg .. ' [e_core state=IDLE]'))
    return
end
```

**Két core + explicit `esx`/`qb`:** figyelmeztetés, majd kényszerített ág – robusztus választás üzemeltetés szempontjából.

```70:91:src/bridge/framework_config.lua
if esx_started and qb_started then
    if fw == 'auto' then
        enterIdle(
            ('[e_core] %s és %s is fut. Csak egy legacy core. Állítsd: setr e_core:framework "esx" vagy "qb".%s'):format(scan_esx, scan_qb, hint)
        )
        return
    end
    print(('[^3e_core^7] FIGYELMEZETÉS: mindkét core fut; aktív ág kényszerítve: ^2%s^7.'):format(fw))
    -- ...
```

**Versenyhelyzet:** A detekció egy pillanatképet vesz az `e_core` **shared** szkriptfázisában. Ha mindkét core *később* indul el, mint az `e_core`, a „nincs core” ág futhat. Ha mindkettő már `started`, de az `e_core` korábban indult, a sorrend szerverfüggő – tipikusan kevésbé probléma, ha az `ensure` sorrend stabil.

### [Orvosolva 0.1.4] „Nincs started core” vs. IDLE

Korábban: ha egyik core sem `started` az `e_core` betöltésekor, **nem** hívódott `enterIdle()`, `_ECORE_INIT_FAILED` **false** maradt.

**Javítás:** `_G._ECORE_INIT_FAILED = true` beállítása ugyanazon ágon, mint a `FRAMEWORK = nil` stub (lásd `framework_config.lua` a print után). Így az `isReady` / guard útvonalak összhangban vannak az `enterIdle()` szemantikájával.

**További jegyzet:** Külön `_ECORE_NO_FRAMEWORK` kulcs továbbra is opcionális, ha finomabb diagnosztikát szeretnél a consumerben.

### [Orvosolva 0.1.7] `isReady()`

A facade **mindig boolean**-t ad: **`true`** csak ha a registry szál sikeresen befejeződött; **`false`** induláskor, timeoutnál, IDLE-nél. A `CORE_READY` globál indulás **`false`** (`client`/`server` `main.lua`).

```371:373:src/bridge/global/shared.lua
function eCore:isReady()
    return CORE_READY == true
end
```

```319:327:src/libs/helper_ecore.lua
function hfe.awaitItemRegistryReady(logTag)
    logTag = tostring(logTag or 'REGISTERED ITEMS')
    if _G._ECORE_INIT_FAILED == true then
        CORE_READY = false
        -- ...
        return false
    end
```

- **[Bevált]** IDLE esetén a várakozás nem timeoutol feleslegesen: azonnal `CORE_READY = false`.
- **[Bevált]** Consumer minta: `exports.e_core:isReady()` vagy `eCore:isReady()` – mindkettő **tiszta boolean** (0.1.7+).

---

## 2. API design és verziókövetés

**Publikus slice:** `ecore_lifecycle.lua` sekély merge: `ecoreVersion`, `bridgeContract`, majd `framework`, `config`, `i18n`, `util`, opcionálisan `log.discord`.

**[Orvosolva 0.1.9]** **`eCore.ecoreVersion`:** `GetResourceMetadata(GetCurrentResourceName(), 'version', 0)` (üres → `0.0.0`). **`eCore.bridgeContract`:** `schemaVersion` (séma bump, ha a tábla alakja változik), `resource`, `lifecycleMergedKeys` — gépi consumer ellenőrzés; nem helyettesíti a `PUBLIC_API` névsort, csak a **lifecycle merge** kulcsait rögzíti.

```100:150:src/bridge/ecore_lifecycle.lua
function eCoreLifecycle_buildPublicAPI()
    local out = {}
    out.ecoreVersion = ...
    out.bridgeContract = { schemaVersion = ..., resource = ..., lifecycleMergedKeys = { ... } }
    -- framework, config, i18n, util, optional log...
    return out
end
```

**[Nyitott]** Aszimmetria példák (forrás / aláírás; teljes szimmetria nincs cél):

| Terület | Megjegyzés |
|--------|------------|
| `getRegisteredItems` | QB: `qb/shared.lua`. ESX: `esx/server.lua` + `esx/client.lua` – más forrás; a kliens oldali **hibás inventory-fallback** viszont **[Orvosolva 0.1.4]** (callback + `not_ready`). |
| `convertPlayer` | ESX: 2 param (`playerData`, `newJob`); QB: 3 param (+ `newGang`) – `esx/shared.lua` vs `qb/shared.lua`. |

### [Orvosolva 0.1.4] ESX kliens `getRegisteredItems`

Korábbi hiba: `REGISTERED_ITEMS` hiányában a kliens a játékos inventoryra hívott `convertItems`-et (rossz szemantika).

**Javítás:** szerver `lib.callback` (`e_core:getRegisteredItems`, `bridge/global/callbacks/server.lua`) + kliensen `lib.callback.await`; ha továbbra sincs adat: **`false`**, **`eCoreErr.not_ready`**. A `helper_ecore.awaitItemRegistryReady` csak **nem üres táblát** ír a globális `REGISTERED_ITEMS`-be (`helper_ecore.lua`).

### [Orvosolva 0.1.4–0.1.6] QB és ESX szerver – játékos feloldás és nil-guard

**QB – 0.1.4 `addMoney`:** `GetPlayer` után `if not xPlayer then return false, eCoreErr.invalid_player end`.

**QB – 0.1.5:** `removeMoney`; továbbá `getAccounts` / `getInventory` (`source` szám + nil-safe visszatérések), `addItem` / `removeItem` / `removeItems` (`invalid_player`, `removeItems` nilkor korábbi `unknown_error` helyett).

**ESX – 0.1.6:** ugyanilyen `invalid_player` / `source` → `GetPlayerFromId` / `0` / `{}` szerződés a szerver `bridge/esx/server.lua` pénz + inventory metódusain (`addMoney`, `removeMoney`, `getAccounts`, `getInventory`, `getInventoryWeight`, `addItem`, `removeItem`, `removeItems`).

### [Nyitott] Bridge verzió a consumernek

A `getCore()` nem ad külön `bridgeVersion` / `contractVersion` mezőt; a resource `version` meta a manifestben és a `hfe.logEcoreStartupSummary` logban jelenik meg.

**Javaslat:** `eCoreLifecycle_buildPublicAPI()`-ba pl. `ecoreVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)`, opcionálisan `bridgeContract = 1`.

---

## 3. Overrides rendszer és bővíthetőség

**Betöltési sorrend** (`fxmanifest.lua`): bridge ESX/QB → **utána** `overrides/**` → események → `src/bridge/main.lua` → `src/runtime/...`.

```39:52:fxmanifest.lua
    'src/bridge/esx/client.lua',
    'src/bridge/qb/client.lua',

    'overrides/**/shared.lua',
    'overrides/**/client.lua',

    'src/bridge/global/events/client.lua',
    -- ...
    'src/bridge/main.lua',
```

**[Bevált]** Az `eCore` metódusok felülírhatók az override fájlokban (új `function eCore:...` definíció).

**„Ősmetódus” / fallback:** Nincs beépített wrapper; a Lua chunk sorrendje alapján a régi referenciát felülírás előtt kell menteni, pl.:

```lua
local _orig = eCore.getRegisteredItems
function eCore:getRegisteredItems()
  return _orig(self)  -- vagy egyéni logika után
end
```

**Config merge (sekély):** Több fájl egymás után fut; ugyanazon **top-level** kulcsnál az utóbbi chunk **teljes táblacserét** jelenthet — **rekurzív merge nincs**. **[Dokumentálva 0.1.11]** Kanonikus szabály + operátori checklist: **`docs/SZERVER_OPERATOR_CHECKLIST_HU.md` §1.1**, összefoglaló **`docs/PUBLIC_API_HU.md`** (Override blokk alatti `Config` bekezdés).

**Új inventory (pl. Quasar):** Minta: `overrides/example_custom_inventory/` – saját globál flag + `config.lua` + `shared.lua` / `server.lua` / `client.lua`, `GetResourceState('<resource>') == 'started'`.

```1:6:overrides/example_custom_inventory/config.lua
CUSTOM_INVENTORY = GetResourceState('custom_inventory') == 'started'
if not CUSTOM_INVENTORY then return end
```

**[Bevált]** Az `e_core` mag forrása nélkül is bővíthető, ha a bridge felületet (`eCore:getInventory`, `getRegisteredItems`, …) lefeded – ugyanígy működik az `ox_inventory` override is.

---

## 4. Hibakezelés és diagnosztika

**[Nyitott]** A bridge egyéb pontjain még lehet `false` / `0` / `nil` `eCoreErr` nélkül, illetve `(ok, err)` vs. egyszeri visszatérés keveredése – a publikus metódusokra érdemes egységes szerződést írni (lásd changelog 0.1.4–0.1.6 bridge sorok). **Részben (0.1.8):** ESX / QB **kliens** jármű stubok (`setFuelLevel`, `vehicleKeys`, `setVehicleProperties`, `setVehiclePropertiesFromNetId`) — `PUBLIC_API` §5 / §9.

### [Orvosolva 0.1.4–0.1.6] ESX `getAccounts` és társai

**0.1.4 – tábla szerződés:** `xPlayer` és `xPlayer.accounts` ellenőrzés; hiány esetén **`0`**, nincs runtime error.

**0.1.6 – `source` szám:** `GetPlayerFromId` feloldás `getAccounts` / `getInventory` / `getInventoryWeight` előtt; továbbra is **`0`** / **`{}`**, ha nincs játékos vagy nincs `accounts`.

**Integrity / env lépés:** `getFrameWork()` + `isReady` + item convert diagnosztika – alap környezet; nem teszteli külön az összes exportot / mindkét framework ágat egy futásban.

```462:469:src/runtime/integrity/server.lua
    if only == 'env' then
        -- ...
        local fw = exports[GetCurrentResourceName()]:getFrameWork()
        appendLine(lines, ('Framework: %s'):format(tostring(fw)))
        appendLine(lines, ('isReady (szerver): %s'):format(tostring(ready)))
```

---

## 5. Teljesítmény és memória

**[Nyitott]** QB `convertPlayer` visszaállítja a `playerData.Functions` referenciát – minimális self-referencia jelleg; hosszú életű cacheknél tudatos tervezés.

**[Nyitott]** **RegisterNetEvent:** FiveM-ben resource stopkor a handler általában lekerül – klasszikus cleanup pattern kevésbé kritikus. Manuális unsubscribe: `onResourceStop`-ban külön kezelendő (jelenleg nincs explicit remove a `main.lua`-ban).

**[Nyitott]** **NUI:** `eCoreNui.isReady()` egyszerű boolean; nincs Lua oldali üzenetsor – extrém `SendNUIMessage` flood esetén a weboldal oldalon kell backpressure.

```7:12:src/runtime/web_bridge/ecore_nui.lua
function eCoreNui.isReady()
    return shellReady
end
```

---

## 6. Karbantarthatóság és tesztelhetőség

**[Nyitott]** A bridge szorosan kötődik az `ESX` / `QBCore` globálokhoz és az `exports[resource]` hívásokhoz – unit teszt mock nélkül nehéz. Vékony „port” réteg (interface tábla), amit a bridge feltölt framework-specifikus implementációval; tesztben csak a port mockolódik.

**[Bevált]** `imports/sdk/shared/core.lua` – egyértelmű consumer belépés: `getCore()` + kurált mezők.

```1:8:src/imports/sdk/shared/core.lua
eCore = exports.e_core:getCore()
FRAMEWORK = eCore.framework
eCoreConfig = eCore.config
```

**Dokumentáció szinkron:** Aszimmetria (`convertPlayer` arity, stb.) **[Nyitott]** részben; az ESX kliens `getRegisteredItems` **[Orvosolva 0.1.4]** – lásd `PUBLIC_API_HU.md` §9 / §5, `NET_EVENTS_AUDIT_HU.md` §4.

**[Nyitott] Új framework (QBox) konvenció:** `framework_config.lua` + `e_core_apply_*_config` + `src/bridge/<fw>/` + manifest sorrend + `ecore_framework_resource_*` bővítés – jelenleg csak `esx`/`qb` kulcs van.

---

## 7. [Nyitott] Konkrét QBox bővítéshez

**Strukturális lépések:**

1. **Új ág vagy QB-kompatibilitás:** Ha a QBox `qb-core` kompat exportot ad (`GetCoreObject`), elég lehet a `framework_resource` + eseménynév ellenőrzés; ha `qbx_core` / más export, külön `e_core_apply_qbx_config()` + `FRAMEWORK = 'qbx'` (vagy `'qb'` + `runtime.frameworkVariant`).
2. **Eseménynevek:** QB bridge prefixeli a DrawText eseményt a registry alapján – QBoxnál ellenőrizd a tényleges client event neveket; szükség esetén override vagy ConVar-alapú template.

```33:36:src/bridge/qb/server.lua
    function eCore:drawText(source, message, position, mType)
        -- ...
        TriggerClientEvent(('%s:client:DrawText'):format(ecore_framework_resource_qb()), source, message, position)
```

3. **Adatmodell:** QBox gyakran megtartja a `PlayerData` / `Functions` mintát, de a pénz/inventory réteg változhat – `convertPlayer` + inventory override kombináció vagy explicit player facade.

**[Bevált]** A `convertPlayer` + `normalizePlayerJobForEcore` már egy **fél absztrakció**.

**[Nyitott]** Javaslat: explicit `IPlayerFacade` tábla (getIdentifier, getJob, getInventoryView), amit `esx`/`qb`/`qbx` modul tölt fel – a domain kód ne hívjon `ESX.GetPlayerFromId`-t közvetlenül.

---

## 8. [Bevált / megfigyelés] Memória – a bridge tipikusan nem a szűk keresztmetszet

Összképben (tipikus szerver heap sorrendben) a **bridge réteg** csak kis részt ad: vékony táblák és függvényreferenciák. A domináns többlet jellemzően:

- **Profession registry** cache és kapcsolódó táblák (sok profession / nagy registry esetén különösen).
- **Item convert pipeline** és a **regisztrált item definíciók** teljes tárolása (`REGISTERED_ITEMS` jellegű struktúrák).
- **NUI:** Svelte bundle + Chromium runtime a kliensen.

A pontos MiB arányokat érdemes egyszer mérni (`collectgarbage`, profiler), de **optimalizálási fókusz:** előbb registry + item pipeline + NUI, utána a bridge finomhangolása.

---

## 9. [Nyitott] Kiegészítő üzemeltetési és UI témák

### 9.1 Hot reload (`ensure` / resource restart)

- **`e_core` újraindítása:** új Lua kontextus; a bridge `RegisterNetEvent` regisztrációk a `src/bridge/main.lua` (és framework event fájlok) betöltésekor **újra egyszer** lefutnak – ugyanazon resource példányán **nem** maradnak „dupla” bridge handlerek.
- **Duplikáció gyakoribb forrása:** **consumer** vagy más resource, amelyik `AddEventHandler` / saját net eseményt **minden** `onResourceStart`-nál újra regisztrál védelem nélkül. Ott idempotencia (`if _registered then return end`) vagy célzott `RemoveEventHandler` indokolt.
- **Dokumentáció:** saját net felület: [NET_EVENTS_AUDIT_HU.md](NET_EVENTS_AUDIT_HU.md). Az `e_core` meta mentés `onResourceStop`-on: `src/runtime/meta/server.lua` (resource stop → `saveAllMeta`).

### 9.2 Cross-framework adatmigráció (pl. ESX → QB)

Ez **nem a bridge**, hanem **adat-szerződés + migrációs terv**:

- Ha a DB-ben tárolt e_core meta **framework-független kulcsok** (profession, labor, stb.), a váltás főleg **azonosító-leképezés** (`identifier` vs `citizenid`) és játékos feloldás kérdése.
- Ha JSON / meta **framework-specifikus** mezőket tartalmaz, váltáskor **egyszeri transzformációs migráció** szükséges; nem feltételezhető automatikus kompatibilitás.
- Konkrét táblák (pl. `users` + e_core JSON mezők) kompatibilitását a tényleges séma alapján külön dokumentálni és tesztelni.

### 9.3 NUI bridge – üzenetflood és backpressure

A kliensen `SendNUIMessage` több modulból hívódik (`src/runtime/bootstrap/client/main.lua`, integrity, hud, web, stb.); **Lua oldalon nincs beépített üzenetsor vagy throttle**. Sűrű, egymás utáni üzenetek (pl. meta `UPDATE` tick szerűen) terhelhetik a CEF-et.

**Javasolt gyakorlat:** azonos típusú üzenetek **összevonása** (debounce / „csak utolsó állapot” frame-enként), progress tick inkább natív vagy ox_lib, ne NUI-on keresztül; szükség esetén a Svelte oldalon queue + `requestAnimationFrame` szintű feldolgozás.

---

## 10. [Nyitott] QBox – thin adapter (pontosítás a 7. fejezethez)

A QBox ökoszisztéma verziófüggő; tipikus **irányú** eltérések a klasszikus QBCore bridge-től (a pontos API-t mindig a futó core exportjaihoz igazítsd):

1. **Játékos feloldás:** `QBCore.Functions.GetPlayer` helyett más entrypoint (pl. központi `QBX` / `exports` tábla – forkonként változik).
2. **Eseményprefix:** `qb-core:` helyett `qbx:` (vagy más névtér) – a QB bridge már paraméterezhető resource névvel (`ecore_framework_resource_qb()`); QBoxnál ellenőrizd a kliens eseményneveket.
3. **`PlayerData`:** előfordulhat, hogy nincs ugyanaz a `.Functions` metatábla / wrapper, mint a régi QB-nél – a `convertPlayer` és az inventory hívások ezt figyelembe vegyék.

**Javasolt szerkezet:** egy vékony `bridge/adapters/qbx_adapter.lua` (vagy hasonló elnevezés), ami a **QB bridge által már jól kezelt** részekre delegál, és csak a QBox-specifikus eltérésekre ad átalakítást – **ne** másold át a teljes `qb/server.lua` / `qb/client.lua` tartalmat. Így QBox frissítéskor csak az adapter és az esemény/resource mapping érintett.

---

## Összegzés (prioritás)

| Státusz | Téma |
|--------|------|
| **[Orvosolva 0.1.4]** | „Nincs core induláskor”: `_ECORE_INIT_FAILED = true` (`framework_config.lua`). ESX kliens `getRegisteredItems`: szerver `e_core:getRegisteredItems` callback, `not_ready`, `helper_ecore` tábla-guard. ESX `getAccounts`: tábla nil-safe **`0`**. Új `eCoreErr`: `not_ready`, `invalid_player`. |
| **[Orvosolva 0.1.5]** | QB `removeMoney` + `getAccounts` / `getInventory` / `addItem` / `removeItem` / `removeItems`: nil-guard, `source` szám feloldás, `invalid_player` / `0` / `{}` szerződés (`bridge/qb/server.lua`). |
| **[Orvosolva 0.1.6]** | ESX szerver: `addMoney` / `removeMoney` + inventory/pénz segédek – ugyanilyen `invalid_player` / szám feloldás / `0` / `{}` (`bridge/esx/server.lua`). |
| **[Orvosolva 0.1.7]** | `CORE_READY` indulás `false`; `eCore:isReady()` mindig boolean; export `isReady` (`main.lua`, `global/shared.lua`, `exports.lua`). |
| **[Orvosolva 0.1.9]** | `getCore()` facade: **`ecoreVersion`** + **`bridgeContract`** (`ecore_lifecycle.lua` merge; `fxmanifest` **0.1.9**). |
| **[Dokumentálva 0.1.11]** | `Config` sekély merge — `SZERVER_OPERATOR` §1.1, `PUBLIC_API` §1, `BRIDGE_LAYER…` §3 (`fxmanifest` **0.1.11**). |
| **[Részben 0.1.10]** | Globális `hasItem`, ESX `removeItems` pcall, ox/qs/avp szerver override inventory ágak — részletezett `eCoreErr` (`PUBLIC_API` §5). |
| **[Nyitott]** | Bridge API / hibakód aszimmetria (további metódusok / `createVehicle` részletezés később); detektálás pillanatkép-alapú; QBox; NUI throttle; `IPlayerFacade`. |
| **[Bevált]** | ConVar-alapú választás + két core + auto → kontrollált IDLE (`framework_config.lua`); explicit fw kényszerítés két core mellett; override sorrend teljes metóduscserehez (`fxmanifest.lua`); `example_custom_inventory` minta új inventoryhoz; `imports/sdk/shared/core.lua` consumer minta. |
