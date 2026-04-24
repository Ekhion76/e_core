# e_core megvalósítási munkanapló (WIP)

## Cél

Ez az **egyetlen központi hely** a futó megvalósítási lépések közbeni változásnaplóhoz.

Szabály:

- fejlesztés közben **nem** kell minden érintett doksit azonnal frissíteni,
- minden köztes változás ide kerül,
- a sprint végén történik a teljes dokumentációs szinkron + verziózás.

---

## Használati minta

Minden bejegyzés tartalmazza:

- dátum/idő,
- lépés azonosító (pl. `S1-T3`),
- rövid változásleírás,
- érintett fájlok,
- státusz (`done` / `partial` / `blocked`),
- nyitott teendő (ha van).

---

## WIP bejegyzések

### 2026-04-24 - alapok

- `S1-T0` - Tervezési doksik elkészítve és egységesítve.
- Érintett:
  - `docs/LABOR_OPTIMALIZALASI_TERV_HU.md`
  - `docs/PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md`
  - `docs/PROFESSION_REGISTRY_IMPLEMENTACIOS_TERV_SPRINT1_HU.md`
- Státusz: `done`
- Nyitott: implementáció közbeni bejegyzések folytatása.

### 2026-04-24 - quote API és collecting pilot

- `S1-TQ1` - `getLaborQuote` export + TTL cache alap bevezetve.
- `S1-TQ2` - `eco_collecting` átállítva quote alapú ellenőrzésre.
- Érintett:
  - `e_core/server/quote.lua`
  - `e_core/server/exports.lua`
  - `e_core/server/meta.lua`
  - `e_core/server/labor.lua`
  - `eco_collecting/server/main.lua`
  - `eco_collecting/client/main.lua`
- Státusz: `done`
- Nyitott: docs/public API végszinkron a sprintzárásban.

### 2026-04-24 - profession cap alap

- `S1-TC1` - profession-specifikus ability cap resolver bevezetve.
- `S1-TC2` - quote payload bővítve `abilityCap` és `isCapped` mezőkkel.
- Érintett:
  - `e_core/standalone/config/main.lua`
  - `e_core/libs/config_check.lua`
  - `e_core/server/meta.lua`
  - `e_core/server/quote.lua`
- Státusz: `done`
- Nyitott: admin GUI oldali cap megjelenítés későbbi fázisban.

### 2026-04-24 - Sprint 1 indulás (Task 1)

- `S1-T1` - DB migration bővítve profession registry táblákkal.
- Érintett:
  - `e_core/server/db_migrations.lua`
- Változás:
  - schema target: `2`
  - új migráció: `create_profession_registry_tables`
  - új táblák: `e_core_level_profiles`, `e_core_professions`
  - egyedi kulcsok + profile FK kapcsolat létrehozva
- Státusz: `done`
- Nyitott: `S1-T2` bootstrap seed implementáció.

### 2026-04-24 - Sprint 1 (Task 2)

- `S1-T2` - Profession registry bootstrap seed implementálva.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/server/db.lua`
  - `e_core/fxmanifest.lua`
- Változás:
  - új startup bootstrap folyamat: registry táblák állapotellenőrzés (`profilesCount`, `professionsCount`)
  - default level profile seed (`default_global`) a `Config.levels` JSON alapján
  - minimális profession seed készlet (crafting: `weaponry`, `chemist`, `cooking`, `foundry`, `handicraft`; harvesting: `gathering`)
  - idempotens működés: meglévő adatoknál nincs duplikáció (`INSERT IGNORE` / `ON DUPLICATE KEY`)
- Státusz: `done`
- Nyitott: `S1-T3` read-only profession API implementáció.

### 2026-04-24 - Sprint 1 (Task 3)

- `S1-T3` - Read-only profession API implementálva és exportálva.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/server/exports.lua`
  - `e_core/libs/errors.lua`
  - `e_core/export_examples_server.md`
  - `e_core/docs/PUBLIC_API_HU.md`
- Változás:
  - új read model cache + DB loader (`e_core_professions` + `e_core_level_profiles` join)
  - új exportok: `getProfessionRegistry`, `isValidProfession`, `getProfessionDefaults`, `getProfessionLevelProfile`
  - konzisztens hibaok kulcsok hozzáadva (`profession_registry_unavailable`, `profession_category_not_found`, `profession_not_found`, `profession_profile_not_found`)
  - server export példák és publikus API doksi bővítve
- Státusz: `done`
- Nyitott: `S1-T4` `eco_crafting` `initMeta` átállás registry alapú inicializálásra.

### 2026-04-24 - Sprint 1 (e_core only)

- `S1-T6A` - Profession registry diagnostics ellenőrzések beépítve (eco_crafting nélkül).
- Érintett:
  - `e_core/server/diagnostics.lua`
- Változás:
  - új szerver oldali registry check blokk (`runProfessionRegistryChecks`)
  - ellenőrzi: registry elérhetőség, rekordszám, profile referencia meglét, profile levels konzisztencia
  - NUI checklist bővítve külön `registry` lépéssel
  - console-only diagnosztikába is bekerült ugyanaz a registry audit szekció
- Státusz: `done`
- Nyitott: e_core oldali további diagnostics/doc bővítés (changelog + support reference) sprintzáráskor.

### 2026-04-24 - Sprint 1 (e_core docs sync)

- `S1-T6B` - Changelog + AI support reference szinkron az e_core profession registry és diagnostics bővítésekhez.
- Érintett:
  - `e_core/changelog.md`
  - `e_core/docs/AI_SUPPORT_REFERENCE_HU.txt`
