# e_core – modernizáció és megbízhatóság: felmérés és munkaterv

Ez a dokumentum **lépésenkénti, területek szerint bontott tervet** ad arra, hogyan lehetne **biztosabbá** tenni a különböző keretrendszerekkel való **kompatibilitást**, és hogyan lehetne **megbízhatóbbá** tenni magát az e_core-t. A megállapítások a jelenlegi repó szerkezetére és kódjára épülnek (verzió: `fxmanifest.lua` → `version` mező). A **2. fejezet (Architektúra döntés)** rögzíti a **SDK elsődlegességét** és az alternatív irányokat; a további fejezetek ehhez igazodnak.

---

## 1. Célok (mit értünk „modern” és „megbízható” alatt)

| Cél | Rövid definíció |
|-----|-----------------|
| **Kompatibilitás** | Előre látható viselkedés ESX / QB (és esetleges QBox) + gyakori inventory/progress/notify stack mellett; egyértelmű, ha valami nem támogatott. |
| **Megbízhatóság** | Nincs csendes állapotkorruptálás; hibák **észlelhetők** (log / felhasználói üzenet); kritikus inicializálás **nem akadhat** végtelen ciklusban; frissítések **kiszámíthatóan** felülírhatók (`standalone/`). |
| **SDK-szerű réteg** | Nem ad-hoc belső integráció: publikus API-szerződés, verziózás és changelog, dokumentált támogatott kombinációk, előre jelezhető indulás és hibák – külső consumer (ügyfél, saját resource) is biztonságosan ráépülhet. |
| **Modernizáció** | Explicit szerződés (API), verziózott integráció, minimális globális állapot a consumer oldalon, opcionálisan típus annotáció / lint / CI. |

---

## 2. Architektúra döntés: SDK irány (kötelező elv a további munkához)

Ez a fejezet **rögzíti a stratégiai választást**, hogy a modernizációs terv és a későbbi bővítések (theme, központi HUD-elrendezés, vevői bekötések) **ne** szétfolyanak több, egymásnak ellentmondó modell között.

### 2.1. Döntés: SDK-szerű felület elsődleges

**A projekt az SDK irányt választja** mint elsődleges fejlesztési és dokumentációs modellt:

- **Publikus szerződés:** `exports.e_core:*`, `eCore:` facade viselkedése, visszatérési értékek és hibakódok – verzióhoz kötve (`fxmanifest` `version`, `changelog.md`).
- **Központi belépés és kényelem:** a consumer-ek számára továbbra is érdemes **vékony belépési réteg** (`imports/core.lua` és későbbi bővítések, pl. theme / HUD registry helper) – nem helyettesíti az exportokat, hanem **egységes, dokumentált** használatot ad.
- **Élő dokumentáció:** `docs/AI_SUPPORT_REFERENCE_HU.txt` + szükség szerint téma-munkafájlok (pl. labor); export / szemantika változáskor a meglévő collaboration rule szerinti frissítés.
- **Cél:** az erre épülő szkriptek és a vevők **ugyanarra az API-ra** támaszkodjanak; a „hogyan kell bekötni” kérdés válasza **SDK**, ne csak tapasztalat vagy forkolt példa.

Ez **nem** jelenti, hogy minden belső fájl „publikus” lenne – továbbra is csak a **dokumentált** felület számít szerződésnek.

### 2.2. Mi marad mellette: `standalone/overrides` (üzemeltetési réteg)

Az **override** (manifest sorrend, `standalone/overrides/<stack>/`) **megmarad** és **nem ellentéte** az SDK-nak:

- Inventory, notify, progress, core client/server – **szerverenként cserélhető** implementáció, frissítésbiztosan a core repo mellett.
- Az SDK azt írja le, **mit** kell teljesítenie egy override-nak / bridge-nek (szerződés, hibakódok); az override a **hogyan** (konkrét ox / qs / egyéb hívások).

**Összefoglalva:** SDK = „mit hívok, mit várok”; override = „nálam ez az inventory hogyan válaszol”.

### 2.3. További irányok (nem elsődleges választás, de ismert alternatívák)

**A) Csak fájlalapú override, consumer import / vékony belépés nélkül**

