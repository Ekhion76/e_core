# Profession registry és meta cleanup terv

## Mi a probléma most?

Jelenleg legalabb a crafting iranyban a szakmak implicit modon jonnek letre:

- a recipe-kbol kiolvasott `recipe.profession` kulcsok alapjan,
- indulaskor `registerMeta(playerId, 'crafting', allProficiency)` hivassal.

Ez gyors, de tobb kockazata van:

- elirasbol uj, hibas szakmanev jon letre,
- nincs kozponti kontroll, hogy milyen szakmak "ervenyesek",
- nincs egyertelmu eletciklus (bevezetes / kivezetes),
- a JSON blobban bent maradnak regi, mar nem hasznalt kulcsok.

## Celallapot

Az e_core legyen a szakmak "source of truth"-a:

- explicit, centralis profession registry,
- consumer script csak felhasznal, nem definial,
- recipe validacio indulaskor (ismeretlen profession -> hiba/log/tiltas),
- biztonsagos meta cleanup folyamat (dry-run + apply).

---

## 1) Profession registry modell (DB-first, kontrollalt)

Alapelv: ha mar van GUI szakma letrehozas/karbantartas, akkor ne fajlgeneralas legyen, hanem adatbazis.

- A config file maradjon csak fallback/bootstrap celra.
- A valodi "source of truth" legyen DB tabla.
- Ezzel kezelheto a GUI-ban letrehozas, szerkesztes, tiltás, level profil valasztas.

## Javasolt adatmodell

### `e_core_professions`

- `id` (PK)
- `category` (pl. `crafting`, `harvesting`)
- `name` (pl. `weaponry`, `gathering`)
- `display_name`
- `enabled` (bool)
- `level_profile_id` (FK -> `e_core_level_profiles.id`)
- `max_proficiency` (nullable, profession cap)
- `created_at`, `updated_at`

Unique index: `(category, name)`

### `e_core_level_profiles`

- `id` (PK)
- `profile_key` (unique, pl. `default_crafting`, `default_harvesting`)
- `display_name`
- `mode` (`easy` | `advanced`)
- `levels_json` (a teljes level gorbe JSON-kent)
- `created_by`, `created_at`, `updated_at`

Megjegyzes:

- egy profession egy profilra mutat (`level_profile_id`),
- ugyanaz a profil tobb professionhoz is rendelheto,
- az egyedi profil is tarolhato (klon + szerkeszt).

## Javasolt e_core API

- `exports.e_core:getProfessionRegistry()` -> teljes, readonly masolat (DB-bol toltve)
- `exports.e_core:isValidProfession(category, name)` -> boolean
- `exports.e_core:getProfessionDefaults(category)` -> `{ [name] = 0, ... }` inicializalashoz
- `exports.e_core:getProfessionLevelProfile(category, name)` -> aktiv level profile (levels_json)

Ezzel a consumer nem recipe-bol epit "igazsagot", csak lekerdezi.

---

## 2) Consumer oldali atallas (eco_crafting minta)

Most:

- `initMeta()` recipe-kbol gyujt profession kulcsokat.

Cel:

- `initMeta()` az e_core registry alapjan inicializal.

Elvart viselkedes:

1. `defaults = exports.e_core:getProfessionDefaults('crafting')`
2. `exports.e_core:registerMeta(playerId, 'crafting', defaults)`
3. recipe validacio startupkor:
   - ha recipe.profession nincs registryben -> hard warning + recipe tiltasa

Igy megszunik az elirasbol szuletett "fantom szakma".

---

## 3) Level profile modell + easy mode kombinacio

Best practice:

- ne csak egy globalis `Config.levels` legyen,
- hanem profile alapu rendszer (`e_core_level_profiles`),
- professionenkent profile hozzarendeles,
- professionenkent opcionális cap (`max_proficiency`).

## Easy mode + manual finomhangolas

A GUI-ban uj profile letrehozasnal:

1. Easy mode wizard:
   - milestone szam,
   - max pont,
   - max kedvezmenyek (`labor`, `time`, `price`, `chance`, `speed`),
   - gorbe tipus (`linear`, `soft`, `aggressive`).
2. A rendszer general egy teljes `levels_json` lapot.
3. A user ezt utana manualisan szerkesztheti cellankent.
4. Menteskor validacio fut (novekvo limit, ervenyes tartomanyok).

Ez adja a "konnyu kezdes + profi kontroll" kombinaciot.

## Valtozo cap es max szint kerdes

Igen, valtozo cap mellett lehet olyan profession, ami nem eri el a profile legmagasabb szintjet.
Ez nem hiba, hanem design dontes.