- Változás:
  - új changelog bejegyzés: profession registry bootstrap + read-only API + diagnostics registry check
  - AI support referencia export lista bővítve (`getProfessionRegistry`, `isValidProfession`, `getProfessionDefaults`, `getProfessionLevelProfile`)
  - server szekció frissítve (`server/professions.lua`, `server/diagnostics.lua`) és rövid működési leírással kiegészítve
- Státusz: `done`
- Nyitott: sprint végi teljes doksi audit + verziózási döntés.

### 2026-04-24 - Sprint 1 (e_core záró audit)

- `S1-TZ1` - Sprint 1 e_core-only záró audit és verziózási döntés rögzítve.
- Érintett:
  - `e_core/docs/PROFESSION_REGISTRY_IMPLEMENTACIOS_TERV_SPRINT1_HU.md`
  - `e_core/fxmanifest.lua`
- Változás:
  - Sprint 1 tervben külön „e_core only scope” záróállapot blokk (done/deferred bontás)
  - halasztott consumer feladatok (`S1-T4`, `S1-T5`) explicit jelölése
  - verzió emelés `0.0.50`-re a changeloggal összhangban
- Státusz: `done`
- Nyitott: consumer oldali (`eco_crafting`) átállás külön körben.

### 2026-04-24 - Fázis 2 indulás (e_core backend-first)

- `F2-T1` - Standard admin response contract bevezetve profession admin API-hoz.
- `F2-T2` - Profession admin CRUD alap (`list/create/update/setEnabled/delete`) exportálva.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/server/exports.lua`
  - `e_core/libs/errors.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - egységes admin válaszobjektum: `ok`, `code`, `message`, `data`
  - profession registry cache invalidálás CRUD műveletek után
  - profile kulcs alapú referencia ellenőrzés create/update útvonalon
  - új hibakulcs: `profession_already_exists`
- Státusz: `done`
- Nyitott: `F2-T3` level profile CRUD + easy generator/validáció.

### 2026-04-24 - Fázis 2 (Task 3)

- `F2-T3` - Level profile admin CRUD + `levels_json` validáció + easy generator alap bevezetve.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/server/exports.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - új admin exportok: `levelProfileAdminList`, `levelProfileAdminCreate`, `levelProfileAdminUpdate`, `levelProfileAdminDelete`
  - `levels_json` normalize/validáció: növekvő `limit`, kötelező milestone lista, százalékos mezők 0..100 tartományban
  - alap easy generator (`milestones`, `maxPoints`, `curveType`, max discount mezők) profile create/update útvonalon
  - profile törlés védelem: default profile tiltás + használatban lévő profile törlésének blokkolása
- Státusz: `done`
- Nyitott: következő lépésként diagnostics és admin API réteg finomítása (`F2-T4+`).

### 2026-04-24 - Fázis 2 (Task 4, backend-first)

- `F2-T4` - Diagnostics admin futtatási alap + doc hint kapcsolat backend oldalon.
- Érintett:
  - `e_core/server/diagnostics.lua`
  - `e_core/server/exports.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - új admin diagnostics exportok: `diagnosticsAdminListTests`, `diagnosticsAdminRun`, `diagnosticsAdminGetRun`, `diagnosticsAdminCancelRun`
  - run-id alapú backend futásmodell (`queued`, `running`, `passed`, `failed`, `cancelled`) és egyszerű concurrency limit
  - első backend tesztkulcs: `registry_integrity` strukturált eredménnyel (`summary`, `issueCount`, `lines`)
  - fail ághoz dokumentációs ajánló (`docHints`) a diagnostics eredményben
  - standard admin response contract alkalmazása diagnostics admin API-ra is (`ok`, `code`, `message`, `data`)
- Státusz: `done`
- Nyitott: `F2-T5` cleanup/delete workflow backend endpoint-ek és audit finomítás.

### 2026-04-24 - Fázis 2 (Task 5, backend-first)

- `F2-T5` - Profession delete workflow backend cleanup/apply + audit/export finomítás.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/server/exports.lua`
  - `e_core/libs/errors.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - új cleanup workflow exportok: `professionAdminDeleteDryRun`, `professionAdminDeleteApply`
  - batch/cursor alapú profession meta cleanup job modell (`jobId`, `processed/changed/failed`, `lastCursor`)
  - job kontroll: `professionAdminCleanupJobGet`, `professionAdminCleanupJobAbort`, `professionAdminCleanupJobResume`
  - admin audit lista: `professionAdminAuditList` (cleanup + profession delete események)
  - apply védelem: kötelező megerősítő szöveg (`"<category>.<name> DELETE"`) és opcionális `deleteProfession`
  - új hibakulcsok: `cleanup_job_not_found`, `cleanup_job_not_resumable`, `cleanup_job_already_running`
- Státusz: `done`
- Nyitott: következő körben DB-perzisztens cleanup job tábla (`e_core_cleanup_jobs`) és hosszú futású aszinkron worker.

### 2026-04-24 - Fázis 2 (Task 6, backend-first)

- `F2-T6` - Cleanup job DB-perzisztencia + restart-safe worker alap.
- Érintett:
  - `e_core/server/db_migrations.lua`
  - `e_core/server/db.lua`
  - `e_core/server/professions.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
- Változás:
  - új migráció: `e_core_cleanup_jobs` tábla (`job_id`, állapot, cursor, stat mezők, hiba JSON, időbélyegek)
  - séma cél verzió emelés `3`-ra
  - cleanup job állapotok DB-be mentése minden érdemi állapotváltásnál/progressnél
  - queued alapú, aszinkron worker scheduler (konkurencia limit)
  - induláskor cleanup job bootstrap/recovery: restartkor félbeszakadt `queued/running` jobok fail-recovery jelölést kapnak
  - `Get/Abort/Resume` útvonalak DB fallback olvasással is működnek
