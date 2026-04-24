# e_core – területenkénti audit (sorban, kontroll alatt)

**Probléma:** függvényenként kérdezgetni fárasztó, és nem látszik a haladás.

**Megoldás:** **egy terület = egy logikai egység** (általában 1–3 szorosan kapcsolódó fájl). Egy beszélgetésben / PR-ban **végigmegyünk az egész területen** (validáció, hibák, edge case, doksi szinkron) – ahogy a **meta** rétegnél történt.

Nem kell minden exportot külön megemlíteni: elég a **sor száma** vagy a **terület neve** ebből a táblázatból.

---

## 1. Ajánlott sorrend (függőség és kockázat szerint)


| Sor    | Terület                 | Fő fájlok                                                                 | Mit jelent „kontroll alatt”                                                                       | Állapot                                                |
| ------ | ----------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| **1**  | Meta (szerver + szint)  | `server/meta.lua`, `libs/meta.lua`                                        | Export szerződés, `eCoreErr`, trim, reserved kulcsok, `messageIfLevelChange` / `checkLevelChange` | **Kész** 0.0.40 jártasság / getDiscounts hibakód audit |
| **2**  | Labor                   | `server/labor.lua`, kapcsolódó kliens olvasás `client/main.lua` részletek | Guard, összeg limit, sync, tick                                                                   | **Kész** 0.0.41 getLabor szerződés, mennyiség guard, `not_enough_labor` |
| **3**  | Meta perzisztencia      | `server/db.lua`, `server/db_migrations.lua`                               | `mysqlAwait`, load/save, migráció verzió                                                          | **Kész** 0.0.42 loadMeta JSON / üres string, save/load cLog, migráció SELECT fail-fast |
| **4**  | Kliens meta / NUI       | `client/main.lua`, `client/exports.lua`                                   | Cache vs szerver, sync, `getAbility` / `getLabor` hibák                                           | **Kész** 0.0.43 kliens `getAbility`/`getMeta` trim + `no_valid_meta_name`, `getLabor` szám guard, `e_core:sync` tábla payload |
| **5**  | Globál shared inventory | `bridge/global/shared.lua`                                                | `canCarryItem`, `canSwapItems`, súly hibák                                                        | **Kész** 0.0.44 szimuláció nem ír inventoryt; `invalid_item_data` / `item_not_registered` |
| **6**  | Globál szerver          | `bridge/global/server.lua`                                                | `createVehicle`, jármű hibák                                                                      | **Kész** 0.0.45 bemenet / entitás / netId 0 csapda, `unknown_error`, árva jármű törlés |
| **7**  | Keretrendszer inventory | `bridge/esx/server.lua`, `bridge/qb/server.lua` (inventory ágak)          | `removeItems`, `ok` / string literálok                                                            | **Kész** 0.0.46 `removeItems` sor validáció, `invalid_item_data`, ESX `pcall` + `unknown_error` |
| **8**  | Override inventory      | `standalone/overrides/*/server.lua` (ox, qs, avp, …)                      | Stack-specifikus, `eCoreErr` konzisztencia                                                        | **Kész** 0.0.47 override `removeItems` sor + `xPlayer` / `pcall`; ox/qs `addItem` második érték normalizálás; avp `canCarryItem`/`canSwapItems` ok-pár, külső `reason` → `eCoreErr` |
| **9**  | Export vékony réteg     | `server/exports.lua`, `client/exports.lua`, `bridge/main.lua`             | Névsor = implementáció, nincs elágazás rejtve                                                     | **Kész** 0.0.48 névsor = PUBLIC_API §2–§3; fejléc-kommentek; doksik §1 / ECORE §3 export-réteg megjegyzés |
| **10** | Diagnosztika            | `server/diagnostics.lua`, `client/diagnostics.lua`                        | Jogosultság, smoke bővíthetőség                                                                   | TODO                                                   |


Az **Állapot** oszlopot a repóban ti tartjátok karban (vagy PR leírásban: „Terület 2 kész”); commitban frissítve látszik a haladás.

---

## 2. Másolható üzenet sablon (Cursor / AI / kolléga)

Egy következő körben elég ez (cseréld a `N`-et):

```
Terület audit: sor #N a docs/TERULET_AUDIT_SORREND_HU.md szerint.

Cél: stabil viselkedés, egyértelmű hibák (eCoreErr), rejtett csapda nélkül;
kapcsolódó doksik: PUBLIC_API §5, ECORE_ERR_HIBA_NYOMON, export_examples ha export;
changelog + fxmanifest version ha viselkedés / API változik.

Hatókör: csak az adott sor fájljai, felesleges refaktor nélkül.
```

Így **nem** kell felsorolni minden függvényt: a sor **már definiálja** a hatókört.

---

## 3. Mit várunk egy „kész” területtől (rövid checklist)

- Bemenetek: típus / `nil` / üres string kezelése **dokumentált** vagy **explicit hiba**.
- Hibák: `eCoreErr` (új kulcs → `libs/errors.lua` + `docs/PUBLIC_API_HU.md` §5 + `docs/ECORE_ERR_HIBA_NYOMON_HU.md` §3).
- Shared + net: szerver-only hívások védve (`IsDuplicityVersion` ahol kell).
- Consumer: releváns `export_examples_*.md` / `AI_SUPPORT_REFERENCE` egy mondat, ha szemantika változott.

---

## 4. Kapcsolódó doksik

- `**docs/ECORE_ERR_HIBA_NYOMON_HU.md`** – ha már konkrét `reason` string van a reproban.
- `**docs/PUBLIC_API_HU.md**` – szerződés, export lista.
- `**docs/AI_SUPPORT_REFERENCE_HU.txt**` – mély paraméter / GYIK.

---

*A sorrendet igény szerint módosíthatjátok (pl. labor előrébb a saját szerveretek prioritása szerint). A lényeg: **terület = egy egység**, ne függvényenkénti ping-pong.*