Opcionális strict szabaly:

- `enforceReachableMaxLevel = true`
- validacio: a profession `max_proficiency` erje el legalabb a kijelolt "cel max level" kuszobot.
- ha nem, GUI mentes tiltva vagy warning + megerosites.

---

## 4) Szakma torles problema (JSON blob)

Jelenleg az `e_core` metadata egy JSON oszlopban van (`users.e_core` / `players.e_core`), a kulcsok egyutt elnek minden mas adattal.

Ezert "szakma torles" nem triviális SQL muvelet.

## Biztonsagos megoldas (ajanlott)

Ne kozvetlen SQL `JSON_REMOVE` legyen az elso megoldas, hanem alkalmazas-szintu cleanup:

1. JSON decode
2. csak az ervenyes registry kulcsok megtartasa
3. ujra encode
4. update

Elony:

- framework-fuggetlen marad (ESX/QB),
- ugyanaz a validacio fut mindenhol,
- konnyebb dry-run riportot adni.

## Javasolt cleanup eszkozok

- Szerver oldali admin parancs:
  - `ecore_meta_cleanup_professions --dry-run`
  - `ecore_meta_cleanup_professions --apply`
- Riport:
  - erintett jatekosok szama,
  - torolt kulcsok listaja kategoriankent,
  - hibalista (invalid json rekordok).

## GUI-bol indithato szakma torles (hardening)

A profession torles ne csak config/SQL oldalrol menjen, hanem GUI action legyen, vedelmi lepessekkel:

1. Delete gomb a profession sorban (`crafting.weaponry` tipusu azonositoval).
2. Elso figyelmeztetes: "Ez minden jatekosnal torolni fogja a profession meta kulcsot."
3. Dry-run automatikus futtatasa es eredmeny megjelenites:
   - hany rekord erintett,
   - hany kulcs torlodne,
   - varhato futasi ido becsles.
4. Masodik megerosites (beirasos): profession teljes neve + "DELETE".
5. Async job inditas (nem blokkolo HTTP/UI), allapotkovetessel.

Minimum audit adatok:

- ki inditotta (`admin_identifier`),
- mikor,
- melyik profession (`category`, `name`),
- dry-run eredmeny,
- apply eredmeny (success/fail, counts).

## Runtime vedelmi vonal

`loadMeta()` utan futtatni egy sanitizert:

- eltavolitja az ismeretlen profession kulcsokat az erintett kategoriakban,
- `dirty` esetben visszamenti.

Igy akkor is tisztul az adat, ha valaki nem futtatott kezi cleanupot.

## Nagy adatbazisok: szakaszolt cleanup (batch + resume)

Nagy players/users tablaknal egyszeri, teljes UPDATE nem ajanlott.

Javasolt vegrehajtas:

- Batch meret: pl. 500-2000 rekord/kor (konfiguralhato).
- Cursor alapu bejaras (pl. `id` vagy stabil rendezesi kulcs szerint).
- Minden batch utan progress mentes `e_core_cleanup_jobs` tablaba:
  - `job_id`, `status`, `last_cursor`, `processed`, `changed`, `failed`.
- Rovid sleep a batchek kozott (DB teher elosztas).
- Resume kepesseg: ujrainditas utan ugyanonnan folytathato.
- Abort lehetoseg: futo job biztonsagos leallitasa.

Operatori best practice:

- eloszor `dry-run`,
- forgalommentesebb idoszakban `apply`,
- kezdetben kisebb batch,
- monitorozas (DB latency, lock varakozas, error rate).

Technikai irany:

- ne "full table lock" jellegu SQL muvelet legyen,
- decode -> sanitize -> encode alkalmazas-szintu batch pipeline maradjon.

## Admin UI diagnostics integracio (on-demand tesztfuttatas)

Cel: a mar meglevo diagnostics tesztek legyenek beagyazhatoak az admin feluletbe, de ne automatikus "mindent futtat" modban, hanem tesztenkenti, gombnyomasos inditassal.

Elvart viselkedes:

- Tesztlista modulonkent (pl. inventory, labor, meta, callback, migration).
- Minden teszthez kulon `Run` gomb.
- Opcionális `Run selected` es `Run all`, de alapertelmezetten manualis inditas.
- Minden futas kulon `run_id`-t kap es allapotkovetheto:
  - `queued`, `running`, `passed`, `failed`, `cancelled`.
- Eredmeny ket szinten:
  - rovid osszegzes (pass/fail, futasi ido),
  - reszletes log (raw output / reason).