- Státusz: `done`
- Nyitott: következő körben külön `list` API + dedikált cleanup jobs UI adatcontract.

### 2026-04-24 - Fázis 2 (Task 7, backend-first)

- `F2-T7` - Cleanup jobs list/filter/pagination API UI adatcontracttal.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/server/exports.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - új export: `professionAdminCleanupJobList(filters)`
  - támogatott filterek: `status`, `mode`, `category`, `name`
  - pagination contract: `limit`, `offset` bemenet + `items`, `total`, `limit`, `offset` kimenet
  - DB-first listázás, memóriacache frissítéssel
- Státusz: `done`
- Nyitott: UI oldali endpoint policy/jogosultsági réteg bekötése.

### 2026-04-24 - Fázis 2 (Task 8, backend-first)

- `F2-T8` - Cleanup admin API jogosultsági policy gate (ACE + allowlist).
- Érintett:
  - `e_core/standalone/config/main.lua`
  - `e_core/libs/errors.lua`
  - `e_core/server/professions.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - új config blokk: `Config.adminApi.cleanup` (`acePermission`, `allowedIdentifiers`, `allowServerWithoutSource`)
  - cleanup admin exportoknál jogosultság ellenőrzés (`auth.source` payload alapon)
  - új hibakulcs: `access_denied`
  - API és példák frissítve az `auth.source` használatra
- Státusz: `done`
- Nyitott: diagnostics admin API ugyanerre a policy rendszerre egységesítése.

### 2026-04-24 - Fázis 2 (Task 9, backend-first)

- `F2-T9` - Diagnostics admin API policy egységesítése (`Config.adminApi`).
- Érintett:
  - `e_core/standalone/config/main.lua`
  - `e_core/server/diagnostics.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - új config blokk: `Config.adminApi.diagnostics` (`acePermission`, `allowedIdentifiers`, `allowServerWithoutSource`)
  - diagnostics admin exportok (`ListTests/Run/GetRun/CancelRun`) jogosultságellenőrzése `auth.source` alapon
  - egységes `access_denied` válasz integráció diagnostics admin API-ra is
  - doksi + példák frissítve az új auth payload mintára
- Státusz: `done`
- Nyitott: közös (shared) admin policy helper kivonása a cleanup/diagnostics duplikáció csökkentésére.

### 2026-04-24 - Fázis 2 (Task 10, backend-first)

- `F2-T10` - Közös admin policy helper kivonás (`hf.adminApiCanAccess`).
- Érintett:
  - `e_core/libs/helper_ecore.lua`
  - `e_core/server/professions.lua`
  - `e_core/server/diagnostics.lua`
- Változás:
  - új shared helper: `hf.adminApiCanAccess(section, payload)` (`Config.adminApi[section]` alapján)
  - cleanup és diagnostics modul helyi, duplikált jogosultságkódjának kiváltása közös helperre
  - policy viselkedés változatlan, de egy helyen karbantartható
- Státusz: `done`
- Nyitott: opcionális következő körben részletesebb audit event a jogosultság-elutasításokra.

### 2026-04-24 - Fázis 2 (Task 11, backend-first)

- `F2-T11` - Jogosultság-elutasítás audit részletesítése (admin API).
- Érintett:
  - `e_core/libs/helper_ecore.lua`
  - `e_core/server/professions.lua`
  - `e_core/server/diagnostics.lua`
- Változás:
  - új helper: `hf.auditAdminApiDenied(section, action, payload, reason)` (in-memory ring + `cLog`)
  - cleanup admin API denied ágai audit eseményt is rögzítenek (`access_denied`) a cleanup audit streamben
  - diagnostics admin API denied ágai szintén központi denied audit helperen át mennek
- Státusz: `done`
- Nyitott: opcionális export a denied audit lista lekérésére admin UI felé.

### 2026-04-24 - Fázis 2 (Task 12, backend-first)

- `F2-T12` - Denied admin audit lista export admin UI-hoz.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/server/exports.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - új export: `adminApiDeniedAuditList(filters)` (section/action szűrés + `limit`/`offset`)
  - jogosultság: cleanup vagy diagnostics admin policy elfogadva
  - UI-barát válaszcontract: `items`, `total`, `limit`, `offset`
- Státusz: `done`
- Nyitott: igény esetén DB-perzisztencia a denied audit eseményekhez (jelenleg in-memory ring).

### 2026-04-24 - Fázis 2 (Task 13, backend-first)

- `F2-T13` - Denied audit DB-perzisztencia.
- Érintett:
  - `e_core/server/db_migrations.lua`
  - `e_core/libs/helper_ecore.lua`
  - `e_core/server/professions.lua`
- Változás:
  - új migráció: `e_core_admin_denied_audit` tábla (`section`, `action`, `source`, `requested_by`, `reason`, `ts`)
  - séma cél verzió emelés `4`-re
  - denied audit helper DB insert best-effort mentéssel bővítve
  - `adminApiDeniedAuditList` export DB-first listázásra váltva (memory fallback megtartva)
- Státusz: `done`
- Nyitott: retention/cleanup policy az audit táblára (pl. időalapú purge).

### 2026-04-24 - Fázis 2 (Task 14, backend-first)

- `F2-T14` - Denied audit retention/purge policy.
- Érintett:
  - `e_core/standalone/config/main.lua`
  - `e_core/server/professions.lua`
  - `e_core/server/db.lua`
- Változás:
  - új config: `Config.adminApi.deniedAudit` (`enabled`, `retentionDays`, `purgeIntervalMinutes`, `maxDeletePerRun`)
  - új purge függvény: `e_core_purge_admin_denied_audit_once()`
  - új scheduler: `e_core_schedule_admin_denied_audit_purge()` (időzített, batchelt törlés)
  - startup bootstrapből automatikus purge scheduler indítás
