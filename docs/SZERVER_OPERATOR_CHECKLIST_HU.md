# e_core – szerver operátori checklist és kockázatlista (Fázis 0)

Egy oldalnyi ellenőrzés **éles vagy teszt szerver** indítás előtt / után. Részletes stack: **`docs/SUPPORTED_STACK_MATRIX_HU.md`**. Net / callback audit: **`docs/NET_EVENTS_AUDIT_HU.md`**.

**Mi ez a dokumentum?** **Üzemeltetői feladatlista**, nem „hiányzó dokumentáció” vagy fejlesztői backlog. A `[ ]` jelölések **minden indításnál / átállásnál** pipálható ellenőrzések: cél, hogy a szerveren ténylegesen lefusson, amit a doksik leírnak (ensure sorrend, log, jogosultságok). Ha valami nincs kipipálva, az **üzemeltetési teendő**, nem automatikusan „elmaradt doksi”.

---

## 1. Gyors checklist (másolható)

- [ ] **Egy** legacy core fut: alapból `es_extended` **vagy** `qb-core`. **Átnevezett core:** `setr e_core:framework "esx"` vagy `"qb"`, majd `setr e_core:framework_resource "<resource név>"`. Ha **mindkettő** fut: `setr e_core:framework "esx"` vagy `"qb"` – `auto` ilyenkor **hibával leáll** (szándékos).
- [ ] **`server.cfg` sorrend:** a választott core **előbb** `ensure`, mint `e_core` (item registry és bridge init).
- [ ] **`oxmysql`** telepítve és `ensure`-elve (a `fxmanifest.lua` `dependencies`-ben szerepel).
- [ ] **`ox_lib`** resource fut – a manifest `@ox_lib/init.lua`-t tölti; ha nincs indítva, az e_core **nem** indul tisztán. *(Jelenleg nincs a `dependencies {}` blokkban – üzemeltető felelősség.)*
- [ ] **Adatbázis:** MySQL elérhető; az e_core meta/labor táblák a szervered szerint létre vannak-e hozva (lásd telepítési / DB jegyzetek a saját workflow-dban).
- [ ] **Migrációs tábla:** indulás után létezik-e az `e_core_migrations` (automatikusan jön létre); opcionálisan: `exports.e_core:getDbSchemaVersion()` megegyezik-e a repóban lévő cél verzióval – **`docs/DB_MIGRATIONS_HU.md`**.
- [ ] **Inventory override:** ha ox / qs / avp stb., a megfelelő resource is fusson; ütköző két override ne írja felül egymást véletlenül (`fxmanifest` betöltési sorrend + `overrides/**` mappa).
- [ ] **Indulási log:** konzolon megjelenik-e az egységes sor (`logEcoreStartupSummary`): verzió, framework, inventory címke, `items=ready|timeout|pending`. `timeout` esetén: item registry / inventory integráció ellenőrzése.
- [ ] **Opcionális ConVarok** (ha nem az alap kell): `e_core:framework`, `e_core:framework_resource`, `e_core:items_ready_timeout_ms`, `e_core:items_ready_poll_ms`, `e_core:loadmeta_rate_ms` (net rate limit meta betöltéshez), `e_core:labor_tick_chunk` (labor auto tick: 0 = mind egyben, pl. 32–128 = hullámonkénti feldolgozás nagy online létszámnál).
- [ ] **Admin konzol (`/ecore_admin`):** `Config.operator.admin.enabled = true` + `Config.operator.identifiers` és/vagy ACE (`add_ace … ecore.admin allow`). Alap: `src/config/main.lua` → `Config.operator.admin` (a betöltéskor szintetizált `Config.web` mezők csak belső használatra maradnak).
- [ ] **Integritás parancs (`/ecore_diag`):** `Config.operator.integrityCheck.enabled = true`. Ha az admin NUI be van kapcsolva (`Config.operator.admin.enabled`), a jog a **`hf.webConsoleAccess`** (admin policy) szerint van; különben `integrityCheck` ACE + azonosítók. Részletek: `src/config/main.lua` → `Config.operator.integrityCheck`.

---

## 1.1 `Config` felülírás — **sekély merge** (kanonikus szabály)