Backend/API irany:

- `POST /admin/diagnostics/run` (`test_key` vagy tomb)
- `GET /admin/diagnostics/runs/:run_id`
- `POST /admin/diagnostics/runs/:run_id/cancel`

Backend-first allapot (F2-T5):

- profession torleshez kapcsolt cleanup dry-run/apply backend exportok keszen,
- `jobId` alapu cleanup status/get + `abort`/`resume` alap endpoint szerzodes keszen,
- admin audit lista backend oldalon elerheto; UI erre epitheto a kovetkezo korben.

Biztonsag es uzemeltetes:

- csak admin/ace jogosultsaggal indithato.
- audit log kotelezo (ki, mikor, mit futtatott, eredmeny).
- eroforras-igenyes tesztekhez warning badge + opcionális megerosites.
- concurrency limit (pl. egyszerre max 1-2 aktiv futas).
- timeout/retry policy tesztenkent konfiguralhato.

## Modern Proficiency UI kovetelmenyek (jatekos oldal)

Referencia: ArcheAge stilusu rank/profession panel modernizalt megfeleloje.

Cel:

- a jatekos egy helyen lassa a haladasat szakmankent,
- egyertelmu legyen, hogy az adott rank milyen bonuszokat ad,
- lassa mi kell a kovetkezo szinthez es milyen cap/korlat ervenyes.

### Fokepernyo (Profession dashboard)

- kategoriankenti bontas (`harvesting`, `crafting`, `special`, stb.),
- profession kartya:
  - nev + ikon,
  - aktualis pont,
  - aktualis rank (szam/cimke),
  - progress bar a kovetkezo rankig,
  - cap jelzes (`isCapped`) ha elerte a plafont.
- osszegzett jelzok:
  - kategoriankenti slot limit/hasznalat,
  - globalis specializacio limit (ha van ilyen gameplay szabaly).

### Rank Details modal (profession specifikus)

Kijelolt professionhoz tablazatos nezet:

- rank nev/sorszam,
- proficiency range (tol-ig),
- bonuszok oszlopok:
  - labor cost reduction,
  - production time reduction,
  - price reduction,
  - chance bonus,
  - speed bonus.
- aktualis rank kiemeles,
- kovetkezo rank kovetelmeny jelzes.

Megjegyzes:

- a bonusz oszlopok a professionhoz rendelt level profile-bol jonnek (`levels_json`),
- nem globalis fix tabla, hanem profile-fuggo render.

### Informacios minoseg (best practice)

- mindig mutassa:
  - `current points`,
  - `current rank`,
  - `points to next rank`,
  - `active discounts now`.
- cap eseten:
  - "Max proficiency reached for this profession" status,
  - rank up CTA helyett ertelmes allapotjelzes.

### Data contract (NUI)

A jelenlegi `INIT`/`UPDATE` payloadot boviteni kell profession/profile adatokkal:

- profession registry snapshot,
- profession -> profile hozzarendeles,
- profession cap (`abilityCap`) es cap allapot (`isCapped`),
- rank detailshez eloallitott sorok (vagy eleg adat a kliens oldali generalashoz).

### UX minosegi elvek (modern megfelelo)

- reszponziv kartyas elrendezes,
- gyors kereshetoseg/szures profession nevre,
- konzisztens szinrendszer rank szintekhez,
- akadalymentesebb tipografia (olvashato szamok, kontraszt),
- animacio csak visszafogottan (rank up feedback), nem terhelesfokuszban.

## Admin Console (modern, jol tagolt felulet)

Cel: kenyelmes, atlathato, napi uzemeltetesre alkalmas admin felulet, ahol a szakma/progression, diagnostics, cleanup es dokumentacios tamogatas egy helyen elerheto.

### Frontend stack dontes (Svelte)

Igen, a Svelte jo irany ehhez.

Konkret ajanlas: **Svelte 5** modern API-val:

- runes alapu allapotkezeles (`$state`, `$derived`, `$effect`),
- tiszta komponens-hatarok,
- kevesebb kulso helper/boilerplate.

Miert:

- hosszu tavon karbantarthatobb admin konzol,
- jobb prediktalhatosag reaktiv adatfolyamnal,
- egyszerubb tesztelhetoseg modulonként.

Tovabbi elvek:

- gyors, konnyu runtime,
- komponens alapu, jol karbantarthato admin UI,
- egyszeru state kezeles kisebb/kozepes dashboardokhoz,
- jo developer UX gyors iteraciokhoz.

Javaslat:

