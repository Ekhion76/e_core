RegisterServerEvent('e_core:loadMeta', function()
    local playerId = source
    loadMeta(eCore:getPlayer(playerId))
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
--- @param defaultValue table key = default value pairs, eg.: {cooking = 0, weaponry = 0}
--- @return boolean success
function registerMeta(playerId, category, defaultValue)
    if not tonumber(playerId) or not ECO.meta[playerId] then
        return false, 'not_found_metadata'
    end

    if type(category) ~= 'string' then
        return false, 'no_valid_meta_name'
    end

    if ECO.meta[playerId][category] then
        if hf.isPopulatedTable(defaultValue) then
            ECO.meta[playerId][category] = ECO.meta[playerId][category] or {}

            if hf.isTable(ECO.meta[playerId][category]) then
                for key, value in pairs(defaultValue) do
                    if type(key) == 'string' then
                        if not ECO.meta[playerId][category][key] then
                            ECO.meta[playerId][category][key] = value
                            syncRequest(playerId)
                        end
                    end
                end
            end

        end
    else
        ECO.meta[playerId][category] = defaultValue
        syncRequest(playerId)
    end

    return true
end

--- @param playerId number (source)
--- @param category string eg.: crafting, reputation, harvesting, special, ...
--- @param name string eg.: weaponry
--- @return boolean success and, in case of an error, the reason as well
function getAbility(playerId, category, name)
    if not checkMetaExists(playerId, category, name) then
        return false, 'not_found_metadata'
    end

    return ECO.meta[playerId][category][name]
end

--- @param playerId number (source)
--- @param category string eg.: crafting, reputation, harvesting, special, ...
--- @param name string eg.: weaponry
--- @param value
--- @return boolean success and, in case of an error, the reason as well
function addAbility(playerId, category, name, value)
    if not checkMetaExists(playerId, category, name) then
        return false, 'not_found_metadata'
    end

    local metaValue = ECO.meta[playerId][category][name]
    local baseValue = metaValue

    if metaValue >= Config.abilityLimit then
        return false, 'has_already_reached_the_limit'
    end

    if tonumber(value) then
        metaValue = metaValue + value
    end

    local newValue = hf.rangeLimit(metaValue, Config.abilityLimit)

    if baseValue ~= newValue then
        ECO.meta[playerId][category][name] = newValue
        messageIfLevelChange(playerId, category, name, baseValue, newValue)
        syncRequest(playerId)
    end

    return true
end

--- @param playerId number (source)
--- @param category string eg.: crafting, reputation, harvesting, special, ...
--- @param name string eg.: weaponry
--- @param value
--- @return boolean success and, in case of an error, the reason as well
function removeAbility(playerId, category, name, value)
    if not checkMetaExists(playerId, category, name) then
        return false, 'not_found_metadata'
    end

    local metaValue = ECO.meta[playerId][category][name]
    local baseValue = metaValue

    if tonumber(value) then
        metaValue = metaValue - value
    end

    local newValue = hf.rangeLimit(metaValue, Config.abilityLimit)

    if baseValue ~= newValue then
        ECO.meta[playerId][category][name] = newValue
        messageIfLevelChange(playerId, category, name, baseValue, newValue)
        syncRequest(playerId)
    end

    return true
end

--- @param playerId number (source)
--- @param category string eg.: crafting, reputation, harvesting, special, ...
--- @param name string eg.: weaponry
--- @param value
--- @return boolean success and, in case of an error, the reason as well
function setAbility(playerId, category, name, value)
    if not checkMetaExists(playerId, category, name) then
        return false, 'not_found_metadata'
    end

    local metaValue = ECO.meta[playerId][category][name]
    local baseValue = metaValue
    local newValue = value

    if tonumber(value) then
        newValue = hf.rangeLimit(value, Config.abilityLimit)
    end

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

function prepareMeta(playerId, meta)
    if type(meta) ~= 'table' then
        meta = {}
    end

    ECO.meta[playerId] = meta
    ECO.meta[playerId]['login'] = os.time()
    ECO.meta[playerId]['logout'] = meta['logout'] or 0
    ECO.meta[playerId]['labor'] = meta['labor'] or { val = Config.defaultLabor, time = os.time() }

    local val = ECO.meta[playerId]['labor'].val
    ECO.meta[playerId]['labor'].val = (tonumber(val) and val == val) and tonumber(val) or 0

    if hf.isPopulatedTable(Config.metaFields) then
        for metaCategory, defaultValue in pairs(Config.metaFields) do
            ECO.meta[playerId][metaCategory] = ECO.meta[playerId][metaCategory] or defaultValue
        end
    end
end

---
--- SAVE AND LOAD EVENTS
---
RegisterServerEvent('e_core:playerLoaded', function(xPlayer)
    loadMeta(xPlayer)
end)

function saveRequest(playerId, event)
    local xPlayer = eCore:getPlayer(playerId)

    if xPlayer and ECO.meta[playerId] then
        local time = os.time()

        if time - ECO.lastSave[playerId] > 1 then
            ECO.meta[playerId]['logout'], ECO.lastSave[playerId] = time, time
            saveMeta(xPlayer, true)
            cLog(xPlayer.name .. ' ' .. event, 'saving metadata...', 1)
        end
    end
end

AddEventHandler('e_core:playerUnload', function(playerId)
    saveRequest(playerId, 'unload')
end)

AddEventHandler('playerDropped', function()
    local playerId = source
    saveRequest(playerId, 'dropped')
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