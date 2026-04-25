---
id: nui-stores-architecture
title: "Svelte store felepites"
sidebar_position: 2
---

# Svelte store felepites

## Architekturalis minta

A kodbazis nem a klasszikus `svelte/store` (`writable`, `derived`) API-t hasznalja, hanem Svelte 5 rune-alapu komponens allapotot:

- `$state(...)`: lokalis reaktiv allapot
- `$derived(...)`: szarmaztatott allapot
- `$effect(...)`: side-effect es figyelo logika

Ez gyakorlatban komponens-szintu store rendszert jelent, globalis singleton store nelkul.

## Fo allapot-kontrollerek

## `NuiApp.svelte`

- **Core UI state:** `pageOpen`, `hudOpen`, `adminOpen`, `selectedCategory`, `popup`
- **Domain state:** `metadata`, `levels`, `locale`, `laborLimit`, `displayComponent`
- **Derived:** `categories` (megjelenitheto stat kategoriak)

## `AdminConsole.svelte`

- **Navigation state:** `activeTab`, `activeTabLabel`
- **Diagnostics state:** `diagnosticsRuns`, `diagnosticsTests`, `selectedTests`, `selectedRunId`, `selectedRun`
- **Async flags:** `diagnosticsLoading`, `testsLoading`, `isRunningSelected`, `isCancelling`
- **Error state:** `diagnosticsError`

## `lib/IntegrityPanel.svelte`

- **Form state:** `testItem`, `testItemAmount`, `cooldownMs`, `tryAddRemove`, `progressDurationMs`, `printToConsole`, `uiStepMs`
- **Run state:** `fullRunBusy`, `rowBusy`, `rowStatus`
- **Log state:** `liveHint`, `logLines`, `progressLogLines`
- **Derived:** `displaySteps` (dinamikus checklist megjelenites)

## Kapcsolodo panelek

A `ProfessionsPanel.svelte`, `LevelProfilesPanel.svelte`, `LevelPreview.svelte` szinten rune-alapu allapotot hasznal, foleg lista-szures/szamlalo jellegu `$derived` mintakkal.

## Megjegyzes fejleszteshez

- A jelenlegi minta gyors es egyszeru NUI komponensekhez.
- Ha kesobb kereszt-komponens, tartosabb state kell (pl. cache + central event bus), erdemes egy dedikalt app-store reteget bevezetni (modul-szintu wrapperrel), de a jelenlegi kod ezt meg nem igenyli.