- *Előny:* minimális absztrakció; közvetlen `exports.e_core` mindenhol.
- *Hátrány:* duplikált snippetek, nehezebb verziókövetés; theme / központi HUD / egységes helper **szétkenődik** a consumer resource-okban; a vevőnek nehezebb az „átlátható SDK” élmény.

**B) Belső architektúra teljes „ox_lib-szerű” modulrendszerre cseréje**

- *Előny:* egységes belső `require` / modul minta inspiráció a nagy könyvtárakból.
- *Hátrány:* FiveM resource-határok, betöltési sorrend és dupla init kockázata; az e_core **ügyfél-oldali** rugalmassága (override mappa, core nélküli fork) gyengülhet; nagyobb egyszeri refaktor költség a nyereményhez képest.

**C) Hibrid (a választott gyakorlat közelítése)**

- SDK **kívül** (export + docs + vékony `imports/`) + override **üzemeltetésre** + `ox_lib` **függőségként** (már a manifestben) inspirációra és közös utilokra – **nem** kötelező minden consumernek ox_lib belső API-jára épülnie.

### 2.4. Következmények a későbbi bővítésekre

A fenti döntéshez igazítva érdemes tervezni:

| Bővítés | SDK irányhoz illeszkedő megközelítés |
|--------|--------------------------------------|
| **Theme** | Központi config / token vagy NUI szerződés + dokumentált API (ne szétágazó CSS másolás consumerenként). |
| **HUD pozíció (DnD, központi réteg)** | Egy **registry** + exportok (mentés, alkalmazás); az erre épülő szkriptek csak azonosítót és offsetet kapnak a központi rétegtől. |
| **Vevő saját inventory / notify** | Ugyanazok az `eCore` / export hívások; a vevő **override**-t cserél – a szerződés az SDK doksiban marad. |
| **Import helper** | Bővíthető `imports/` vagy később `sdk/` névtér: verziózott, rövid fájlok, hivatkozás az `AI_SUPPORT_REFERENCE`-ben. |

### 2.5. Kapcsolat a dokumentum többi részével

A **„3. Területek”** fejezet alatti A–F (és további) pontok **ennek az SDK + override hibridnek** a megvalósítási részletei; új ötletnél először ellenőrizendő: **illeszkedik-e a 2. fejezetben rögzített döntéshez**, vagy külön architektúra-döntést igényel.

---

## 3. Területek (felosztás)

### A) Keretrendszer-felismerés és „egyetlen aktív bridge” szabály

**Állapot a kódban (frissítve):** A `fxmanifest.lua` a `bridge/framework_config.lua` + `bridge/*/config_defaults.lua` sorrendet használja. Két core + `e_core:framework` = `auto` esetén indulás **megáll** (`error`); kényszerített `esx` / `qb` esetén `ESX_CORE` / `QB_CORE` a választott ágnak megfelelően áll (lásd `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md`, `docs/REFAKTOR_PRIORITAS_UZEMTERV_HU.md`).

**Megvalósult (részletek a framework doksiban):** központi resolver + `e_core:framework` ConVar; két core + `auto` → `error`; kényszerített ág + mindkét core → figyelmeztető log. További finomítás: induláskor egy soros „aktív keretrendszer” összegző log (opcionális), README operátori checklist.

**Eredmény:** Előre jelezhető viselkedés, kevesebb „furcsa bug csak ezen a szerveren”.

---

### B) Publikus API szerződés (facade) és verziózás

**Állapot:** Consumer-ek `exports.e_core:getCore()`, `getFrameWork()`, `getConfig()` + sok `eCore:` metódus. **Központi szerződés:** `docs/PUBLIC_API_HU.md` (v0.3: exportok, `eCore:` névsor, **`eCoreErr` / `eCore.Err`**, deprec szabály). Paraméter / viselkedés mélység: **`docs/AI_SUPPORT_REFERENCE_HU.txt`** – változáskor mindkettő karbantartandó.

**Javasolt irány:**

1. **`API.md` vagy `docs/PUBLIC_API.md`:** táblázat: metódusnév, oldal (shared/client/server), paraméterek, visszatérési érték, hibakódok (`false, 'inventory_full'` stb.).
2. **Semver:** Resource `version` növelése, **CHANGELOG** szabály: breaking változás = major (vagy legalább „breaking” szekció).
3. **Deprecálás:** Régi exportok 1–2 minor ciklusig alias + `print`/`cLog` figyelmeztetés, majd eltávolítás.

