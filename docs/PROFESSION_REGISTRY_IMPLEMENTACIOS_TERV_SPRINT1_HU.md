# Profession Registry - Implementacios terv (Sprint 1)

## Cél és hatókör

Ez a terv a `PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md` gyakorlati, sprint-szintű kivonata.

Dokumentációs munkarend ehhez a tervhez:

- futás közben a változások egy helyre kerülnek: `docs/IMPLEMENTATION_MUNKANAPLO_WIP_HU.md`,
- a sprint során nem kötelező minden kapcsolódó doksit minden lépésnél frissíteni,
- teljes doksi-szinkron és verziózás a sprint végi záráskor történik.

Sprint 1 cél:

- DB-first profession registry alap lefektetése,
- read-only e_core API-k bevezetése,
- `eco_crafting` inicializálás átállítása registry alapon,
- startup validáció recipe profession mezőkre,
- minimális, de használható diagnostics/dry-run alap.

## Kotelezo epitesi elvek

1. **Sorban, lepescsomagokban epites**
   - Minden fazis onalloan szallithato legyen.
   - Ne legyen "big bang" release.
   - Minden lepest lehessen kulon validalni es visszagorgetni.

2. **Admin UI: Svelte 5**
   - Svelte 5 hasznalata javasolt a modern feature-kel:
     - runes (`$state`, `$derived`, `$effect`)
     - komponensenkenti reaktiv adatfolyam
   - Kerulni kell a legacy mintakat, ha van stabil Svelte 5 alternativa.

3. **Jovoallo API/struktura (ketfazisu kompatibilitas politika)**
   - **Aktualis atalakitasi fazisban** teljes szabadsag van: a belso es kulso szerzodesek is torhetok, ha ez egyszerusiti/erositi az uj architekturara allast.
   - **Stabilizalas utan** viszont kompatibilitas-tudatos modra valtunk:
     - stabil, verziozhato export szerzodes,
     - uj mezok bovithetoek, de mar stabil API-t csak indokoltan torunk,
     - minden toro valtozashoz dokumentalt migracios utvonal.
   - Most kell ugy tervezni, hogy kesobb tobb `eco_*` script tamaszkodhasson ra gond nelkul.
   - Hibaokok (`eCoreErr`) maradjanak konzisztensen hasznalva.

4. **Bevalt struktura kovetese, celzott absztrakciokkal**
   - Az atalakitasi fazisban lehet uj helper/absztrakcio, ha ez gyorsitja a rendezett ujraepitest.
   - Kerulni kell a "helper helpere" jellegu tulretegezest.
   - A mar bevalt projektstrukturat kell kovetni:
     - tiszta service modulok,
     - vekony export reteg,
     - dokumentalt API.
   - Stabilizalas utan uj absztrakcio csak akkor keruljon be, ha merhetoen egyszerusit.

Kifejezetten **nem** Sprint 1:

- teljes admin GUI,
- full cleanup apply job engine,
- teljes consumer ökoszisztéma migráció.

---

## Deliverable lista (Sprint 1)

1. DB migration: `e_core_level_profiles`, `e_core_professions`.
2. Bootstrap seed: jelenlegi configból alap profile + profession rekordok.
3. e_core server read model + exportok:
   - `getProfessionRegistry()`
   - `isValidProfession(category, name)`
   - `getProfessionDefaults(category)`
   - `getProfessionLevelProfile(category, name)`
4. `eco_crafting` `initMeta` átállás recipe-derived helyett registry-derived inicializálásra.
5. Recipe startup validáció (ismeretlen profession -> warning + tiltás).
6. Dokumentáció frissítés (PUBLIC API + support reference + changelog megjegyzés).
7. Epitesi elvek kodifikalasa a kapcsolodo dokumentaciokban (Svelte 5 + kompatibilitas + struktura).

---

## Konkrét feladatbontás

## Task 1 - DB migration (schema)

### Fájlok

- `e_core/server/db_migrations.lua`
- opcionálisan új migration SQL segédfájl, ha a projektstruktúra ezt követi

### Teendő

