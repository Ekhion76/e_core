# Lua Annotation Backlog (e_core)

Audit date: 2026-04-25

## Coverage snapshot

- Files with functions: 47
- Total functions: 451
- Missing annotation blocks: 337

## Highest-priority gaps (missing/total)

- `server/professions.lua`: 61/71
- `bridge/global/client.lua`: 24/24
- `libs/helper.lua`: 21/25
- `imports/discordlog.lua`: 18/28
- `imports/utils.lua`: 7/7
- `server/exports.lua`: audit in Phase A (public contract gate)
- `client/exports.lua`: audit in Phase A (public contract gate)
- `bridge/main.lua`: audit in Phase A (public contract gate)

## Phase mapping

## Phase A (public contract)

- `server/exports.lua`
- `client/exports.lua`
- `bridge/main.lua`
- `imports/discordlog.lua`
- `imports/utils.lua`

## Phase B (bridge + domain core)

- `bridge/global/shared.lua`
- `bridge/global/server.lua`
- `bridge/esx/server.lua`
- `bridge/qb/server.lua`
- `server/meta.lua`
- `server/labor.lua`
- `server/db.lua`
- `server/professions.lua`

## Phase C (overrides + NUI/admin bridges)

- `standalone/overrides/**/**/*.lua`
- `client/nui_admin_bridge.lua`
- `client/nui_diagnostics_bridge.lua`
- `server/nui_admin_bridge.lua`
- `server/nui_diagnostics_bridge.lua`

## Notes

- `types/fivem_ox_stubs.lua` is intentionally low-value for full semantic docs and is excluded from public-contract strictness; keep only minimal signatures.
- All annotation wording must follow `docs/LUA_ANNOTATION_STYLE_EN.md`.
