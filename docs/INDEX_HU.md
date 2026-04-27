# e_core – dokumentáció (belépési pont)

Egy fejlesztő / AI asszisztens számára elég innen kinavigálni. A cél: **ox_lib-szintű** későbbi felhasználói oldal építéséhez meglegyen a **szerződés** (API, hibák, stack, üzemeltetés); a belső „munkanapló” és lezárt sprint-tervek ki lettek vezetve.

## 1. Kötelező szerződés és referencia

| Fájl | Szerep |
|------|--------|
| [PUBLIC_API_HU.md](PUBLIC_API_HU.md) | `exports.e_core:*` + `eCore:` névsor, deprec szabály |
| [AI_SUPPORT_REFERENCE_HU.txt](AI_SUPPORT_REFERENCE_HU.txt) | Részletes magyar leírás: struktúra, exportok, GYIK |
| [export_examples_client.md](../export_examples_client.md) / [export_examples_server.md](../export_examples_server.md) | Másolható hívásminták (angol) |
| [changelog.md](../changelog.md) | Verziókövetés (újraindítva) |

## 2. Üzemeltetés és környezet

| Fájl | Szerep |
|------|--------|
| [SZERVER_OPERATOR_CHECKLIST_HU.md](SZERVER_OPERATOR_CHECKLIST_HU.md) | `ensure`, ConVar, indulási log, kockázatok |
| [FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md](FRAMEWORK_CONFIG_REFACTOR_TERVEZES_HU.md) | `e_core:framework`, két core eset |
| [FRAMEWORK_IDLE_GUARD_STRATEGY_HU.md](FRAMEWORK_IDLE_GUARD_STRATEGY_HU.md) | Framework detect hibaegyesítés, `idle` állapot, guard és ready-state stratégia |
| [SUPPORTED_STACK_MATRIX_HU.md](SUPPORTED_STACK_MATRIX_HU.md) | Tier / override / támogatott kombinációk |

## 3. Adat, migráció, hibakeresés

| Fájl | Szerep |
|------|--------|
| [DB_MIGRATIONS_HU.md](DB_MIGRATIONS_HU.md) | `e_core_migrations`, új migráció sablon |
| [ECORE_ERR_HIBA_NYOMON_HU.md](ECORE_ERR_HIBA_NYOMON_HU.md) | `eCoreErr` táblázat, tipikus okok, nyomozási sorrend |
| [NET_EVENTS_AUDIT_HU.md](NET_EVENTS_AUDIT_HU.md) | Saját net / callback felület |

## 4. Domain és architektúra (mélyebb)

| Fájl | Szerep |
|------|--------|
| [LABOR_KEZELES_MUNKAFIL_HU.md](LABOR_KEZELES_MUNKAFIL_HU.md) | Labor + meta szinkron részletek |
| [PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md](PROFESSION_REGISTRY_ES_META_CLEANUP_TERV_HU.md) | Profession registry határ: e_core = source of truth |

## 5. Fejlesztői minőség (DX)

| Fájl | Szerep |
|------|--------|
| [PROJECT_STRUCTURE.txt](PROJECT_STRUCTURE.txt) | Mappák, `fxmanifest` emlékeztető |
| [LUA_ANNOTATION_STYLE_EN.md](LUA_ANNOTATION_STYLE_EN.md) | LuaLS annotáció szabvány |
| [LUA_ANNOTATION_MAINTENANCE_EN.md](LUA_ANNOTATION_MAINTENANCE_EN.md) | Annotáció policy |
| [LUA_LS_AND_CI_HU.md](LUA_LS_AND_CI_HU.md) | LuaLS, luacheck, CI |

## 6. Későbbi publikus dokumentáció (web)

A `tech_docs/` mappa szándéka: **Docusaurus** (vagy hasonló) – ox_lib-stílusú kereshető oldal. Jelenleg csak [../tech_docs/README.md](../tech_docs/README.md); a tartalom a fenti `docs/` szerződésre épülhet.

## Cursor / AI

A rövid szabályok: `.cursor/rules/e_core-context.mdc` és `.cursor/rules/e_core-ai-collaboration.mdc`.