- új tábla: `e_core_level_profiles`
- új tábla: `e_core_professions`
- indexek/unique kulcsok:
  - `e_core_professions(category, name)` unique
  - `e_core_level_profiles(profile_key)` unique

### Elfogadási kritérium

- migráció hiba nélkül lefut üres és meglévő DB-n is,
- migráció idempotens logikával kezelhető (ne hozzon létre duplikátumot).

---

## Task 2 - Bootstrap seed

### Fájlok

- `e_core/server/db.lua`
- `e_core/server/main.lua` vagy dedikált profession service fájl (ajánlott: `e_core/server/professions.lua`)

### Teendő

- ha nincs profile/profession adat:
  - hozzon létre default level profile-t a jelenlegi `Config.levels` alapján (`levels_json`),
  - hozzon létre alap profession rekordokat a jelenlegi consumer ismert készletek szerint (kezdetben crafting/harvesting minimum).

### Elfogadási kritérium

- első induláskor automatikusan előáll a minimális registry,
- második induláskor nincs újradublikálás.

---

## Task 3 - Read-only profession API

### Fájlok

- `e_core/server/exports.lua`
- `e_core/server/professions.lua` (új)
- `e_core/export_examples_server.md`
- `e_core/docs/PUBLIC_API_HU.md`

### Teendő

- implementáld és exportáld:
  - `getProfessionRegistry()`
  - `isValidProfession(category, name)`
  - `getProfessionDefaults(category)`
  - `getProfessionLevelProfile(category, name)`
- cache-elhető read model memóriában (startup load + időszakos refresh opció)

### Elfogadási kritérium

- exportok konzisztens visszatérési szerződéssel működnek,
- hibaágak dokumentáltak,
- export példák frissítve vannak.

---

## Task 4 - eco_crafting initMeta átállás

### Fájlok

- `eco_crafting/libs/functions.lua`
- szükség esetén `eco_crafting/server/main.lua`

### Teendő

- jelenlegi recipe-derived `allProficiency` építés kiváltása:
  - `defaults = exports.e_core:getProfessionDefaults('crafting')`
  - `registerMeta(playerId, 'crafting', defaults)`

### Elfogadási kritérium

- új játékos meta init recipe-től függetlenül a registry alapján történik,
- typo recipe profession nem hoz létre új kulcsot.

---

## Task 5 - Recipe validáció startupkor

### Fájlok

- `eco_crafting/server/main.lua`
- opcionális `eco_crafting/libs/configchecker.lua`

### Teendő

- induláskor végigellenőrizni `Config.recipes[*].profession` mezőket:
  - ha nincs registryben:
    - warning log,
    - recipe disable (ne jelenjen meg gyárthatóként)

### Elfogadási kritérium

- invalid profession recipe nem fut le éles gyártásban,
- logból egyértelműen látszik a hiba oka és recipe azonosító.

---

## Task 6 - Minimál diagnostics és dokumentáció

### Fájlok

- `e_core/server/diagnostics.lua`
- `e_core/docs/AI_SUPPORT_REFERENCE_HU.txt`
- `e_core/changelog.md`

### Teendő

- diagnostics check hozzáadása:
  - registry consistency check (duplikáció, hiányzó profile referenciák)
  - recipe profession validity check (crafting scope)
- dokumentációban új szekció a Sprint 1 API és migrációs irányról

### Elfogadási kritérium

- legalább egy diagnosztikai parancs/report mutatja a registry integritást,
- changelog és referencia frissítve.

---

## API contract v1 (Sprint 1)

`getProfessionRegistry()`:

- `true, { [category] = { [name] = { enabled, displayName, levelProfileKey, maxProficiency } } }`
- hiba: `false, eCoreErr.*`

`isValidProfession(category, name)`:

- `true, true|false`
- hiba: `false, eCoreErr.*`

`getProfessionDefaults(category)`:

- `true, { [professionName] = 0, ... }`
- hiba: `false, eCoreErr.*`

`getProfessionLevelProfile(category, name)`:

- `true, { profileKey, displayName, mode, levels }`
- hiba: `false, eCoreErr.*`

---

## Tesztterv (Sprint 1)

## Funkcionális

