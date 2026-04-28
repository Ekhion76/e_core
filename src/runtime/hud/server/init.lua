--- HUD domain init (server): side effects only (event registration).

local hud = lib.require('src/runtime/hud/server/logic')

RegisterServerEvent('e_core:hud:commit', function(payload)
    hud.commitLayout(source, payload)
end)
