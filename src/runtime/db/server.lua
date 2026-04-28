local UPDATE_META = 'UPDATE `users` SET `e_core` = ? WHERE `identifier` = ?'
local SELECT_META = 'SELECT `e_core` FROM `users` WHERE `identifier` = ?'
local hfe = hfe

if QB_CORE then
    UPDATE_META = 'UPDATE `players` SET `e_core` = ? WHERE `citizenid` = ?'
    SELECT_META = 'SELECT `e_core` FROM `players` WHERE `citizenid` = ?'
end

MySQL.ready(function()
    e_core_run_db_migrations()
    e_core_bootstrap_profession_registry()
    if type(e_core_bootstrap_cleanup_jobs) == 'function' then
        e_core_bootstrap_cleanup_jobs()
    end
    if type(e_core_schedule_admin_denied_audit_purge) == 'function' then
        e_core_schedule_admin_denied_audit_purge()
    end
end)

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @param dropMeta any
--- @return any result
function saveMeta(xPlayer, dropMeta)
    local playerId = xPlayer.source
    local row = PlayerMetaStore.get(playerId)

    if row then
        local ok = hfe.mysqlAwait(('saveMeta:%s'):format(xPlayer.identifier), function()
            MySQL.update.await(UPDATE_META, {
                json.encode(row),
                xPlayer.identifier,
            })
        end)
        if not ok then
            cLog(('[e_core] saveMeta: DB hiba, meta nem mentve (%s)'):format(xPlayer.identifier), 'warning', 2)
            return
        end
        if dropMeta then
            PlayerMetaStore.clear(playerId)
        end
        cLog(xPlayer.name .. ' metadata', 'saved', 1)
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function saveAllMeta()
    local parameters = {}

    for playerId, meta in PlayerMetaStore.eachLoaded() do
        local xPlayer = eCore:getPlayer(playerId)

        if xPlayer then
            parameters[#parameters + 1] = { json.encode(meta), xPlayer.identifier }
        end
    end

    if #parameters > 0 then
        local ok = hfe.mysqlAwait('saveAllMeta:prepare', function()
            MySQL.prepare.await(UPDATE_META, parameters)
        end)
        if ok then
            cLog('all metadata', 'saved', 1)
        else
            cLog('[e_core] saveAllMeta: DB hiba, kötegelt mentés sikertelen', 'warning', 2)
        end
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param xPlayer table
--- @return any result
function loadMeta(xPlayer)
    local playerId = xPlayer.source

    local ok, result = hfe.mysqlAwait(('loadMeta:%s'):format(xPlayer.identifier), function()
        return MySQL.scalar.await(SELECT_META, { xPlayer.identifier })
    end)
    if not ok then
        cLog(('[e_core] loadMeta: DB hiba, meta nem töltődött (%s)'):format(xPlayer.identifier), 'warning', 2)
        return
    end

    local meta = {}
    if result ~= nil and result ~= '' then
        local decodeOk, decoded = pcall(json.decode, result)
        if not decodeOk or type(decoded) ~= 'table' then
            cLog(
                ('[e_core] loadMeta: az e_core oszlop nem érvényes JSON objektum (%s); meta nem állítódik be (DB javítás, különben mentéskor felülírás veszélye)'):format(
                    xPlayer.identifier
                ),
                'error',
                1
            )
            return
        end
        meta = decoded
    end

    prepareMeta(playerId, meta)
    addOfflineLabor(playerId)
    PlayerMetaStore.setLastSave(playerId, os.time())

    PlayerMetaStore.pushFullSync(playerId)
end
