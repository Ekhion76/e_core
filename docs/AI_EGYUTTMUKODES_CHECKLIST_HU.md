# Meglévő projekt átalakítása / debug Cursor AI-val – kezdőlista

## Projekt alap (e_core – kontextus összefoglaló)

- **Cél:** eladható, **escrow-os** `eco_*` szkriptek **ismeretlen szerveren** is működjenek megbízhatóan; az ügyfél **nem** szerkeszti a zárt kódot.
- **Szerep:** **nyílt adapter** – egy helyen illeszkedik az idegen stackhez; a titkos rész nem ez.
- **Szerződés:** a consumer az **`eCore` / export API**-n hív (pl. itemek), az e_core **az aktuális keretrendszer + kiegészítő** megfelelő hívására fordítja, és visszaadja az eredményt.
- **SDK-szerű cél:** ne csak belső „glue” maradjon; ugyanarra a szerződésre építünk: publikus, dokumentált és verzióhoz kötött felület (changelog, támogatott stack, indulás és hibák előre jelezhetősége) – lásd README és [MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md](MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md).
- **Korlát:** sok inventory / eszköz **fizetős vagy ritka** → **szűk** az előre beépített lista; ez **szándékos**, nem feltétlenül „hiányos termék”.
- **Közösség (opció):** nyílt repo → mások is használhatják → **nagyobb dokumentáció** kellene (pl. ox-szint), de **nem első sprint**.
- **Állapot:** korábban kiadva mint „minimum”; **nem béta-szintű átláthatóság**; fáradtság, elveszett rálátás → folytatás **struktúrával + AI-val**.
- **Prioritás most:** **életképesség + audit + területekre bontás** – több funkció **≠** nagyobb „erdő”; **átosztható modulok és határok** (`bridge/` vs `standalone/overrides/`).
- **Később élesíthető:** elsődleges célközönség (eco vs általános adapter); **minimálisan garantált** stack (teszt / támogatás).

- **Tebex / termék:** egy éles script **eco_crafting** (~3+ év); jelenleg **csak ez** használja az e_core-t.
- **Stratégiai elágazás:** (1) **központi e_core** fejlesztése + erre illesztés vs (2) **szkriptenként külön** illesztő fájl (ügyfél tölti ki: inventory, üzenet, progressbar…). *Munkamenetben rögzítve: **1. irány** (központosítás, több eco termék + közös labor); ritka / ismeretlen stack → `standalone/overrides/`.*
- **e_core melletti érvek:** **labor** (tevékenység → pontok, fogyás, regeneráció pl. 5 percenként, offline is); **jártasság** (elköltött labor → proficiency → kevesebb idő/labor); **központi beállítások** már most (nyelv, pénznem, egységek, labor/perc…). Kérdés: a vásárlók **be tudják-e** lőni a környezetüket egy nagy, robosztus core-ba → **dokumentáció + felépítés** kritikus.
- **UX / konfig:** kényelmes állíthatóság – **grafikus panel** (pipák, csúszkák) vs **config fájl**; **hova menteni**, hogyan **importálja** az `eco_*`; „egyszer beállítom” vs panel **túlzás**-e.
- **Robosztusság:** a jártasság rendszer **még nem elég** erős; általános **tanácstalanság** + nyers ötletek gyűjtése továbbra is.
- **Ox vonal:** `ox_*` **gyakorlatilag kikerülhetetlen** (pl. SQL / mysql); felmerül: **ox_lib** mélyebb használata, **modul felépítés** – ezzel jár a **szerveren futó ox_lib verzió** függősége (vállalás + **minimum verzió** + javítás **egy helyen** az e_core-ban, nem changelog-fejben).
- **Ötletlista (későbbi döntés / fázisok):** központi szín + téma; labor fejlesztés; **funkció- és export-doks**i (repo + wiki-szerű?); jártasság lap (szakmák, rank, „mi mennyit változtat”); cap szakmánként; billentyű / bind game settingsből; HUD mozgatási réteg; felhasználóbarátság; **admin felület**; több konfig egybe vonása; **GitHub-os doks**i mint az ox.


** ----- **


Ezt akkor használd, amikor **egy már létező** projekten szeretnél refaktort vagy hibakeresést csináltatni. Minél több pontot kipipálsz **a beszélgetés elején**, annál kevesebb kört veszítünk el félreértésen.

**Kapcsolódó fájlok:** [PROJECT_STRUCTURE.txt](PROJECT_STRUCTURE.txt) (mappa szerepek és fa), [MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md](MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md) (hosszabb technikai terv, ha releváns), [REFAKTOR_PRIORITAS_UZEMTERV_HU.md](REFAKTOR_PRIORITAS_UZEMTERV_HU.md) (rögzített A–G prioritás).

---

## 1. Környezet és keret (projekt: e_core)

- [x] **FiveM**, Lua verzió (`lua54`)
- [x] **Keretrendszer(ek):** ESX, QB, QBox (a szerveren általában csak egy aktív core)
- [x] **Kritikus függőségek:** `oxmysql`, `ox_lib` (manifest / shared)
- [x] **server.cfg sorrend:** `e_core` → `eco_*` (és egyéb e_core-ra épülő resource-ok előtt)

---

## 2. Projekt megnyitása Cursorban

