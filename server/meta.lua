RegisterServerEvent('e_core:loadMeta', function()

    loadMeta(eCore:getPlayer(source))
end)

--- @param playerId number (source)
--- @param meta string eg.: crafting, reputation, harvesting, special, ...
--- @param value table key = value pairs, eg.: {cooking = 4020, weaponry = 200}
--- @return boolean success and, in case of an error, the reason as well
function setMeta(playerId, meta, value)

    if not tonumber(playerId) or not ECO.meta[playerId] then

        return false, 'not_found_metadata'
    end

    if type(meta) ~= 'string' then

        return false, 'no_valid_meta_name'
    end

    ECO.meta[playerId][meta] = value
    syncRequest(playerId)

    return true
end

--- @param playerId number (source)
--- @param meta string eg.: crafting, reputation, harvesting, special, ...
--- @return boolean|table success or values
function getMeta(playerId, meta)

    if not tonumber(playerId) or not ECO.meta[playerId] then

        return false, 'not_found_metadata'
    end

    if meta then

        if type(meta) == 'string' then

            return ECO.meta[playerId][meta]
        else

            return false, 'no_valid_meta_name'
        end
    end

    return ECO.meta[playerId]
end

--- Register metadata if not exists
--- @param playerId number source
--- @param category string eg.: crafting, reputation, harvesting, special, ...
--- @param values table key = default value pairs, eg.: {cooking = 0, weaponry = 0}
--- @return boolean success
function registerMeta(playerId, category, values)

    if not tonumber(playerId) or not ECO.meta[playerId] then

        return false, 'not_found_metadata'
    end

    if type(category) ~= 'string' then

        return false, 'no_valid_meta_name'
    end

    if type(values) ~= 'table' or not next(values) then

        return false, 'no_valid_data'
    end

    ECO.meta[playerId][category] = ECO.meta[playerId][category] or {}

    for key, value in pairs(values) do

        if type(key) == 'string' then

            ECO.meta[playerId][category][key] = ECO.meta[playerId][category][key] or value
        end
    end

    return true
end

--- @param playerId number (source)
--- @param operation string (add | remove | get | set)
--- @param category string eg.: crafting, reputation, harvesting, special, ...
--- @param name string eg.: weaponry
--- @param value
--- @return boolean success and, in case of an error, the reason as well
function ability(playerId, operation, category, name, value)

    if not checkMetaExists(playerId, category, name) then

        return false, 'not_found_metadata'
    end

    local metaValue = ECO.meta[playerId][category][name]
    local baseValue = metaValue

    if operation == 'get' then

        return metaValue

    elseif operation == 'add' and tonumber(value) then

        if metaValue >= Config.abilityLimit then

            return false, 'has_already_reached_the_limit'
        end

        metaValue = metaValue + value

    elseif operation == 'remove' and tonumber(value) then

        metaValue = metaValue - value

    elseif operation == 'set' then

        metaValue = value
    else

        return false, 'no_operation'
    end

    local newValue = settingLimits(metaValue, Config.abilityLimit)

    if baseValue ~= newValue then

        ECO.meta[playerId][category][name] = newValue
        messageIfLevelChange(playerId, category, name, baseValue, newValue)
        syncRequest(playerId)
    end

    return true
end

function syncRequest(playerId)

    ECO.idsToSync[playerId] = true

    if not ECO.syncRequested then

        ECO.syncRequested = true

        SetTimeout(0, function()

            for id in pairs(ECO.idsToSync) do

                TriggerClientEvent('e_core:sync', id, ECO.meta[id])
            end

            ECO.idsToSync = {}
            ECO.syncRequested = false
        end)
    end
end

---
--- SAVE AND LOAD EVENTS
---

RegisterServerEvent('e_core:playerLoaded', function(xPlayer)

    loadMeta(xPlayer)
end)

AddEventHandler('e_core:playerUnload', function(playerId)

    local xPlayer = eCore:getPlayer(playerId)

    if xPlayer and ECO.meta[playerId] then

        ECO.meta[playerId]['logout'] = os.time()
        saveMeta(xPlayer, true)
    end
end)

AddEventHandler('onResourceStop', function(resource)

    if resource == GetCurrentResourceName() then

        saveAllMeta()
    end
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)

    if eventData.secondsRemaining == 60 then

        CreateThread(function()
            Wait(50000)
            saveAllMeta()
        end)
    end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()

    saveAllMeta()
end)

local function scheduledSave()

    SetTimeout(60000 * 10, function()

        saveAllMeta()
        scheduledSave()
    end)
end

scheduledSave()


