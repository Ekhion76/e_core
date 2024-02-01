local CREATE_META = 'ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `e_core` LONGTEXT NULL DEFAULT NULL'
local UPDATE_META = 'UPDATE `users` SET `e_core` = ? WHERE `identifier` = ?'
local SELECT_META = 'SELECT `e_core` FROM `users` WHERE `identifier` = ?'

if QB_CORE then
    CREATE_META = 'ALTER TABLE `players` ADD COLUMN IF NOT EXISTS `e_core` LONGTEXT NULL DEFAULT NULL'
    UPDATE_META = 'UPDATE `players` SET `e_core` = ? WHERE `citizenid` = ?'
    SELECT_META = 'SELECT `e_core` FROM `players` WHERE `citizenid` = ?'
end

MySQL.ready(function()
    MySQL.query.await(CREATE_META)
end)

function saveMeta(xPlayer, dropMeta)
    local playerId = xPlayer.source

    if ECO.meta[playerId] then
        MySQL.update(UPDATE_META, {
            json.encode(ECO.meta[playerId]),
            xPlayer.identifier
        }, function()
            if dropMeta then
                ECO.meta[playerId] = nil
            end
            cLog(xPlayer.name .. ' metadata', 'saved', 1)
        end)
    end
end

function saveAllMeta()
    local parameters = {}

    for playerId, meta in pairs(ECO.meta) do
        local xPlayer = eCore:getPlayer(playerId)

        if xPlayer then
            parameters[#parameters + 1] = { json.encode(meta), xPlayer.identifier }
        end
    end

    if #parameters > 0 then
        MySQL.prepare(UPDATE_META, parameters)
        cLog('all metadata', 'saved', 1)
    end
end

function loadMeta(xPlayer)
    local playerId = xPlayer.source

    MySQL.scalar(SELECT_META, { xPlayer.identifier }, function(result)
        local meta = result and json.decode(result) or {}

        prepareMeta(playerId, meta)
        addOfflineLabor(playerId)
        ECO.lastSave[playerId] = os.time()

        TriggerClientEvent('e_core:sync', playerId, ECO.meta[playerId])
    end)
end