- Státusz: `done`
- Nyitott: opcionális admin export manuális purge triggerre.

### 2026-04-24 - Fázis 2 (Task 15, backend-first)

- `F2-T15` - Manuális denied audit purge trigger export.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/server/exports.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - új export: `adminApiDeniedAuditPurge(payload)`
  - admin policy védelem (`auth.source`) + denied audit rögzítés elutasítás esetén
  - új válasz adat: `data.deleted` (hány sor lett törölve)
- Státusz: `done`
- Nyitott: opcionális `dryRun` támogatás manuális purge exporthoz.

### 2026-04-24 - Fázis 2 (Task 16, backend-first)

- `F2-T16` - Manuális denied audit purge export `dryRun` támogatás.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
- Változás:
  - `adminApiDeniedAuditPurge(payload)` bővítve `dryRun=true` móddal
  - dry-run esetén törlés nélkül visszaadja a törölhető rekordok számát (`wouldDelete`)
  - normál futásnál explicit `dryRun=false` + `deleted` mező
- Státusz: `done`
- Nyitott: opcionális külön purge history/audit stream a manuális purge hívásokra.

### 2026-04-24 - Fázis 3 (e_core-only előkészítés)

- `F3-E2` - Recipe-validációs profession kulcs helper/export bevezetése (consumer nélkül).
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/server/exports.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
  - `e_core/docs/PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md`
  - `e_core/docs/PROFESSION_REGISTRY_IMPLEMENTACIOS_TERV_SPRINT1_HU.md`
- Változás:
  - új export: `validateProfessionKeys(category, keys)`
  - kimenet: `valid`, `invalid`, `missingProfile` listák (deduplikált kulcskezelés)
  - célzottan az `S1-T5` consumer startup recipe-validáció backend alapjának előkészítése
- Státusz: `done`
- Nyitott: következő körben consumer oldali (`S1-T5`) recipe startup validáció bekötése.

### 2026-04-24 - Fázis 3.5 (Admin Console MVP indítás)

- `F3.5-M1` - Svelte 5 alapú `admin-web` app scaffolding + tabos MVP váz elkészítve.
- Érintett:
  - `e_core/admin-web/package.json`
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - új különálló admin app létrehozva (`admin-web`) Vite + TypeScript alapon
  - Svelte dependency `^5.55.4` (runes-kompatibilis setup)
  - MVP tabstruktúra bekészítve a terv szerint: `Overview`, `Diagnostics`, `Documentation`, `Professions`, `Level Profiles`
  - runes-alapú state (`$state`, `$derived`) bevezetve az aktív tab kezeléséhez
- Státusz: `done`
- Nyitott: `Diagnostics` live run + fail doc ajánló és a profession/profile workflow-k adatbekötése.

### 2026-04-24 - Fázis 3.5 (Diagnostics mock contract)

- `F3.5-M2` - Diagnostics tab mock run modellel és fail doc ajánló blokkal bővítve.
- Érintett:
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - diagnostics futásmodell bevezetve (`runId`, `status`, `summary`, `docHints`)
  - run lista + részletező panel elkészítve (`queued/running/passed/failed/cancelled` státuszokkal)
  - fail futáshoz kapcsolt "Recommended Docs" blokk mock `docHints` adatokkal
  - responsive kártyás layout és státusz badge vizuális jelölések hozzáadva
- Státusz: `done`
- Nyitott: backend diagnostics API bekötése (valós `run_id` polling + cancel + élő log).

### 2026-04-24 - Fázis 3.5 (Diagnostics API layer + polling)

- `F3.5-M3` - Diagnostics adatréteg és UI polling/cancel vezérlés bevezetve.
- Érintett:
  - `e_core/admin-web/src/lib/diagnostics.ts`
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - új diagnostics service modul (`listDiagnosticsRuns`, `getDiagnosticsRun`, `cancelDiagnosticsRun`)
  - API contract-ready fallback: mock mód alapértelmezett, valós backend mód `VITE_USE_MOCK_DIAGNOSTICS=false` + `VITE_DIAGNOSTICS_API_BASE_URL` beállítással
  - Diagnostics tabon refresh gomb + hibaállapot megjelenítés
  - futó/sorban álló runhoz automatikus státusz polling (`2.5s`) és `Cancel Run` gomb
  - run részletek és ajánlott dokumentáció panel változatlan contract mentén megtartva
- Státusz: `done`
- Nyitott: valós e_core admin endpoint bridge/NUI integráció és élő run log stream.

### 2026-04-24 - Fázis 3.5 (Run selected + status cards)

- `F3.5-M4` - Diagnostics testkatalógus alapú indítás és státusz összesítő kártyák.
- Érintett:
  - `e_core/admin-web/src/lib/diagnostics.ts`
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - új diagnostics service műveletek: `listDiagnosticsTests`, `runDiagnosticsTests`
  - Diagnostics tabon tesztkatalógus (checkbox lista) + `Run selected` akció
  - futásstátusz összesítő kártyák (`queued`, `running`, `passed`, `failed`)
  - mock módban is működő run indítás, ami új `queued` run sort ad a listához
- Státusz: `done`
- Nyitott: backend endpoint véglegesítése a valós URL/payload szerződéshez (`/diagnostics/tests`, `/diagnostics/run`) + élő log panel.

### 2026-04-24 - Fázis 3.5 (Diagnostics live log + steps)

