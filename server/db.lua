local UPDATE_META = 'UPDATE `users` SET `e_core` = ? WHERE `identifier` = ?'
local SELECT_META = 'SELECT `e_core` FROM `users` WHERE `identifier` = ?'

if QB_CORE then
    UPDATE_META = 'UPDATE `players` SET `e_core` = ? WHERE `citizenid` = ?'
    SELECT_META = 'SELECT `e_core` FROM `players` WHERE `citizenid` = ?'
end

MySQL.ready(function()
    e_core_run_db_migrations()
end)

function saveMeta(xPlayer, dropMeta)
    local playerId = xPlayer.source

    if ECO.meta[playerId] then
        local ok = hf.mysqlAwait(('saveMeta:%s'):format(xPlayer.identifier), function()
            MySQL.update.await(UPDATE_META, {
                json.encode(ECO.meta[playerId]),
                xPlayer.identifier,
            })
        end)
        if not ok then
            return
        end
        if dropMeta then
            ECO.meta[playerId] = nil
        end
        cLog(xPlayer.name .. ' metadata', 'saved', 1)
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
        local ok = hf.mysqlAwait('saveAllMeta:prepare', function()
            MySQL.prepare.await(UPDATE_META, parameters)
        end)
        if ok then
            cLog('all metadata', 'saved', 1)
        end
    end
end

function loadMeta(xPlayer)
    local playerId = xPlayer.source

    local ok, result = hf.mysqlAwait(('loadMeta:%s'):format(xPlayer.identifier), function()
        return MySQL.scalar.await(SELECT_META, { xPlayer.identifier })
    end)
    if not ok then
        return
    end

    local meta = result and json.decode(result) or {}

    prepareMeta(playerId, meta)
    addOfflineLabor(playerId)
    ECO.lastSave[playerId] = os.time()

    TriggerClientEvent('e_core:sync', playerId, ECO.meta[playerId])
end