**Eredmény:** A te és a Cursor AI munkád is **ugyanarra a szerződésre** hivatkozhat; kevesebb rejtett breaking change.

#### AI szupport referencia (élő dokumentum + záró audit)

A fájl: **`docs/AI_SUPPORT_REFERENCE_HU.txt`**. **Már a fejlesztés alatt** érdemes karbantartani: a Cursor AI és a támogatás így folyamatosan egy helyen látja a struktúrát és az API-t **magyarul**; új export / `eCore` metódus esetén ugyanabban a lépésben bővül. **Projekt zárásakor** érdemes egy **audit kört** (teljes paraméterlista, GYIK, verziószám egyeztetés a `fxmanifest`-tel).

**Kötelező tartalom (első verzió → folyamatosan tökéletesítve):**

1. **Kódstruktúra** – a `bridge/`, `standalone/overrides/`, `imports/`, `libs/` szerepe; hol érdemes módosítani vs. hol nem.
2. **Exportok részletes leírása** – minden publikus `exports.e_core:*` (és releváns `eCore:` metódus), **oldal** (client / server / shared), **paraméterek listája magyarázattal**, **visszatérési érték**, tipikus hibák / `nil` esetek.
3. **Kapcsolódó példák** hivatkozása – pl. `export_examples_client.md`, `export_examples_server.md`, `imports/core.lua` minta.

**Későbbi bővítés (nem blokkolja az első kiadást, de a fájl erre van előkészítve):**

- **GYIK** (gyakran ismételt kérdések): pl. „ox_inventory helyes bekötése”, `ensure` sorrend, `REGISTERED_ITEMS` / ready állapot, keretrendszer-választás.

**Célhatás:** az AI a **felhasználó nyelvén** tudjon **konkrét, verzióhoz köthető** választ adni (integráció, debug, API), összhangban a `PUBLIC_API` / changelog szerződéssel.

---

### C) Inicializálás, készenlét jelzés, hibatűrés

**Állapot:** A `server/main.lua` szálon **ismételve** hívja `eCore:getRegisteredItems()`-et, amíg `REGISTERED_ITEMS` „populated” nem lesz (`Wait(1000)`). Ha valamilyen inventory override / bridge hiba miatt ez **soha** nem teljesül, a ciklus **elméletileg végtelen** → erőforrás „félready” állapot, nehéz diagnosztika.

**Javasolt irány:**

1. **Időzített kilépés:** pl. N próbálkozás után `CORE_READY = false`, konzol + opcionális Discord webhook: „REGISTERED_ITEMS nem töltődött”.
2. **Export / esemény:** `exports.e_core:isReady()` vagy `e_core:server:ready` – consumer ne induljon el munkának addig.
3. **Kliens oldal:** Ugyanilyen minta (`client/main.lua`) – szinkron logika.

**Eredmény:** Megbízhatóbb indulás, kevesebb „néma” failure.

---

### D) Inventory / notify / progress – adapterek és tesztelhetőség

**Állapot:** Sok logika `bridge/global/shared.lua`-ban; inventory mezők `Config.fields`-ben; különböző override mappák (`standalone/overrides/ox_inventory`, `qs_inventory`, stb.). Ez **jó irány** (adapter), de a **mátrix** (ESX+ox, ESX+qb-inv, QB+ox, …) gyorsan nagy.

**Javasolt irány:**

1. **Támogatott kombinációk táblázata** a dokumentációban (lásd lentebb: **Tier 0**, Tier 1 / Tier 2 / Community).
2. **Egységes hibakód-készlet** (string konstansok egy `libs/errors.lua`-ban): `inventory_full`, `too_heavy`, stb. – consumer-ek ne string literált duplikáljanak.
3. **Minimális „szintetikus” teszt:** Lua unit nem mindig kényelmes FiveMnél; alternatíva: **egy headless nélküli** „smoke” resource vagy `ensure` utáni parancs, ami ellenőrzi: `getFrameWork`, `getRegisteredItems` nem üres, egy teszt item létezik.