- [ ] **Workspace gyökér:** c:\FX_ESX_ox\ESX\resources\[eco]\e_core\
- [ ] **`.cursor/rules/`** A project élesítve fut. Kompatibilitás megörzése cél. Ettől eltérni csak dokumnetálva és csak ha fölösleges kódbonyolítást okozna. FONTOS! Kerüld a kódbonyolítást, ne csinálj kerülő ágakat szó nélkül. Ha ilyen kell, kérdezz meg.

---

## 3. Kontextus fájlok (e_core repóban)

- [x] [docs/PROJECT_STRUCTURE.txt](PROJECT_STRUCTURE.txt) – fejlécben **mappa szerepek** + alatta fájlfa (override-ok változáskor frissítendők).
- [x] [README_HU.md](../README_HU.md) / [README.md](../README.md) – „Fejlesztőknek / AI és Cursor kontextus” szekció megvan, linkek rendben.
- [x] [.cursor/rules/e_core-context.mdc](../.cursor/rules/e_core-context.mdc) – Cursor alwaysApply kontextus; más workspace gyökérből dolgozva érdemes említeni vagy a szabályt átmásolni (lásd a fájl utolsó szekcióját).
- [x] [docs/MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md](MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md) – hosszú táv / megbízhatóság / SDK célok; első üzenetben opcionális, refaktor és architektúra témánál hasznos.

**Export / API példák (első üzenetben, ha releváns):** [export_examples_client.md](../export_examples_client.md), [export_examples_server.md](../export_examples_server.md)

**AI szupport referencia:** [AI_SUPPORT_REFERENCE_HU.txt](AI_SUPPORT_REFERENCE_HU.txt) – **élő dokumentum** (fejlesztés közben bővítendő): kódstruktúra, exportok, eCore áttekintés, GYIK; záráskor teljes audit. Első üzenetben érdemes csatolni / @-olni, ha API vagy integráció a téma. Részletek: [MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md](MODERNIZACIOS_ES_MEGBIZHATOSAGI_TERV_HU.md) → *3B* (API / AI referencia); architektúra döntés: *2. fejezet*.

**e_core – kritikus részek az első üzenetben (2–3 mondat, alapértelmezés):** Más resource-ból a belépés: `imports/core.lua` minta → `exports.e_core:getFrameWork()`, `getCore()`, `getConfig()`. Testreszabás és frissítésbiztonság: **`standalone/overrides/*`**, ne a `bridge/` tömeges szerkesztése; `server.cfg`-ben `ensure e_core` a consumer resource-ok előtt. Ha **eco_*** debug: csatolandó a konkrét resource és a releváns esemény/export nevek (pl. craft flow, saját progress callback).

---

## 4. Cél és határ (e_core / eco vonal)

- [ ] **Cél:** a kód robosztussá tétele, hogy versenyképes, kényelmes és megbízható legyen. SDK-szerű réteg-nek kialakítani.
- [ ] **Első körben:** kód feltérképezése + Cursor / docs segédfájlok (struktúra, checklist, szabályok) – összhangban a [PROJECT_STRUCTURE.txt](PROJECT_STRUCTURE.txt) bővítésével.
- [ ] **Nem cél (add meg konkrétan új chatben):** pl. NUI kinézet változatlan; breaking exportok nélkül; stb.

---

## 5. Bug / viselkedés esetén (debug)

- [ ] **Elvárt vs. tényleges** viselkedés (3–7 lépés).
- [ ] **Kliens vagy szerver**; F8 / szerver konzol üzenet (szöveg bemásolva).
- [ ] **Reprodukálható** mindig ugyanazzal a lépéssel, vagy „random”?
- [ ] **Stack:** ESX vagy QB + melyik inventory / progress (ha ismert).
- [ ] **Ne** illess be titkot: webhook URL jelszóval, DB jelszó, licenc kulcs.

---

## 6. Refaktor esetén

- [ ] **Viselkedés változhat-e** ez az érintett területtől függ. Ha csatolom az egyetlen szkriptet ami használja segít eldönteni.
- [ ] **Manuális teszt 3–5 pont** (pl. egy craft, több darab, cancel).
- [ ] **Fázisokban** kérj nagyobb refaktort, ne egy üzenetben az egész resource.

---

## 7. Teljesítmény panasz

- [ ] Van-e **mérés** (resmon, tick), vagy csak érzés?
- [ ] **Elvárt:** kevesebb CPU vs. kevesebb DB hívás – specifikusabb jobb.

---

## 8. Biztonság

- [ ] Exploit / dupla item: mit csinálhat a játékos, mit nem szabadna?

---

## 9. Első üzenet sablon (másolható)

```
Projekt: e_core (vagy e_core + eco_*)
Workspace: [teljes útvonal a resource mappához]
Cél: [egy mondat]
Nem cél: […]
Környezet: [ESX/QB + inventory + progress ha ismert]
Repro / teszt: [lépések vagy „nincs bug, csak refaktor/doksi”]
Dokumentumok: docs/PROJECT_STRUCTURE.txt, docs/AI_EGYUTTMUKODES_CHECKLIST_HU.md, .cursor/rules/e_core-context.mdc; exporthoz: export_examples_client.md, export_examples_server.md; ha elérhető: docs/AI_SUPPORT_REFERENCE_HU.txt (struktúra + export API magyarul)
```

---

*Igény szerint bővíthető saját „mindig ezt küldd el” pontokkal.*
