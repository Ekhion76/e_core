-- Extension point: `17mov_Hud` + `17_movement` client (`client.lua`) bind to this global.
-- Do not place generic weight / web / diagnostics overrides here
-- (use inventory override or `standalone/config/main.lua`).
HUD17 = GetResourceState('17mov_Hud') == 'started'
if HUD17 then
    -- example: Config.displayComponent.laborHud = true
end