- `F3.5-M5` - Futáslépés/checklist és élő log panel hozzáadva a Diagnostics részletezőhöz.
- Érintett:
  - `e_core/admin-web/src/lib/diagnostics.ts`
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - `DiagnosticsRun` contract bővítve `steps` és `logs` mezőkkel
  - mock futásokhoz lépéslista (pending/running/passed/failed) és logbejegyzések hozzáadva
  - Run Details panel bővítve `Run Steps` és `Live Log` blokkokkal
  - vizuális státusz és log level jelölés (`info/warn/error`) elkészítve
- Státusz: `done`
- Nyitott: backend oldali valós log/step payload szerződés véglegesítése és stream/poll finomhangolás.

### 2026-04-24 - Fázis 3.5 (Backend payload-map illesztés)

- `F3.5-M6` - Diagnostics frontend normalizálás igazítva a jelenlegi e_core `diagnosticsAdmin*` run shape-hez.
- Érintett:
  - `e_core/admin-web/src/lib/diagnostics.ts`
- Változás:
  - `getRun` mapping bővítve: `data.run` és direkt `data` fallback támogatás
  - run indítás válaszmapping bővítve: `data.run.runId` fallback
  - run lista mapping bővítve: `items` mellett `runs` fallback
  - `summary/results` alapú futás-normalizálás:
    - `results` tömbből automatikus `steps` előállítás
    - `results[].lines` alapján log panelhez `logs` előállítás (`info/warn/error`)
    - `results[].docHints` alapján doc ajánlók összegyűjtése
  - tesztlista mapping finomítás (`estimatedCost` -> leírás fallback)
- Státusz: `done`
- Nyitott: végleges backend HTTP/NUI gateway szerződés rögzítése (`/diagnostics/*` útvonalak tényleges bevezetése).

### 2026-04-24 - Fázis 3.5 (Result details panel)

- `F3.5-M7` - Diagnostics `results` mező tesztenkénti részletező nézet hozzáadva.
- Érintett:
  - `e_core/admin-web/src/lib/diagnostics.ts`
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - új `DiagnosticsResultDetail` típus és `DiagnosticsRun.resultDetails` mező
  - backend `results` normalizálásból `resultDetails` előállítás (`key`, `code`, `issueCount`, `summary`, `passed`, `docHints`)
  - Run Details panel bővítve `Result Details` blokkal
  - mock run adatok is frissítve result detail mintával
- Státusz: `done`
- Nyitott: docHint severity/title backendből történő gazdagítása (jelenleg fallback alapú).

### 2026-04-24 - Fázis 3.5 (Result details docHints kibontás)

- `F3.5-M8` - Result soronkénti docHint lista megjelenítés hozzáadva.
- Érintett:
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - `Result Details` elemek alatt külön `Doc hints` blokk jelenik meg, ha van kapcsolt hint
  - hint sorokban a `docId/sectionKey` és confidence százalék is látható
  - result card layout módosítva, hogy a meta és hint lista jól olvasható maradjon
- Státusz: `done`
- Nyitott: hint kattintható deep-link (doksi tab/anchor) bekötése.

### 2026-04-24 - Fázis 3.5 (Külső docs stratégia + hint URL prep)

- `F3.5-M9` - GitHub Pages központi docs döntés rögzítve, hint-ek URL-re felkészítve.
- Érintett:
  - `e_core/docs/PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md`
  - `e_core/admin-web/src/lib/diagnostics.ts`
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - tervdoksiban rögzítve: `Documentation` tab elsődlegesen külső GitHub Pages link alapú
  - `DocHint` contract bővítve opcionális `docUrl` mezővel
  - frontend oldali URL resolver bevezetve (`VITE_DOCS_BASE_URL` + `docId/sectionKey` anchor)
  - diagnostics ajánlók kattintható külső linkként jelennek meg (`target="_blank"`)
- Státusz: `done`
- Nyitott: `Documentation` tab külön docs-index nézettel és központi docs kereséssel bővítése.

### 2026-04-24 - Fázis 3.5 (Documentation index tab)

- `F3.5-M10` - Documentation tab valós docs-index + kereső + külső open linkek.
- Érintett:
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - doc index aggregáció diagnostics run/test hint-ekből (deduplikált `docId+sectionKey`)
  - docs kereső mező (`title/docId/sectionKey`) és szűrt lista
  - minden docs sorban confidence + severity + `Open` külső link
  - responsive docs index UI stílusok hozzáadva
- Státusz: `done`
- Nyitott: Diagnostics -> Documentation belső átvezetés (fókusz egy konkrét hintre/tab váltáskor).

### 2026-04-24 - Fázis 3.5 (Hint releváns szekció garantálás)

- `F3.5-M11` - Hintek URL normalizálása, hogy backendből érkező hintnél is mindig szekció-link legyen.
- Érintett:
  - `e_core/admin-web/src/lib/diagnostics.ts`
  - `e_core/admin-web/src/App.svelte`
- Változás:
  - új központi `normalizeHint()` a `docUrl` kötelező előállítására (`docId + sectionKey` alapján)
  - `run`, `result`, `test` hint map-ek egységesítve erre a normalizálóra
  - docs index CTA felirat pontosítva: `Relevans szekcio`
- Státusz: `done`
- Nyitott: Documentation tabról visszanavigálás a forrás diagnostics run/hint elemre.

### 2026-04-24 - Fázis 3.5 (Documentation tab egyszerusites)

- `F3.5-M12` - Documentation tab scope pontositva: egyetlen kulso GitHub Pages link.
- Érintett:
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - docs index/kereso nezet eltavolitva a tabrol
  - Documentation tabon egy dedikalt `GitHub Pages megnyitasa` gomb maradt
  - szoveges megerosites: a diagnostics hint-ek tovabbra is relevans kulso szekcio linkek
