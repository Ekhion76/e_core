--- Meta domain init (server): side effects only (event handlers / periodic save).

local meta = lib.require('src/runtime/meta/logic')
local db = lib.require('src/runtime/db/logic')

RegisterServerEvent('e_core:loadMeta', function()
    local playerId = source
    if not hf.isValidPlayerSource(playerId) then
        return
    end
    local cooldown = GetConvarInt('e_core:loadmeta_rate_ms', 2500)
    if cooldown < 500 then
        cooldown = 500
    end
    if not hf.netRateLimit(playerId, 'e_core:loadMeta', cooldown) then
        return
    end
    local xPlayer = eCore:getPlayer(playerId)
    if not xPlayer then
        return
    end
    db.loadMeta(xPlayer)
end)

--- Server-side bridge events only (TriggerEvent). Do not expose as RegisterServerEvent,
--- otherwise clients could inject forged xPlayer payloads.
AddEventHandler('e_core:playerLoaded', function(xPlayer)
    if not xPlayer or not xPlayer.source then
        return
    end
    db.loadMeta(xPlayer)
end)

AddEventHandler('e_core:playerUnload', function(playerId)
    meta.saveRequest(playerId, 'unload')
end)

AddEventHandler('playerDropped', function()
    local playerId = source
    meta.saveRequest(playerId, 'dropped')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        db.saveAllMeta()
    end
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(50000)
            db.saveAllMeta()
        end)
    end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    db.saveAllMeta()
end)

--- Periodic save loop (10-minute interval).
--- @return nil
local function scheduledSave()
    SetTimeout(60000 * 10, function()
        db.saveAllMeta()
        scheduledSave()
    end)
end

scheduledSave()
