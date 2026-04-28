# e_core – side-effect audit (állapot + checklist)

**Cél:** nyomon követni, hol tart a **pure modul vs. init** szétválasztás; nem deficit-lista, hanem **üzemeltethető** checklist új refaktorokhoz.

## Lezárt / bevezetett minta

| Terület | Állapot | Megjegyzés |
|---------|---------|------------|
| **Labor** | Refaktorálva | `logic.lua` (pure), `init.lua` (timer / regisztráció), `Config.systemMode.labor` gate |
| **Professions** | Facade + gate | `professions/logic.lua` — `profession` + `labor` flag; exportok `feature_disabled`; bootstrap `init.lua` / DB hook szétválasztva ahol bevezetve |
| **SDK útvonalak** | Lezárt | `src/imports/sdk/{shared,client,server}` + `fxmanifest` `files { }` |

## Átnézendő (nagyobb felület – iteratív)

- **Bridge** (`src/bridge/**`): megfelelő helyen shared vs. server/client; top-level események indokolt-e.
- **Libs** (`src/libs/**`): helper modulok maradjanak többségében pure; ritka globális (`eCoreErr`) dokumentált.
- **További runtime domainek** (`admin`, `diagnostics`, `integrity`, `web_bridge`, …): új refaktor követi a **logic / init** mintát, ahol van értelmes határ.

## Ellenőrző kérdések (PR-ben)

1. Van-e **top-level** `RegisterNetEvent` / `CreateThread` egy „logic” fájlban? → mozgatás **`init.lua`** vagy bootstrapba.
2. Kikapcsolt **`systemMode`** mellett fut-e még felesleges listener? → gate az init előtt.
3. Új export **feature off** esetén **`false`, `eCoreErr.feature_disabled`** (vagy dokumentált admin válasz)?
4. Kliens **`lib.require('@e_core/...')`:** szerepel a cél fájl az e_core **`files { }`** listában?

## Kapcsolódó

- Policy: `docs/ECORE_ARCHITECTURE_MODULARITY_HU.md`
- Hibakód: `docs/ECORE_ERR_HIBA_NYOMON_HU.md` (`feature_disabled`)