- Admin UI kulon app-kent (`admin-web`) Svelte(+TypeScript) alapon,
- e_core backend API-kra csatlakozik,
- fokozatos bevezetes: eloszor Diagnostics + Szakmak, utana tobbi modul.

Kompatibilitas-jovoallósag:

- **Mostani atalakitasi fazis:** kompatibilitas nem elvaras; lehet toro valtozasokat csinalni, ha ez kell a tiszta uj alapokhoz.
- **Kovetkezo (stabil) fazis:** ugy kell kialakitani az API-kat, hogy kesobb tobb consumer script is erre tamaszkodhasson.
- Stabil fazisban: stabil export szerzodes + verziozott valtozaskezeles.
- Stabil fazisban: toro valtozas csak indokoltan, dokumentalt migracios utvonallal.

Strukturális elv:

- a mai bevalt struktura kovetese (service modulok + vekony export reteg),
- atalakitasi fazisban celzottan johet uj helper/absztrakcio, ha gyorsitja a rendezett ujraepitest,
- stabil fazisban csak indokolt esetben uj helper reteg; felesleges komplexitast kerulni.

### Tab struktura (MVP -> bovitheto)

1. `Overview`
   - rendszer allapot, aktiv cleanup jobok, utolso diagnostics runok.
2. `Diagnostics`
   - tesztenkenti manualis inditas,
   - futas status, elo log, eredmeny.
3. `Documentation`
   - kulso, kozponti dokumentacio (GitHub Pages) index/link gyujto,
   - szakaszokra ugrashoz deep-link ankerek/hivatkozasok.
4. `Professions`
   - szakma lista, letrehozas/szerkesztes/tiltas/torles.
5. `Level Profiles`
   - profil valasztas, easy mode generalas, manual szerkesztes.
6. `Cleanup Jobs`
   - dry-run/apply futasok, progress, resume/abort.
7. `Audit`
   - admin muveletek naploja.

### Diagnostics -> Dokumentacio ajanlo rendszer

Kovetelmeny: sikertelen teszt utan a rendszer ajanlja fel, melyik doksi szakasz segithet.

Backend-first megvalositasi elv:

- eloszor a backend adatszerzodes keszul el (`docHints` a diagnostics eredmenyben),
- utana erre epul a UI oldali "Recommended Docs" blokk.

Javasolt mechanizmus:

- minden diagnostics teszthez legyen `docHints` mező:
  - `docId` (pl. `PUBLIC_API_HU`, `DB_MIGRATIONS_HU`),
  - `sectionKey` (pl. `profession-registry-validation`),
  - `docUrl` (kozvetlen GitHub Pages deep-link),
  - `severity` / `confidence`.
- fail eseten a UI "Recommended Docs" blokkot mutat:
  - 1-3 legrelevansabb szakasz kattinthato kulso linkkel.
- opcionális "Open relevant section" gomb.

Dokumentacio tarolasi dontes (admin konzol):

- alapertelmezett megoldas: **kulső linkeles** a kozponti GitHub Pages docs oldalra,
- a `Documentation` tab ebben a fazisban nem iframe embed, hanem docs navigator + "Open in Docs" jellegu kiugro linkeket ad,
- opcionális kesobbi bovites: iframe preview mode feature flaggel, ha UX oldalrol szukseges.

Peldak:

- recipe profession invalid -> profession registry doksi vonatkozo szakasz,
- cleanup fail -> cleanup job/operator szakasz,
- level profile validacio fail -> level profile validacios szabalyok.

### Interaktiv visszajelzes (Diagnostics fül)

- run-id alapu live allapotfrissites (`queued/running/...`),
- step-by-step checklist allapotok,
- raw log panel (szurheto),
- hiba ok + javasolt kovetkezo lepes.

### UX minosegi kovetelmenyek (admin oldal)

- erosen tagolt layout (bal oldali nav + fo tartalom),
- hosszu muveleteknel progress bar + ETA jelzes,
- destructive akcioknal ketlepcsos megerosites,
- undo ahol lehet (soft delete/disable),
- minden kritikus akcio audit logot ir.

---

## 5) Bevezetesi terv (nem tulbonyolitott)

### Fazis 1 - DB schema + bootstrap

- uj tablák: `e_core_professions`, `e_core_level_profiles`
- bootstrap script a jelenlegi configbol alap profilokhoz
- read-only exportok DB forrasrol

### Fazis 2 - GUI backend API

