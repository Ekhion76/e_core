---
id: nui-typescript-interfaces
title: "TypeScript interface es tipus referencia"
sidebar_position: 4
---

# TypeScript interface es tipus referencia

Megjegyzes: a kodbazis tobbnyire `type` aliasokat hasznal `interface` helyett, de szerzodes-szempontbol ezek ugyanugy API-kontraktusok.

## NUI app payload tipusok (`src/web/src/NuiApp.svelte`)

| Tipus | Cel | Fo mezok |
|---|---|---|
| `InitPayload` | kezdeti Lua -> UI boot payload | `metadata`, `levels`, `locale`, `laborLimit`, `abilityLimit`, `displayComponent` |
| `PopupPayload` | szintlepes popup adat | `category`, `name`, `baseLevel?`, `newLevel` |

## Admin + diagnostics tipusok

### `src/web/src/lib/diagnostics.ts`

| Tipus | Leiras |
|---|---|
| `RunStatus` | diagnostics futas allapot (`queued/running/passed/failed/cancelled`) |
| `DocHint` | doksi ajanlas metadata (`docId`, `sectionKey`, `severity`, `confidence`, `docUrl`) |
| `DiagnosticsRun` | egy futas teljes modellje (steps, logs, resultDetails) |
| `DiagnosticsTest` | futtathato diagnostics teszt metadata |
| `DiagnosticsStep` | egy futas lepesallapota |
| `DiagnosticsLogEntry` | naplosor (`ts`, `level`, `message`) |
| `DiagnosticsResultDetail` | granularis eredmeny (`code`, `issueCount`, `passed`, `docHints`) |

### `src/web/src/lib/registry.ts`

| Tipus | Leiras |
|---|---|
| `ProfessionItem` | profession registry sor (`category`, `name`, `profileKey`, `enabled`, `maxProficiency`) |
| `LevelProfileItem` | level profile row (`profileKey`, `mode`, `levels`, `levelsData`, `linkedProfessions`) |
| `ProfessionDefaultsResult` | category default kulcsok |
| `ProfessionValidateResult` | valid/invalid/missingProfile kulcsvalidacio eredmeny |
| `ProfessionProfileResult` | profession -> profile feloldasi eredmeny |
| `ProfessionCreateInput` | profession letrehozas input |
| `ProfessionUpdateInput` | profession modositas input |
| `LevelProfileCreateInput` | level profile letrehozas input |
| `LevelProfileUpdateInput` | level profile modositas input |

## Egyeb UI-szerzodes tipusok

| Fajl | Tipus | Cel |
|---|---|---|
| `src/web/src/AdminConsole.svelte` | `TabId`, `Tab` | admin tab navigacios modell |
| `src/web/src/lib/IntegrityPanel.svelte` | `RowStatus`, `IntegrityStep` | inline integritas checklist allapot |
| `src/web/src/lib/levelPreview.ts` | `LevelEntry` | szintek vizualis elokeszitese |
| `src/web/src/lib/rankData.ts` | `LevelRow` | rank/level szamitas bemeneti sor |
| `src/web/src/lib/adminFormHelpers.ts` | `EasyGeneratorForm` | easy generator form szerzodes |
| `src/web/src/nui.d.ts` | `GetParentResourceName()` | FiveM NUI global deklaracio |

## Tervezoi megallapitas

- A tipusok jol szeparaljak a **NUI transport** (`InitPayload`, `DocHint`, API response type-ok) es a **domain model** (`ProfessionItem`, `DiagnosticsRun`) reteget.
- Ha kesobb kulso SDK-cel is hasznalnatok, erdemes ezeket egy `src/web/src/types/` gyujto mappaba emelni, hogy a Svelte komponensek csak importaljak a szerzodeseket, ne helyben definialjak.
