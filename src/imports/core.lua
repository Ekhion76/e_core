-- luacheck: push ignore 131
FRAMEWORK = exports.e_core:getFrameWork()
eCore = exports.e_core:getCore()
eCoreConfig = exports.e_core:getConfig()
-- luacheck: pop

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