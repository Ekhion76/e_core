# e_core – SDK imports réteg (kanonikus szótár)

**Cél:** egyértelműen elválasztani a **platform shared** (e_core saját `fxmanifest` `shared_scripts`) és a **cross-resource consumer SDK** (`src/imports/sdk/**`) fogalmát.

## Fogalmak

| Fogalom | Mit jelent | Példa |
|--------|------------|--------|
| **Platform shared** | Az **e_core** `fxmanifest.lua` által betöltött, **egy resource-on belüli** kliens+szerver kód | `shared_scripts { '@ox_lib/init.lua', 'src/bridge/...', … }` |
| **Bridge shared** | Az e_core bridge **mindkét oldali** modulja | `src/bridge/global/shared.lua` |
| **SDK import / consumer SDK** | Más resource manifestjébe tehető chunk, amely **az e_core fájljaira** hivatkozik (`@e_core/...`) | `src/imports/sdk/core/shared.lua` |

## Könyvtár-struktúra (consumer oldal)

| Mappa | Consumer manifest lista |
|-------|-------------------------|
| `src/imports/sdk/<module>/shared.lua` | `shared_scripts` |
| `src/imports/sdk/<module>/client.lua` | `client_scripts` |
| `src/imports/sdk/<module>/server.lua` | `server_scripts` |

## Fájllista (jelenlegi repó)

- `src/imports/sdk/core/shared.lua`
- `src/imports/sdk/locale/shared.lua`
- `src/imports/sdk/utils/shared.lua`
- `src/imports/sdk/helper_base/shared.lua`
- `src/imports/sdk/hud_drag/client.lua`
- `src/imports/sdk/discord_log/server.lua`

## `full_import.lua`

`full_import.lua` kivezetve. Nincs kötelező core→locale→utils lánc; a consumer külön include-olja, amire ténylegesen szüksége van.

## `lib.require` más resource-ból

- **SDK:** `lib.require('@e_core/src/imports/sdk/core/shared.lua')` stb. — a fájloknak szerepelniük kell az e_core **`files { }`** listájában (SDK chunkok már fel vannak véve).
- **Belső runtime modulok** (pl. `src/runtime/web_bridge/client_logic.lua`): szintén **`files { }`** nélkül a kliens nem látja a fájlt.

## Kapcsolódó

- **Publikus mátrix:** `docs/PUBLIC_API_HU.md` §4.1
- **Modul / init policy:** `docs/ECORE_ARCHITECTURE_MODULARITY_HU.md`
