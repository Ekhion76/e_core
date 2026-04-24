# e_core – szerver operátori checklist és kockázatlista (Fázis 0)

Egy oldalnyi ellenőrzés **éles vagy teszt szerver** indítás előtt / után. Részletes stack: **`docs/SUPPORTED_STACK_MATRIX_HU.md`**. Net / callback audit: **`docs/NET_EVENTS_AUDIT_HU.md`**.

---

## 1. Gyors checklist (másolható)

- [ ] **Egy** legacy core fut: `es_extended` **vagy** `qb-core` (QBox gyakran qb-core kompat réteggel). Ha véletlen **mindkettő** fut: `setr e_core:framework "esx"` vagy `"qb"` – `auto` ilyenkor **hibával leáll** (szándékos).
- [ ] **`server.cfg` sorrend:** a választott core **előbb** `ensure`, mint `e_core` (item registry és bridge init).
- [ ] **`oxmysql`** telepítve és `ensure`-elve (a `fxmanifest.lua` `dependencies`-ben szerepel).
- [ ] **`ox_lib`** resource fut – a manifest `@ox_lib/init.lua`-t tölti; ha nincs indítva, az e_core **nem** indul tisztán. *(Jelenleg nincs a `dependencies {}` blokkban – üzemeltető felelősség.)*
- [ ] **Adatbázis:** MySQL elérhető; az e_core meta/labor táblák a szervered szerint létre vannak-e hozva (lásd telepítési / DB jegyzetek a saját workflow-dban).
- [ ] **Migrációs tábla:** indulás után létezik-e az `e_core_migrations` (automatikusan jön létre); opcionálisan: `exports.e_core:getDbSchemaVersion()` megegyezik-e a repóban lévő cél verzióval – **`docs/DB_MIGRATIONS_HU.md`**.
- [ ] **Inventory override:** ha ox / qs / avp stb., a megfelelő resource is fusson; ütköző két override ne írja felül egymást véletlenül (`standalone/overrides/**` sorrend).
- [ ] **Indulási log:** konzolon megjelenik-e az egységes sor (`logEcoreStartupSummary`): verzió, framework, inventory címke, `items=ready|timeout|pending`. `timeout` esetén: item registry / inventory integráció ellenőrzése.
- [ ] **Opcionális ConVarok** (ha nem az alap kell): `e_core:framework`, `e_core:items_ready_timeout_ms`, `e_core:items_ready_poll_ms`, `e_core:loadmeta_rate_ms` (net rate limit meta betöltéshez), `e_core:labor_tick_chunk` (labor auto tick: 0 = mind egyben, pl. 32–128 = hullámonkénti feldolgozás nagy online létszámnál).
- [ ] **Admin konzol (`/ecore_admin`):** `Config.operator.admin.enabled = true` + `Config.operator.identifiers` és/vagy ACE (`add_ace … ecore.admin allow`). Alap: `standalone/config/main.lua` → `Config.operator.admin` (a betöltéskor szintetizált `Config.web` mezők csak belső használatra maradnak).
- [ ] **Integritás parancs (`/ecore_diag`):** `Config.operator.integrityCheck.enabled = true`. Ha az admin NUI be van kapcsolva (`Config.operator.admin.enabled`), a jog a **`hf.webConsoleAccess`** (admin policy) szerint van; különben `integrityCheck` ACE + azonosítók. Részletek: `standalone/config/main.lua` → `Config.operator.integrityCheck`.

---

## 2. Ismert kockázatok és mitigáció (rövid lista)

| Kockázat | Mitigáció a repóban / üzemeltetésben |
|----------|----------------------------------------|
| **Két core + `auto`** | indulás `error`; kényszerített `esx` / `qb` ConVar |
| **Végtelen várakozás** item registry-re | timeout + `CORE_READY`, `exports.e_core:isReady()`, indulási log |
| **`ox_lib` hiány** | `@ox_lib` init – kötelező indítani `e_core` előtt/vele együtt |
| **`dependencies` csak `oxmysql`** | ox_lib explicit `ensure` a cfg-ben; későbbi manifest bővítés opció |
| **Hamis net `loadMeta` / abuse** | forrás ellenőrzés + rate limit (`e_core:loadmeta_rate_ms`) |
| **Régi kliens `e_core:playerLoaded`** | csak szerver `TriggerEvent` + `AddEventHandler` – kliens hívás nem támogatott |
| **Jármű spawn** | csak `e_core:createVehicle` **callback** + forrás check |

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