**Eredmény:** Kompatibilitás **dokumentált mátrixként** kezelhető, nem csak tapasztalatként.

#### Inventory stratégia – keretrendszer-közvetlen útvonal és kockázatok (értékelés)

**Mi van már a bridge-ben (nyers funkciók, nincs külön grafikus inventory UI az e_core-ban):**

- **ESX** (`bridge/esx/server.lua`): `eCore:addItem` / `removeItem` / `getInventory` az **`xPlayer` ESX API**-ra épül (`addInventoryItem`, `removeInventoryItem`, `getInventory`, súly: `getWeight` + `Config.maxInventoryWeight`).
- **QB** (`bridge/qb/server.lua`): **`Player.Functions.AddItem` / `RemoveItem` / `SetInventory`** – QBCore player API.

A `standalone/overrides/ox_inventory` (és más) réteg ott kell, ahol a stack **nem** egyezik az alap API viselkedésével (metadata, slot, export, súly szabály).

**Tier 0 – „framework-only” (dokumentált, szűk célközönség):**

- Nincs (vagy nem használt) ox / qs / egyéb inventory override; **csak** a fenti keretrendszer-hívások.
- **Előny:** kis mátrix, kevés illesztés, előrejelezhető viselkedés.
- **CanCarry / csere-szabályok:** érdemes **egy helyen** szerződésben rögzíteni (`bridge/global/shared.lua` `canSwapItems` és kapcsolódó részek), keretrendszer szerinti súly/limitek.

**Tier 1+ – ox_inventory és társak (jellemző piaci valóság):**

- Sok szerveren az inventory **nem** „mellék script”, hanem **átvágja** az add/remove/weight útvonalat (export, esemény, core hook). Ilyenkor a **`xPlayer.addInventoryItem`** hívás továbbra is „keretrendszer API”, de a **tényleges szabályok** már az inventory resource-é lehetnek – **ütközés** vagy rejtett viselkedés, ha a Tier 0 feltételezést túllépjük.
- **ESX + metadata/slot:** az alap ESX API egyszerűbb, mint amit sok eco script elvár; a QB bridge **kézi** slot/mennyiség logikája (`removeItem` / `removeItems`) azt mutatja, hogy „csak core” mellett is **jelentős kód** marad az e_core-ban – nem tűnik el egy „saját inventory motorral” automatikusan.
- **QBX vs QBCore:** gyakran **qb-core** kompat réteg; külön harmadik bridge csak akkor éri meg, ha az API **tényleg** eltér – egyébként duplikáció.

**Stratégiai ajánlat (nagy refaktor nélkül):**

1. **Nem** feltétlenül új párhuzamos „saját inventory motor” első körben – a bridge **már** keretrendszer-közvetlen; erősíteni a **szerződést** (hibakódok, előfeltételek, mikor **kötelező** override).
2. A támogatási táblázatban külön sor: **Tier 0** vs **Tier 1 (ox, …)** vs community.
3. **Opcionális későbbi config** (implementáció külön döntés): pl. `Config.inventoryIntegration = 'framework' | 'auto' | 'explicit_override'` – `framework` módban **nem** tölti az ox override fájlokat, vagy **figyelmeztet**, ha az ox_inventory resource fut; így a „csak core hívások” **választható** üzemmód marad, nem kötelező minden vevőnek.

**Összegzés:** A keretrendszer-közvetlen útvonal **legyen az SDK-dokumentáció elsődleges, egyszerű útja** (összhangban a dokumentum **2. fejezetével**), de ez **nem váltja ki** teljesen az inventory adaptereket a piaci stack miatt; a cél: **tudatos, kevés kombináció** + egy helyen rögzített canCarry/add/remove szerződés.

**Dokumentált eCore primitívek (karbantartva az AI referenciában):** a `bridge/global/shared.lua` **`getAmountOfItems`**, **`canSwapItems`**, **`canCarryItem`**, súly/slot segédek – recepthez és „van elég alapanyag” kérdéshez **több stack** esetén a `getAmountOfItems` összesítés; részletes magyarázat és **QB + ox_inventory → override `canSwapItems` / `canCarryItem`** szabály: **`docs/AI_SUPPORT_REFERENCE_HU.txt`** → „Global bridge” → `shared.lua` blokk.

