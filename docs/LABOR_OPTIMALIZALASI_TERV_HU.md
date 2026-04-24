# Labor/jártasság optimalizálási terv (egyszerű, fokozatos)

## Cél

Az `eco_*` consumerekben a labor költség számítása legyen:

- kevesebb lekérdezéssel működő,
- konzisztens (kliens és szerver ugyanazt a logikát használja),
- könnyen bővíthető szakmánkénti szabályokra.

## Kiinduló probléma

Jelenleg több helyen külön fut a lánc:

- `getLabor`
- `getAbility`
- `getDiscounts`
- (esetenként) `getMeta`

Ez gyakori akcióknál (pl. `eco_collecting` traktoros aratás, kb. másodpercenként) felesleges hívásszámot és duplikált logikát eredményez.

## Döntés: rang-alapú kedvezmény jó irány?

Röviden: **igen, jó és skálázható irány**.

Miért:

- a felhasználó számára érthetőbb (szintlépcsők),
- jól kommunikálható UI-ban (következő szint kedvezménye),
- stabilabb balanszolás (nem túl finom, nehezen követhető százalékos mikroeltérések).

Megjegyzés: a belső számítás továbbra is történhet pont + interpoláció alapján, de a játékos felé a szint/rang maradjon az elsődleges modell.

## Szakmánként állítható maximum haladás kell?

Röviden: **igen, érdemes bevezetni**.

Várható igények:

- eltérő szerver-gazdaság szakmánként (collecting vs crafting vs fishing),
- event/szezon rendszerek (időszakos emelt cap),
- progression pacing finomhangolás külön szakmákra.

Javaslat:

- szakmánként `maxProficiency` (vagy `maxLevel`) konfig,
- default fallback globális értékre,
- cap fölött ne nőjön tovább az ability, de a folyamat működjön.

## Egyszerű optimalizálási terv (implementációs sorrend)

### 1) Aggregált quote API bevezetése e_core oldalon

Új szerver oldali hívás, pl.:

- `getLaborQuote(playerId, context)`

Visszaad legalább:

- `paidLabor`
- `discounts`
- `proficiency`
- `level`
- `hasEnoughLabor`
- `code` / `reason`

Ezzel kiváltható a több külön lekérdezéses minta.

### 2) Rövid TTL cache a quote-ra (1-3 mp)

Különösen gyakoribb akcióknál (`eco_collecting`) ugyanaz a játékos rövid időn belül sokszor kér quote-ot.

Javaslat:

- cache kulcs: `playerId + profession + actionType`,
- invalidáció: labor változás, ability változás, releváns meta változás,
- TTL lejárat után újraszámolás.

### 3) Consumer oldali migráció minimálisan

- Kliens: preview/UI a quote objektumból.
- Szerver: végső döntés és levonás szintén quote alapján.
- Eltávolítani a kézzel írt `getLabor + getAbility + getDiscounts` láncokat a consumerből.

### 4) Szakmánkénti cap bevezetése

Konfig szinten:

- `progression.maxByProfession.harvesting.gathering = ...`
- `progression.maxByProfession.crafting.<profession> = ...`

Alkalmazás:

- `addAbility` előtt clamp,
- quote válaszban jelezni, ha cap elérve (`isCapped`).

### 5) Dokumentáció és mintafrissítés

- `docs/PUBLIC_API_HU.md`
- `export_examples_server.md`
- `export_examples_client.md`
- rövid migrációs példa: régi lánc -> quote hívás

## Rollout (nem túlbonyolított)

1. `eco_collecting` pilot (nagy hívásfrekvencia miatt itt látszik leghamarabb a nyereség).  
2. `eco_crafting` migráció ugyanarra a mintára.  
3. többi érintett `eco_*` consumer fokozatosan.

Kapcsolodo terv a szakmaregiszterhez es JSON meta takaritashoz:

- `docs/PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md`
- a tervben mar DB-first szakma/level profile modell szerepel (GUI + easy mode generalas + manual szerkesztes).

## Elfogadási feltételek

- gyakoribb folyamatoknál érzékelhetően kevesebb e_core lekérdezés,
- nincs eltérés kliens preview és szerver végső költség között,
- szakmánkénti cap működik, és configból állítható,
- consumer kód rövidebb és kevésbé duplikált.

## Rövid záró döntés

- A rang/szint-alapú kedvezmény megtartása: **igen**.
- Szakmánként állítható max haladás bevezetése: **igen**.
- Első optimalizációs fókusz: **aggregált quote + rövid cache + collecting pilot**.
