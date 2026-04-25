# e_core projekt attekintes

Ez a dokumentum roviden osszefoglalja az `e_core` felepiteset: FiveM Lua backend + Svelte/TypeScript NUI frontend.

## Technologiai alapok

- **Backend/runtime:** FiveM (Lua 5.4), framework bridge reteggel (`ESX`, `QB`), `ox_lib` es `oxmysql` fuggosegekkel.
- **Frontend (NUI):** Svelte + TypeScript alapu web UI a `src/web/dist` mappaban, amit az `fxmanifest.lua` a `ui_page` beallitassal tolt be.
- **Integracios modell:** Exportokon keresztuli API (`src/client/exports.lua`, `src/server/exports.lua`), plusz `src/imports/core.lua` belepesi minta mas resource-oknak.

## Fobb mappak szerepe

- `src/bridge/`: framework-specifikus (ESX/QB) es globalis osszekoto logika.
- `src/server/`: szerver oldali domain logika (pl. labor, meta, adatbazis, exportok).
- `src/client/`: kliens oldali inicializalas, NUI-hidak, exportok.
- `src/standalone/`: frameworktol fuggetlen configok + usableitem.
- `overrides/`: stack-fuggo inventory/progress/core felulirasok.
- `src/libs/`: kozos helper modulok es utilityk.
- `src/imports/`: mas resource-bol include-olhato segedfajlok.
- `src/locales/`: nyelvi fajlok.
- `html/`: NUI statikus/all-in UI eroforrasok, beleertve a `web` frontend buildet.
- `docs/`: projekt dokumentacio, API/uzemeltetesi/modernizacios anyagok.

## Betoltesi es futasi kep

1. `fxmanifest.lua` deklaralja a shared/client/server script sorrendet.
2. A `src/bridge` retegek kivalsztjak es egysegesitik az aktiv framework viselkedeset.
3. Az `overrides/` felulirja vagy kiegesziti a stack-fuggo integraciokat.
4. A `src/server` + `src/client` modulok biztositjak az e_core fo szolgaltatasait.
5. A NUI frontend (`src/web/dist`) a kliens oldali bridge-eken keresztul kommunikal a Lua reteggel.

## Gyors orientacio uj fejlesztoknek

- Framework valtas vagy stack-fuggo tema: eloszor `src/bridge/` + `overrides/`.
- Publikus API valtozas: `src/client/exports.lua`, `src/server/exports.lua`, majd doksi frissites (`docs/`, `export_examples_*`, `changelog.md`).
- UI/NUI munka: `src/web/dist` (Svelte/TS forras/build), illetve a hozza tartozo kliens oldali NUI bridge fajlok.