- Státusz: `done`
- Nyitott: vegleges `VITE_DOCS_BASE_URL` ertek beallitasa a tenyleges Pages URL-re.

### 2026-04-24 - Fázis 3.5 (UI finomitas - hint CTA/fallback)

- `F3.5-M15` - Hint link CTA szoveg egységesítés + URL nélküli fallback üzenet.
- Érintett:
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - minden hint link CTA egységes: `Relevans szekcio megnyitasa`
  - URL nélküli hintnél explicit fallback szöveg: `Szekcio link hamarosan elerheto`
  - fallback megjelenéshez külön stílus (`hint-missing-link`)
- Státusz: `done`
- Nyitott: valós docs URL-ek és szekció anchorok bevezetése a Pages publikálás után.

### 2026-04-24 - Fázis 3 (diagnostics consumer-ready)

- `F3-E3` - Diagnostics bővítés `profession-key-validation` teszttípussal.
- Érintett:
  - `e_core/server/diagnostics.lua`
  - `e_core/docs/PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md`
- Változás:
  - új admin diagnostics tesztkulcs: `profession-key-validation`
  - tesztfutás közben a `validateProfessionKeys` service-t használja kategóriánként
  - futás mód:
    - payloadból `professionKeysByCategory` esetén célzott kulcsvalidáció
    - payload nélkül registry-alapú teljes kategóriaellenőrzés
  - docHint mapping finomítva F3-E fókuszra (cleanup terv + sprint terv + API)
- Státusz: `done`
- Nyitott: következő körben consumer oldali (`S1-T5`) recipe startup validáció bekötése.

### 2026-04-24 - Fázis 3 (audit shape egységesítés)

- `F3-E4` - Cleanup/diagnostics/denied audit események közös shape-re hozása.
- Érintett:
  - `e_core/server/professions.lua`
  - `e_core/libs/helper_ecore.lua`
  - `e_core/docs/PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md`
- Változás:
  - cleanup audit események top-level mezői egységesítve: `eventType`, `actor`, `target`, `outcome` (+ `details`)
  - denied audit helper (`hf.auditAdminApiDenied`) új egységes event struktúrát is tárol
  - `adminApiDeniedAuditList` DB és memory fallback sorokból közös audit shape-et ad vissza
  - legacy mezők (`section`, `action`, `source`, `requestedBy`, `reason`) kompatibilitási okból továbbra is visszaadva
- Státusz: `done`
- Nyitott: következő körben consumer oldali (`S1-T5`) recipe startup validáció bekötése.

### 2026-04-24 - Fázis 3 (doksi zárás)

- `F3-E5` - Fázis 3 e_core-only doksi szinkron lezárása.
- Érintett:
  - `e_core/docs/PUBLIC_API_HU.md`
  - `e_core/export_examples_server.md`
  - `e_core/docs/PROFESSION_REGISTRY_IMPLEMENTACIOS_TERV_SPRINT1_HU.md`
- Változás:
  - `PUBLIC_API_HU` frissítve az F3-E3/F3-E4 szerződésre (`diagnosticsAdminRun.professionKeysByCategory`, audit event shape)
  - `export_examples_server` frissítve:
    - diagnostics futtatás példa `profession-key-validation` + `professionKeysByCategory`
    - denied audit lista példa az egységes audit mezőkkel (`eventType`, `actor`, `target`, `outcome`)
  - sprint terv Fázis 3 e_core-only blokkja teljes F3-E2..F3-E5 bontással kiegészítve
- Státusz: `done`
- Nyitott: következő körben consumer oldali (`S1-T5`) recipe startup validáció bekötése.

### 2026-04-24 - Fázis 3.5 (UI stabilizálás - App.svelte darabolás)

- `F3.5-M16` - `App.svelte` szétbontása külön panel komponensekre.
- Érintett:
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/lib/DiagnosticsPanel.svelte`
  - `e_core/admin-web/src/lib/DocumentationPanel.svelte`
- Változás:
  - a Diagnostics tab teljes nézete átkerült `DiagnosticsPanel` komponensbe
  - a Documentation tab külön `DocumentationPanel` komponenst kapott
  - az `App.svelte` container szerepre egyszerűsödött (state, tab routing, adatfrissítés/polling)
- Státusz: `done`
- Nyitott: következő tabok (`Professions`, `Level Profiles`) hasonló komponens-szintű bontásának előkészítése.

### 2026-04-24 - Fázis 3.5 (UI stabilizálás - további tab darabolás)

- `F3.5-M17` - `Professions` és `Level Profiles` tab külön panel komponensekre bontása.
- Érintett:
  - `e_core/admin-web/src/App.svelte`
  - `e_core/admin-web/src/lib/ProfessionsPanel.svelte`
  - `e_core/admin-web/src/lib/LevelProfilesPanel.svelte`
- Változás:
  - új `ProfessionsPanel` komponens a professions tab tartalmára
  - új `LevelProfilesPanel` komponens a level profiles tab tartalmára
  - `App.svelte` tab branch-ek egyszerűsítve komponens-hívásra
- Státusz: `done`
- Nyitott: a két panelben a tényleges CRUD/workflow UI fokozatos feltöltése.

### 2026-04-24 - Fázis 3.5 (Panel feltoltes - mock catalog MVP)

- `F3.5-M18` - `ProfessionsPanel` es `LevelProfilesPanel` tartalmi MVP vaz mock katalogussal.
- Érintett:
  - `e_core/admin-web/src/lib/ProfessionsPanel.svelte`
  - `e_core/admin-web/src/lib/LevelProfilesPanel.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - professions panel: mock registry lista, status cardok, profile/cap/meta oszlopok
  - level profiles panel: mock profile katalogus, mode szerinti status, linked profession mutatok
  - kozos listastilusok (`admin-grid`, `simple-list`, `simple-list-meta`) a ket panelhez
