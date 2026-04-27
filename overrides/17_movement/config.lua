-- Extension point: `17mov_Hud` + `17_movement` client (`client.lua`) bind to this global.
-- Do not place generic weight / web / diagnostics overrides here
-- (use inventory override or `standalone/config/main.lua`).
HUD17 = GetResourceState('17mov_Hud') == 'started'
if not HUD17 then return end

--- Extension placeholder: optional `Config.*` tweaks when HUD17 is active (see `client.lua`).
local _ = HUD17