- új DB-n indulás -> táblák + seed létrejönnek,
- meglévő DB-n indulás -> nem duplikál,
- `eco_crafting` új belépőnél registry-alapú meta kulcsokat kap,
- invalid profession recipe tiltott státuszba kerül.

## Regresszió

- meglévő crafting folyamat valid professionnel tovább működik,
- labor/ability régi exportok változatlanul működnek.

## Negatív

- hiányzó profile referencia esetén diagnosztika fail,
- üres registry esetén egyértelmű hiba és fallback log.

---

## Rollout és rollback

## Rollout

1. migration deploy
2. e_core deploy
3. eco_crafting deploy
4. diagnostics check futtatás
5. operátori validáció

## Rollback

- kód rollback lehetséges, de migráció miatt:
  - új táblák maradhatnak (nem zavaró),
  - read path fallbackolhat configra ideiglenesen (ha szükséges).

---

## Sprint 1 Definition of Done

- fenti 6 task kész és merge-ready,
- köztes változások rögzítve a WIP munkanaplóban,
- sprintzáráskor dokumentáció és export példa naprakészre szinkronizálva,
- diagnosztika legalább alapszinten lefedi a registry konzisztenciát,
- eco_crafting már nem recipe alapján hoz létre profession metát.

---

## Sprint 1 záróállapot (e_core only scope - 2026-04-24)

Az aktuális körben a scope tudatosan **e_core only** volt (consumer módosítás nélkül).

Kész (`done`):
- Task 1 - DB migration
- Task 2 - Bootstrap seed
- Task 3 - Read-only profession API
- Task 6 - e_core része (registry diagnostics + docs/changelog szinkron)

Tudatosan halasztva (`deferred`):
- Task 4 - `eco_crafting` initMeta átállás (consumer oldali döntés alapján)
- Task 5 - `eco_crafting` recipe startup validáció (consumer oldali döntés alapján)

Verziózási döntés:
- `fxmanifest.lua` verzió: **`0.0.50`**
- indok: Sprint 1 e_core oldali profession registry alapok + új publikus exportok + diagnostics bővítés.

Megjegyzés:
- a teljes Sprint 1 DoD csak akkor lesz teljesített, ha a halasztott `eco_crafting` feladatok külön körben elkészülnek.

---

## Fázis 2 backend-first kivonat (aktuális következő lépés)

`F2-T4` fókusz: diagnostics + doc hint/admin finomítás backend oldalon, UI előtt.

- admin diagnostics exportok run-id alapú állapotmodellel (`queued/running/passed/failed/cancelled`),
- tesztkatalógus + tesztenkénti futtatás (on-demand),
- fail eredményhez kapcsolt dokumentációs ajánló (`docHints`),
- egységes admin response contract a diagnostics API-n is (`ok`, `code`, `message`, `data`).

`F2-T6` fókusz: cleanup job perzisztens infrastruktúra backend oldalon.

- `e_core_cleanup_jobs` DB tábla + migráció,
- restart-safe cleanup worker alap (queued/running recovery),
- resume/abort/get folyamatok DB fallback olvasással.

---

## Fázis 3 e_core-only előkészítés (belépő blokk)

Első lépésben consumer nélküli backend hidat készítünk, hogy az `S1-T5` recipe validáció később azonnal ráköthető legyen.

- `F3-E2` - Recipe-validációs e_core service: új export `validateProfessionKeys(category, keys[])`.
- Válaszcontract:
  - `valid`: engedélyezett és létező profession kulcsok (deduplikált lista),
  - `invalid`: hiányzó/tiltott/hibás kulcsok,
  - `missingProfile`: létező, de profile nélküli profession kulcsok.
- `F3-E3` - Diagnostics tesztkatalógus bővítés `profession-key-validation` típussal + docHint finomítás.
- `F3-E4` - Cleanup/diagnostics/denied audit egységes event shape (`eventType`, `actor`, `target`, `outcome`).
- `F3-E5` - Doksi zárás: `PUBLIC_API_HU` + `export_examples_server` F3 contract szinkron.
- Scope: e_core only, consumer változás nélkül.
