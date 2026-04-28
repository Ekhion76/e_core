# e_core – side-effect audit (állapot + checklist)

**Cél:** nyomon követni, hol tart a **pure modul vs. init** szétválasztás; nem deficit-lista, hanem **üzemeltethető** checklist új refaktorokhoz.

## Lezárt / bevezetett minta

| Terület | Állapot | Megjegyzés |
|---------|---------|------------|
| **Labor** | Refaktorálva | `logic.lua` (pure), `init.lua` (timer / regisztráció), `Config.systemMode.labor` gate |
| **Professions** | Facade + gate | `professions/logic.lua` — `profession` + `labor` flag; exportok `feature_disabled`; bootstrap `init.lua` / DB hook szétválasztva ahol bevezetve |
| **SDK útvonalak** | Lezárt | `src/imports/sdk/{shared,client,server}` + `fxmanifest` `files { }` |
| **Web bridge** | Refaktorálva | `web_bridge/server.lua` + `client.lua` pure modul; regisztráció: `init.lua` + `init_client.lua` |
| **Integrity bridge** | Refaktorálva | `integrity/server.lua` + `client.lua` pure modul; regisztráció: `init.lua` + `init_client.lua` |
| **Admin/Diagnostics NUI bridge** | Refaktorálva | `server_nui_bridge.lua` / `client_nui_bridge.lua` pure; domain initből történik a regisztráció |
| **HUD client registry** | Refaktorálva | `registerClientBindings()` + külön `hud/client/init.lua` side-effect entry |

## Átnézendő (nagyobb felület – iteratív)

- **Bridge** (`src/bridge/**`): megfelelő helyen shared vs. server/client; top-level események indokolt-e.
- **Libs** (`src/libs/**`): helper modulok maradjanak többségében pure; ritka globális (`eCoreErr`) dokumentált.
- **További runtime domainek**: a mintát tartsd új moduloknál is (logic pure, side-effect init/bootstrap).

## Ellenőrző kérdések (PR-ben)

1. Van-e **top-level** `RegisterNetEvent` / `CreateThread` egy „logic” fájlban? → mozgatás **`init.lua`** vagy bootstrapba.
2. Kikapcsolt **`systemMode`** mellett fut-e még felesleges listener? → gate az init előtt.
3. Új export **feature off** esetén **`false`, `eCoreErr.feature_disabled`** (vagy dokumentált admin válasz)?
4. Kliens **`lib.require('@e_core/...')`:** szerepel a cél fájl az e_core **`files { }`** listában?

## Kapcsolódó

- Policy: `docs/ECORE_ARCHITECTURE_MODULARITY_HU.md`
- Hibakód: `docs/ECORE_ERR_HIBA_NYOMON_HU.md` (`feature_disabled`)