- Státusz: `done`
- Nyitott: API read model bekotes (`getProfessionRegistry`, profile endpoint), kereses/szures, es CRUD actionok aktiv hookjai.

### 2026-04-24 - Fázis 3.5 (Registry read bekotes + szures)

- `F3.5-M19` - Professions/Level Profiles panelek valos read adapterre kotese, mock fallbackkel.
- Érintett:
  - `e_core/admin-web/src/lib/registry.ts`
  - `e_core/admin-web/src/lib/ProfessionsPanel.svelte`
  - `e_core/admin-web/src/lib/LevelProfilesPanel.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - uj kozos API adapter: `listProfessions`, `listLevelProfiles` (`VITE_ADMIN_API_BASE_URL`)
  - `VITE_USE_MOCK_REGISTRY` flag-gel mock/live mod valtasa
  - panelenkent refresh + loading + error allapot + kliens oldali kereses/szures
  - toolbar/search UI stilusok egységesitese
- Státusz: `done`
- Nyitott: konkret backend HTTP route contract veglegesitese (`/professions`, `/level-profiles`) es CRUD endpoint hookok aktiv bekotese.

### 2026-04-24 - Fázis 3.5 (Route contract hardening)

- `F3.5-M20` - Admin registry adapter route-varians es response-shape hardening.
- Érintett:
  - `e_core/admin-web/src/lib/registry.ts`
- Változás:
  - endpoint fallback sorrend bevezetve professions/profile listara
  - route variansok: `/professions`, `/admin/professions`, `/profession-admin/list`, illetve profile oldalon ennek megfelelo parok
  - payload normalizalo (`unwrapItems`) kezeli: `data.items`, `data.professions`, `data.profiles`, valamint top-level tomb/lista shape-eket
  - hibauzenet pontositva: route varians probalkozasi hiba osszegzessel
- Státusz: `done`
- Nyitott: backend oldalon egyetlen kanonikus HTTP path keszlet kijelolese es a tobbi varians fokozatos kivezetese.

### 2026-04-24 - Fázis 3.5 (Kanonikus route fixálás)

- `F3.5-M21` - Admin registry read route-ok fixálása kanonikus path párra.
- Érintett:
  - `e_core/admin-web/src/lib/registry.ts`
- Változás:
  - route fallback logika eltávolítva a registry adapterből
  - kanonikus profession route: `/admin/professions`
  - kanonikus level profile route: `/admin/level-profiles`
  - response shape normalizálás (`unwrapItems`) megtartva
- Státusz: `done`
- Nyitott: backend oldali route implementáció/bridge végleges szinkron ellenőrzése live környezetben.

### 2026-04-24 - Fázis 3.5 (Kanonikus route doksi szinkron)

- `F3.5-M22` - Kanonikus admin-web read route contract rögzítése a publikus API dokumentációban.
- Érintett:
  - `e_core/docs/PUBLIC_API_HU.md`
- Változás:
  - új szekció: `Admin-web HTTP read contract (kanonikus route-ok)`
  - rögzített route páros:
    - `GET /admin/professions`
    - `GET /admin/level-profiles`
  - rögzített response shape: `ok`, `code`, `message`, `data.items`
- Státusz: `done`
- Nyitott: backend bridge implementáció és deploy környezet route-exponálás validálása.

### 2026-04-24 - Fázis 3.5 (Backend HTTP bridge - minimál)

- `F3.5-M23` - Kanonikus admin read route-ok minimál backend HTTP bridge implementáció.
- Érintett:
  - `e_core/server/admin_http.lua`
  - `e_core/fxmanifest.lua`
- Változás:
  - új HTTP handler (`SetHttpHandler`) a két kanonikus read route-ra
    - `GET /admin/professions` -> `professionAdminList()`
    - `GET /admin/level-profiles` -> `levelProfileAdminList()`
  - alap válaszkezelés: JSON `Content-Type`, CORS header, `OPTIONS` preflight
  - ismeretlen útvonal: `404 route_not_found`, nem támogatott metódus: `405 method_not_allowed`
  - handler felvéve a szerver script betöltési sorba (`fxmanifest.lua`)
- Státusz: `done`
- Nyitott: auth/jogosultság réteg (admin token/ACL) és részletes audit bekötése HTTP hívásokra.

### 2026-04-24 - Fázis 3.5 (HTTP auth policy - config identifier/token)

- `F3.5-M24` - Admin HTTP read route-ok jogosultságkezelése config alapú identifier/token policy-val.
- Érintett:
  - `e_core/server/admin_http.lua`
  - `e_core/standalone/config/main.lua`
  - `e_core/libs/config_check.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
- Változás:
  - új config blokk: `Config.adminHttp.read`
    - `allowedIdentifiers` (pl. `fivem:...`, `license:...`, `discord:...`)
    - `identifierHeader` (alap: `x-ecore-identifier`)
    - `token` + `tokenHeader` (alap: `x-ecore-token`)
  - HTTP GET route-ok (`/admin/professions`, `/admin/level-profiles`) auth ellenőrzést kaptak
  - jogosulatlan kérés: `401` + `access_denied`, denied audit rögzítéssel (`hf.auditAdminApiDenied`, `section=http_read`)
  - config sanitization bővítve (`config_check.lua`) az új `Config.adminHttp` mezőkre
- Státusz: `done`
- Nyitott: opcionális ACE/source alapú HTTP auth réteg és részletes rate-limit policy.

### 2026-04-24 - Fázis 3.5 (Frontend auth header bekötés)

