# SRC migracios smoke checklist

Cel: gyors validacio az `src/` + `overrides/` mappastrukturara atallas utan.

## 1) Resource startup

- [ ] `ensure e_core` utan nincs Lua load error a szerver konzolban.
- [ ] Az indulo osszegzo sor megjelenik (framework + inventory + items status).
- [ ] `exports.e_core:getCore()` es `exports.e_core:getFrameWork()` hivasok mukodnek.

## 2) Framework branch

- [ ] ESX stacknel az ESX ag aktiv (`src/bridge/esx/*`).
- [ ] QB stacknel a QB ag aktiv (`src/bridge/qb/*`).
- [ ] Dual-core tiltasi viselkedes valtozatlan (`e_core:framework` policy).

## 3) Override betoltes

- [ ] Az override configok az uj gyokerrol toltodnek (`overrides/**/config.lua`).
- [ ] A kliens/szerver override script globok lefutnak (`overrides/**/client.lua`, `overrides/**/server.lua`).
- [ ] Inventory/progress stack szerint a vart override van aktivan.

## 4) NUI + admin

- [ ] `ecore_admin` megnyithato jogosultsaggal.
- [ ] NUI callbackok rendben futnak (`eCoreAdminApi`, `eCoreDiagnosticsApi`).
- [ ] `webAdminExit` es `exit` callbackok helyesen zarjak a fokuszt.

## 5) Integrity / diagnostics

- [ ] Integrity full run sikeresen indul.
- [ ] Checklist status es log frissul a NUI-ban.
- [ ] Progress teszt eredmeny visszajon (`onFinish` / `onCancel` utvonal).

## 6) Meta sync

- [ ] `e_core:sync` update utan a HUD/page metadata frissul.
- [ ] `e_core:levelChange` popup tovabbra is megerkezik.

## 7) Manifest path sanity

- [ ] `fxmanifest.lua` minden belso pathja `src/...` vagy `overrides/...` szerkezetu.
- [ ] Nincs mar hivatkozas a regi top-level `bridge/`, `client/`, `server/`, `imports/`, `libs/`, `locales/`, `standalone/overrides/` gyokerekre.