- profession CRUD
- profile CRUD (easy generalas + manual szerkesztes + validacio)
- profession <-> profile hozzarendeles
- diagnostics test endpointok on-demand futtatashoz
- doc hint endpoint fail esetekhez (`test_key` -> relevans doksi szakaszok)
- admin UI-hoz szukseges szerzodesek/foundation:
  - auth + jogosultsag endpoint policy,
  - run-id/status contract diagnostics futasokhoz,
  - standard response format (`ok`, `code`, `message`, `data`).

### Fazis 3 - Consumer atallas

- eco_crafting `initMeta` registry alapu inicializalas (DB)
- recipe validacio: csak registryben letezo profession engedett
- level/discount lookup profile alapjan
- modern proficiency NUI: dashboard + rank details modal (profession/profile alapon)

### Fazis 3 e_core-only elokeszites (consumer hid)

- `F3-E2`: uj backend helper/export `validateProfessionKeys(category, keys[])`
- cel: a kesobbi consumer startup recipe-validacio (`S1-T5`) ne ad-hoc ellenorzes legyen, hanem kozponti e_core service-re epuljon
- vart kimenet:
  - `valid` lista
  - `invalid` lista
  - `missingProfile` lista
- `F3-E3`: diagnostics tesztkatalogus bovitese `profession-key-validation` tipussal
  - cel: consumer bekotes elott is legyen kesz diagnostics gerinc
  - fail agban docHint mapping finomitas (registry terv + sprint terv + API szakaszok)
- `F3-E4`: cleanup/diagnostics/denied audit esemenyek kozos shape-re hozasa
  - kozos contract: `eventType`, `actor`, `target`, `outcome`
  - cel: UI es kesobbi reporting oldalon egységes audit feldolgozas

### Fazis 3.5 - Admin Console MVP (Svelte)

- Svelte 5 admin UI MVP (runes alapu state)
- tabok: Overview, Diagnostics, Documentation, Professions, Level Profiles
- diagnostics live run + fail eseti dokumentacio ajanlo
- profession letrehozo/szerkeszto alap workflow
- level profile valasztas + easy mode generalas alap nezet

### Fazis 4 - Meta cleanup tooling

- dry-run admin command
- apply command
- log + osszefoglalo
- GUI-bol indithato profession delete workflow (ketlepcsos megerositessel)
- batchelt, folytathato cleanup job infrastruktura (`resume`, `abort`, progress)
- admin UI-bol tesztenkenti diagnostics futtatas (`run_id`, status, log)
- admin UI halado modulok:
  - Cleanup Jobs tab (progress + resume/abort),
  - Audit tab reszletes nezet,
  - nagy DB futasok operacios kontrolljai.

### Fazis 5 - Runtime sanitizer

- `loadMeta` utan profession kulcs normalizalas
- dirty meta automatikus visszamentese

### Fazis 6 - Strict szabalyok (opcionalis)

- hard fail ismeretlen professionre
- opcionális "max rank elerhetoseg" validacio

---

## Elfogadasi kriteriumok

- uj szakma csak registry (DB) modositassal johet letre,
- recipe eliras nem hoz letre uj szakmat csendben,
- professionhoz kotelezo level profile tartozik,
- easy mode altal generalt profile manualisan is szerkesztheto es validalva mentheto,
- van dry-run + apply cleanup folyamat,
- szakma torles GUI-bol indithato, ket megerositessel es audit loggal,
- nagy adatbazisnal a cleanup batchelt, folytathato es monitorozhato,
- diagnostics tesztek admin UI-bol egyenkent indithatok es visszakeresheto eredmenyt adnak,
- diagnostics fail eseten dokumentacio szakasz ajanlas automatikusan megjelenik,
- admin UI jol tagolt tabos szerkezetben kezeli a profession/profile/diagnostics/cleanup folyamatokat,
- jatekos oldalon modern proficiency felulet mutatja professionenkent a rankot, progresszt es bonuszokat,
- regi, torolt szakmak kulcsai eltuntethetok JSON-bol adatvesztes nelkul,
- dokumentalt uzemeltetoi folyamat van profession bevezetes/kivezetesre.

---

## Dontesi javaslat

Ez a modell jobb kontrollt ad, mint a recipe-derived auto-regisztracio.
Az uzemeltetesnek kiszámíthatóbb, auditálhatóbb, es meggatolja az elirasbol eredő hibas szakmaneveket.

## Megvalositasi bontas (Sprint 1)

A blueprinthez tartozó konkret, task-szintu implementacios terv:

- `docs/PROFESSION_REGISTRY_IMPLEMENTACIOS_TERV_SPRINT1_HU.md`
- futas kozbeni egyhelyes valtozasnaplo: `docs/IMPLEMENTATION_MUNKANAPLO_WIP_HU.md`
