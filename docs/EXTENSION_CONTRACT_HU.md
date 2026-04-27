# e_core – extension szerződés (belső + publikus)

Cél: egy **közös mentális modell** a `_eCoreInternal.extensions.*` modulokra és a `getCore()` által visszaadott **thin** publikus felületre.

## Belső tábla

- **`_eCoreInternal`**: globál Lua/FiveM korlát miatt; **nem** része a publikus szerződésnek. Consumer **ne** hivatkozzon rá.
- **Dev:** `setr e_core_dev "true"` mellett opcionális `exports.e_core:getInternal()` (csak debug; productionben kapcsold ki).

## Extension regisztráció (e_core resource)

- **Explicit sorrend:** `eCoreLifecycle_registerExtensions()` név szerint hívja a regisztrációs lépéseket (`registerDiscordExtension`, `registerHudExtension`, …). Nincs auto-scan / dinamikus `require` loop az első verzióban.
- **Második fázis:** `eCoreLifecycle_initExtensions(_eCoreInternal)` – opcionális `ext.init(ctx)` hívások extension–extension vagy service függéshez.

## Minimális extension alak (belső)

```lua
_eCoreInternal.extensions.discordLog = {
  create = createDiscordLog, -- példa: factory függvény
}
```

Opcionális bővítés később:

- `name = "discordLog"`
- `init = function(ctx) end` – `ctx` tipikusan `_eCoreInternal`

## Publikus felület (consumer)

- A `exports.e_core:getCore()` visszaadott `eCore` táblába a **`eCoreLifecycle_buildPublicAPI()`** írja be a kurált mezőket (merge). Példa: `eCore.log.discord.create(...)` – thin wrapper, **nem** a nyers `extensions` tábla.
- **TILOS** consumernek: `eCore.getModule(...)`, nyers belső tábla visszaadása exporton.

## Side (client / server / shared)

- **Discord log:** csak szerver (`createDiscordLog` csak szerver chunkban töltődik).
- **Shared consumer:** `eCore.util` tartalmazhat kliens-only native-t igénylő segédet (pl. blip) – shared scriptben csak akkor hívd, ha futási kontextus megengedi (lásd `docs/PUBLIC_API_HU.md` / util megjegyzés).

## API változás

Új vagy átnevezett **`eCore.*` publikus mező** = szerződés változás → `changelog.md` + `docs/PUBLIC_API_HU.md` + `fxmanifest` `version`.