- `F3.5-M25` - Admin-web registry adapter auth header támogatás a backend HTTP policy-hoz.
- Érintett:
  - `e_core/admin-web/src/lib/registry.ts`
  - `e_core/docs/PUBLIC_API_HU.md`
- Változás:
  - frontend fetch hívások auth headerekkel mennek (`identifier`/`token`)
  - env vezérelt header név és érték:
    - `VITE_ADMIN_IDENTIFIER`, `VITE_ADMIN_IDENTIFIER_HEADER`
    - `VITE_ADMIN_TOKEN`, `VITE_ADMIN_TOKEN_HEADER`
  - doksi frissítve az admin-web env illesztési mintával
- Státusz: `done`
- Nyitott: sample `.env` sablon felvétele az `admin-web` gyökérbe fejlesztői onboardinghoz.

### 2026-04-24 - Fázis 3.5 (Admin-web env onboarding)

- `F3.5-M26` - Admin-web `.env` minta és rövid setup dokumentáció.
- Érintett:
  - `e_core/admin-web/.env.example`
  - `e_core/admin-web/README.md`
- Változás:
  - új `.env.example` a kanonikus admin read API + auth header változókkal
  - mock flag-ek (`VITE_USE_MOCK_DIAGNOSTICS`, `VITE_USE_MOCK_REGISTRY`) mintázva
  - `README` kiegészítve rövid e_core admin env setup lépésekkel
- Státusz: `done`
- Nyitott: opcionális külön `README-HU` vagy dedikált `docs/ADMIN_WEB_SETUP_HU.md` onboarding doksi.

### 2026-04-24 - Fázis 3.5 (HTTP bridge funkcionalitas bovites - profession read)

- `F3.5-M27` - Kiegeszito profession read endpointok a kanonikus admin HTTP bridge-re.
- Érintett:
  - `e_core/server/admin_http.lua`
  - `e_core/docs/PUBLIC_API_HU.md`
- Változás:
  - uj GET route-ok:
    - `/admin/professions/defaults?category=...` (`getProfessionDefaults`)
    - `/admin/professions/validate?category=...&keys=a,b,c` (`validateProfessionKeys`)
    - `/admin/professions/profile?category=...&name=...` (`getProfessionLevelProfile`)
  - query parser + URL decode bevezetve a HTTP bridge-be
  - route-ok a meglévő admin HTTP auth policy-t használják (`Config.adminHttp.read`)
- Státusz: `done`
- Nyitott: frontend oldali felhasznalas (pl. create/update elotti valos key validacio) bekotese.

### 2026-04-24 - Fázis 3.5 (ProfessionsPanel valos read akciok)

- `F3.5-M28` - ProfessionsPanel bovitese defaults/validate valos API akciokkal.
- Érintett:
  - `e_core/admin-web/src/lib/registry.ts`
  - `e_core/admin-web/src/lib/ProfessionsPanel.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - uj registry kliens fuggvenyek:
    - `getProfessionDefaults(category)`
    - `validateProfessionKeys(category, keys[])`
  - `ProfessionsPanel` UI:
    - category selector
    - keys input
    - `Load defaults` + `Validate keys` gombok
    - action result blokk (valid/invalid/missingProfile + defaults kulcslista)
  - uj stilusok az action panelhez (`action-grid`, `action-results`, `field-label`)
- Státusz: `done`
- Nyitott: ugyanez a workflow bekotese a kovetkezo create/update form validacios lepeseibe.

### 2026-04-24 - Fázis 3.5 (ProfessionsPanel profile endpoint bekotes)

- `F3.5-M29` - Profession soronkénti profile lekérés a kanonikus `/admin/professions/profile` route-ról.
- Érintett:
  - `e_core/admin-web/src/lib/registry.ts`
  - `e_core/admin-web/src/lib/ProfessionsPanel.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - új kliens függvény: `getProfessionProfile(category, name)`
  - profession lista sorokban `View profile` akciógomb
  - profile result blokk: `profileKey`, `displayName`, `mode`, `levels` darabszám
  - kisebb CTA gomb stílus (`small-btn`)
- Státusz: `done`
- Nyitott: profile részletek (levels) bővebb táblás nézete külön expandable panelben.

### 2026-04-24 - Fázis 3.5 (ProfessionsPanel profile level preview)

- `F3.5-M30` - Profile eredmény kibővítése level tartalom előnézettel.
- Érintett:
  - `e_core/admin-web/src/lib/ProfessionsPanel.svelte`
  - `e_core/admin-web/src/app.css`
- Változás:
  - profile result blokkban a `levels` struktúra feldolgozása (object/array támogatás)
  - rendezett, rövidített level preview lista (első 8 bejegyzés) JSON soronként
  - vizuális jelzés, ha további level elemek is vannak
  - dedikált stílusok (`levels-preview`, `level-key`)
- Státusz: `done`
- Nyitott: teljes level táblázat / expand mód és mezőszintű formázás.

### 2026-04-24 - Fázis 3.5 (LevelProfilesPanel level preview)

- `F3.5-M31` - Level profile lista kibővítése kiválasztható level előnézettel.
- Érintett:
  - `e_core/admin-web/src/lib/registry.ts`
  - `e_core/admin-web/src/lib/LevelProfilesPanel.svelte`
- Változás:
  - `LevelProfileItem` bővítve nyers `levelsData` mezővel (list endpoint payloadból)
  - listanézet soronként `View levels` gombot kapott
  - kiválasztott profile blokkon level preview (első 8 sor) + további elemszám jelzés
  - object/array level struktúra támogatás rendezett megjelenítéssel
- Státusz: `done`
- Nyitott: level sorok mezőszintű táblás formázása és edit előkészítés.
