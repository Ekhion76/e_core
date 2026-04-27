--- Optional client import for draggable HUD preview sync.
--- Needed only for HUD edit/drag flows (`e_core:hud:clientPreview` -> `ECORE_HUD_SYNC`).
RegisteredElements = RegisteredElements or {}

AddEventHandler('e_core:hud:clientPreview', function(id, pos)
    if type(id) ~= 'string' then
        return
    end
    if not RegisteredElements[id] then
        return
    end
    SendNUIMessage({
        action = 'ECORE_HUD_SYNC',
        id = id,
        pos = pos
    })
end)