---

### E) Adat és perzisztencia (meta, labor, DB)

**Állapot:** `server/db.lua`, `server/meta.lua`, `server/labor.lua` – kritikus üzleti adat. **Labor (2026):** `server/labor.lua` közös guard + `syncRequest` az auto tickben; kliens `getLabor` nil-védelem – lásd `docs/LABOR_KEZELES_MUNKAFIL_HU.md` fókuszlista. **DB migrációk (Fázis 3):** `server/db_migrations.lua` – `e_core_migrations` tábla + soronkénti migrációk; induláskor `e_core_run_db_migrations()`; export `getDbSchemaVersion` – **`docs/DB_MIGRATIONS_HU.md`**. **MySQL hívások (3E, 2026):** `hf.mysqlAwait` (`libs/helper.lua`) – `pcall` + `cLog`; `server/db.lua` és `server/db_migrations.lua` **oxmysql `.await`** API (`update.await`, `prepare.await`, `scalar.await`, `query.await`).

**Javasolt irány:**

1. **Migrációk verziózva:** ✅ `e_core_migrations` + `ECORE_DB_MIGRATIONS` (Lua); új lépés = új `id` + doksi. Opcionális későbbi bővítés: nyers `.sql` fájlok `LoadResourceFile`-lal.
2. **Tranzakciók / hibakezelés:** ✅ Meta perzisztencia + migráció: `hf.mysqlAwait` + `.await`; további MySQL (más resource-ok) opcionálisan ugyanígy.
3. **Mentés ütemezése:** `ECO.syncRequested` jellegű logika felülvizsgálata – adatvesztés vs. terhelés egy rövid design jegyzetben.

**Eredmény:** Kevesebb adatintegritási incidens szerver újraindításkor / crashkor.

---

### F) Fejlesztői élmény (DX): globálok, lint, CI

**Állapot:** `imports/core.lua` globális `FRAMEWORK`, `eCore`, `eCoreConfig` – gyors, de **modern** kódbázisban gyakran `local Core = exports.e_core:getCore()` preferált. **LuaLS + luacheck + GitHub Actions (Fázis 4):** `.luarc.json`, `types/*.lua` stubok, `.luacheckrc`, `.github/workflows/lua_ci.yml` – részletek: **`docs/LUA_LS_AND_CI_HU.md`**.

**Javasolt irány:**

1. **Opcionális modul minta:** `local eco = require '???'` FiveM-ben korlátozott; maradhat az export, de **dokumentált** „best practice” snippet.
2. **LuaLS / EmmyLua:** ✅ induló stubok `types/` + `eCore` fő metódusok; bővítés új publikus API-val.
3. **CI:** ✅ `luacheck .` workflow; ✅ **fxmanifest helyi útvonalak:** `scripts/validate_fxmanifest.py` (lásd `docs/LUA_LS_AND_CI_HU.md`).

**Eredmény:** Kevesebb elírás, jobb AI autocomplete, átláthatóbb refaktor.

---

### G) Biztonság és események

**Állapot (frissítve):** `e_core:loadMeta` forrás + rate limit; `e_core:playerLoaded` **AddEventHandler** (nem kliens net); `e_core:createVehicle` nyitott NetEvent eltávolítva; callback + avp callback forrás check. Részletek: **`docs/NET_EVENTS_AUDIT_HU.md`**.

**Javasolt irány (továbbra is):**

1. ACE / szerepkörök kritikus műveletekre; további eco_* audit.
2. Eseménynevek dokumentálva (`e_core:` prefix ahol saját).

**Eredmény:** Kisebb abuse felület.

---

## 4. Munkaterv – fázisok (prioritás szerint)

### Fázis 0 – Rövid diagnosztika (1–2 nap)

- [x] **Dokumentált állapotkép:** framework belépő + defaults; részletek `docs/AI_SUPPORT_REFERENCE_HU.txt` „Keretrendszer-felismerés”.
- [x] **Kockázatlista + szerver operátor checklist:** `docs/SZERVER_OPERATOR_CHECKLIST_HU.md` (dual-core, item timeout, `ox_lib` / `dependencies`, net mitigációk, ensure példa, ConVarok).

