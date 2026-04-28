# e_core – modularchitektúra policy (pure + init)

**Hatály:** belső `src/` kód; a **consumer SDK** globális aliasai külön, dokumentált kivétel.

## Alapelv

1. **Pure modul:** oldalhatás nélküli fájl — főleg **`return` tábla / API**. Kerülendő top-szinten: `RegisterNetEvent`, `AddEventHandler`, `CreateThread`, időzítők (kivéve a kifejezetten erre szánt entry fájlokat).
2. **Init / bootstrap:** regisztrációk, induló szálak — `src/runtime/bootstrap/**/main.lua`, domain szinten **`init.lua`**, vagy dedikált bootstrap chunk a `fxmanifest` sorrendje szerint.
3. **Betöltés:** ahol lehetséges, **`lib.require`** (ox_lib), egységes path konvenció (`src/runtime/...` resource-rel vagy `@e_core/...` — a repóban lévő mintához igazodj).
4. **Feature gate (`Config.systemMode.*`):** ha egy alrendszer ki van kapcsolva, **ne** maradjanak élő regisztrációk (event, timer) csak „üres logikával”. Bootstrap csak akkor hívja az adott domain **`init.lua`**, ha a flag engedi (ahol bevezetésre került: labor, professions).
5. **Graceful degradation (export):** kikapcsolt feature esetén ne ess csendben **`nil`**, se mágikus hiba — olvasó exportok: **`false`, `eCoreErr.feature_disabled`** (vagy domain által dokumentált admin válasz `{ ok = false, code = … }`). Részlet: `docs/PUBLIC_API_HU.md` §5, `libs/errors.lua`.

## `_G` / globál szennyezés

- **Új belső modul:** ne vezess be ad-hoc globálokat; API **`return`**, publikus felület export / registry.
- **Kivétel (SDK):** `imports/sdk/shared/core.lua` stb. **szándékos** `FRAMEWORK` / `eCoreConfig` / `hf` — nevesítve a `PUBLIC_API`-ban.

## Kapcsolódó

- Annotáció policy + szerződés-útvonalak: `docs/LUA_ANNOTATION_MAINTENANCE_EN.md` §6
- Side-effect audit állapot: `docs/ECORE_SIDE_EFFECT_AUDIT_HU.md`
- SDK szótár: `docs/ECORE_IMPORTS_SDK_LAYER_TERVEZES_HU.md`