Az e_core **`Config`** táblája több **Lua chunk**-ból épül fel (`fxmanifest.lua` `shared_scripts` sorrend: alapértelmezett bridge / `src/config/main.lua`, majd `overrides/**/config.lua` a glob szerint). **Nincs beépített rekurzív (mély) merge:** ha egy későbbi fájl **új táblát** rendel egy top-level kulcshoz (pl. `Config.operator = { … }`), az **lecseréli** az előző chunk ugyanilyen kulcs alatti **teljes** tábláját — az előző almezők, amiket nem másoltál át, **nem** maradnak „alapértelmezés alatt” automatikusan.

| Szabály | Gyakorlat |
|----------|-----------|
| **Utóbbi győz** | Ugyanazon top-level kulcsnál a **később betöltött** fájl értéke érvényesül. |
| **Beágyazott blokk = egy egység** | Pl. `Config.operator`: egy override **csak rész** admin beállítást ad vissza, de **nem** adja vissza a `integrityCheck` / `cleanup` ágakat → azok **eltűnhetnek** (üres / hiányzó), hacsak nem másolod be őket is az override-ba, vagy nem egy fájlban szerkeszted a teljes `operator` fát. |
| **Szintézis után** | `src/libs/config_check.lua` induláskor `Config.operator` alapján tölti a **`Config.web`**, **`Config.integrityCheck`**, **`Config.adminApi`** stb. mezőket — ha az `operator` „hiányos” maradt, **default** ágak léphetnek fel (`applyOperatorConfig` logika); üzemeltetői cél: **ne** támaszkodj véletlenszerű defaultokra élesben, hanem **tudatos** `operator` tábla. |
| **Mély merge igény** | Saját helper vagy **egyetlen** saját `config.lua`, ahol kézzel egyesíted a részfákat — az e_core **nem** ígér rekurzív merge-t. |

**Ellenőrzés override után:** `Config.operator` (és más felülírt top-level kulcs) tartalmazza-e az összes **számodra szükséges** alkulcsot; ha csak „diffet” írtál, hasonlítsd össze a **`src/config/main.lua`** referenciával.

---

## 2. Ismert kockázatok és mitigáció (rövid lista)

| Kockázat | Mitigáció a repóban / üzemeltetésben |
|----------|----------------------------------------|
| **Két core + `auto`** | indulás `error`; kényszerített `esx` / `qb` ConVar |
| **Végtelen várakozás** item registry-re | ConVar timeout + poll; **`CORE_READY`** indulás **`false`**, kész után `true` (0.1.7+); **`exports.e_core:isReady()`** mindig boolean; indulási összegzés log (`items=ready\|timeout\|pending`) |
| **`ox_lib` hiány** | `@ox_lib` init – kötelező indítani `e_core` előtt/vele együtt |
| **`dependencies` csak `oxmysql`** | ox_lib explicit `ensure` a cfg-ben; későbbi manifest bővítés opció |
| **Hamis net `loadMeta` / abuse** | forrás ellenőrzés + rate limit (`e_core:loadmeta_rate_ms`) |
| **Régi kliens `e_core:playerLoaded`** | csak szerver `TriggerEvent` + `AddEventHandler` – kliens hívás nem támogatott |
| **Jármű spawn** | csak `e_core:createVehicle` **callback** + forrás check |
| **Config „eltűnő” ágak** override után | §1.1 sekély merge: teljes `operator` (vagy érintett top-level kulcs) másolása / egy fájlban tartás; összevetés `src/config/main.lua`-val |

---

## 3. Példa `server.cfg` sorrend (irányadó)

```cfg
# Adatbázis + libek
ensure oxmysql
ensure ox_lib

# Pontosan egy legacy core ág:
ensure es_extended
# VAGY: ensure qb-core

# ECO core (eco scriptek előtt)
ensure e_core
ensure eco_crafting
```

---

## 4. Kapcsolódó dokumentumok

| Dokumentum | Tartalom |
|------------|----------|
| `docs/SUPPORTED_STACK_MATRIX_HU.md` | Tier 0–2, inventory / progress mátrix |
| `docs/FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md` | `e_core:framework`, defaults |
| `docs/PUBLIC_API_HU.md` | Publikus exportok, hibakódok |
| `docs/NET_EVENTS_AUDIT_HU.md` | Szerver net események, G audit |
| `README_HU.md` | Rövid bevezető, ensure megjegyzés |

---

*Fázis 0 (modernizációs terv): kockázatlista + operátori egy oldal – karbantartandó új kockázat / ConVar esetén.*