### Fázis 1 – Megbízható indulás (közepes effort)

- [x] Framework **resolver** + ütközés-kezelés (`bridge/framework_config.lua`, `e_core:framework`; lásd 3A).
- [x] `REGISTERED_ITEMS` / `CORE_READY` ciklus: **timeout**, hibalog, `isReady` export + `eCore:isReady()` (részletek: `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md` 5. szakasz, `libs/helper.lua` `awaitItemRegistryReady`).
- [x] Egységes indulási log sor: `hf.logEcoreStartupSummary` (`libs/helper.lua`) – verzió, `framework`, `inventory`, `items` (ready|timeout|pending); szerver + kliens az item registry szál végén.

### Fázis 2 – Szerződés és dokumentáció (közepes effort)

- [x] **Publikus API** lista + deprecálási szabály (lásd 3B) – `docs/PUBLIC_API_HU.md` v0.3 (export + eCore névsor + `eCoreErr` + deprec).
- [x] **Támogatott stack mátrix** (lásd 3D) – `docs/SUPPORTED_STACK_MATRIX_HU.md` v0.1.
- [x] **AI szupport referencia** (`docs/AI_SUPPORT_REFERENCE_HU.txt`): élő karbantartás fejlesztés közben; **Fázis 2 audit (2026-04):** export szekció + `isReady` / kliens `getLabor` hibák, GYIK, globális events leírás (G), kliens item szál = `awaitItemRegistryReady`; mérvadó névsor továbbra is `PUBLIC_API_HU.md` §6–10 (lásd 3B alatti alcím).
- [x] **Hibakód** konstansok (lásd 3D) – `libs/errors.lua`, `eCore.Err`; bridge + fő override + meta/labor.

### Fázis 3 – Adat és biztonság (nagyobb effort, ütemezve)

- [x] DB migrációk + séma verzió (lásd 3E) – `server/db_migrations.lua`, `e_core_migrations`, `exports.e_core:getDbSchemaVersion`, `docs/DB_MIGRATIONS_HU.md`.
- [x] Kritikus net eventek auditja (lásd 3G) – `docs/NET_EVENTS_AUDIT_HU.md`, `libs/helper.lua` (`isValidPlayerSource`, `netRateLimit`), `server/meta.lua`, callbacks, `bridge/global/events/server.lua`.

### Fázis 4 – Modern DX (folyamatos)

- [x] LuaLS stub / `eCore` + környezet – `.luarc.json`, `types/fivem_ox_stubs.lua`, `types/e_core_facade.lua`, `types/resource_globals.lua` (lásd 3F, `docs/LUA_LS_AND_CI_HU.md`).
- [x] CI + `luacheck` – `.luacheckrc`, `.github/workflows/lua_ci.yml` (push/PR: main, master, develop).
- [x] **fxmanifest útvonalak** – `scripts/validate_fxmanifest.py` (CI lépés + lokális futtatás, `docs/LUA_LS_AND_CI_HU.md`).

---

## 5. Mérési javaslatok („bizonyítjuk, hogy jobb”)

- **Indulás:** sikeres / sikertelen init aránya logból (timeout esetek száma).
- **Runtime:** exception-szerű hibák száma (ha egységes error handler kerül be).
- **Kompatibilitás:** manuális vagy félig automata „matrix smoke” checklist minden release előtt.

---

## 6. Összefoglalás

Az e_core **jó irányt** mutat az **adapter + override** mintával, de a **megbízhatóság** főleg **explicit keretrendszer-választáson**, **indulási szerződésen** (ready / timeout), és **dokumentált támogatott kombinációkon** múlik. A **modernizáció** szempontjából a legnagyobb nyereség: **egy nyilvános API-doksi + semver**, kevesebb implicit globális feltételezés, és **adatréteg** rendezett migrációja. A **2. fejezet** szerinti **SDK elsődlegesség** (export + dokumentált belépés + override mint üzemeltetés) ad keretet a későbbi bővítéseknek (theme, központi HUD, vevői bekötések) anélkül, hogy minden új ötlet új architektúrát nyitna.

---

*Dokumentum készítve: belső kódfelmérés alapján. Konkrét implementáció előtt érdemes minden fázist a saját szerverparkotokkal és inventory választékkal validálni.*
