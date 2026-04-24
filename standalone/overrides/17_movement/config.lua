-- Bővítési pont: `17mov_Hud` + `17_movement` kliens (`client.lua`) ehhez a globális névhez köt.
-- Általános súly / web / diagnostics felülírások ne ide kerüljenek (inventory override vagy `standalone/config/main.lua`).
HUD17 = GetResourceState('17mov_Hud') == 'started'
if HUD17 then
    -- példa: Config.displayComponent.laborHud = true
end