--- Rendszer be van-e kapcsolva a labor modul.
--- @return boolean|nil ok true ha mehet
--- @return string|nil err eCoreErr érték, ha kikapcsolva
local function laborRequireSystem()
    if not Config.systemMode.labor then
        return nil, eCoreErr.the_system_is_turned_off
    end
    return true, nil
end

--- @return table|nil row ECO.meta[playerId]
--- @return string|nil err ha nincs meta / labor
local function laborPlayerRow(playerId)
    if not tonumber(playerId) or not ECO.meta[playerId] or not ECO.meta[playerId].labor then
        return nil, eCoreErr.not_found_metadata
    end
    return ECO.meta[playerId], nil
end

--- @param playerId number (source)
--- @return boolean ok siker: `true`, hiba: `false`
--- @return number|string second siker: labor pont (0 is lehet); hiba: `eCoreErr` string
function getLabor(playerId)
    local ok, err = laborRequireSystem()
    if not ok then
        return false, err
    end

    local row, err2 = laborPlayerRow(playerId)
    if not row then
        return false, err2
    end
    return true, row.labor.val
end

--- @param playerId number (source)
--- @param amount number of labor points
--- @return boolean success and, in case of an error, the reason as well
function setLabor(playerId, amount)
    amount = tonumber(amount)

    local ok, err = laborRequireSystem()
    if not ok then
        return false, err
    end

    local row, err2 = laborPlayerRow(playerId)
    if not row then
        return false, err2
    end

    if amount == nil or amount < 0 or amount ~= amount then
        return false, eCoreErr.not_valid_amount
    end

    row.labor.val = hf.rangeLimit(amount, Config.laborLimit)
    row.labor.time = os.time()

    syncRequest(playerId)
    return true
end

--- @param playerId number (source)
--- @param amount number of labor points to be removed
--- @return boolean success and, in case of an error, the reason as well
function removeLabor(playerId, amount)
    local ok, err = laborRequireSystem()
    if not ok then
        return false, err
    end

    local row, err2 = laborPlayerRow(playerId)
    if not row then
        return false, err2
    end

    amount = tonumber(amount)
    if amount == nil or amount <= 0 or amount ~= amount then
        return false, eCoreErr.not_valid_amount
    end

    if row.labor.val < amount then
        return false, eCoreErr.not_enough_labor
    end

    row.labor.val = hf.rangeLimit(row.labor.val - amount, Config.laborLimit)
    row.labor.time = os.time()

    syncRequest(playerId)
    return true
end

--- @param playerId number (source)
--- @param amount number of labor points to be added
--- @return boolean success and, in case of an error, the reason as well
function addLabor(playerId, amount)
    local ok, err = laborRequireSystem()
    if not ok then
        return false, err
    end

    local row, err2 = laborPlayerRow(playerId)
    if not row then
        return false, err2
    end

    amount = tonumber(amount)
    if amount == nil or amount <= 0 or amount ~= amount then
        return false, eCoreErr.not_valid_amount
    end

    if row.labor.val >= Config.laborLimit then
        return false, eCoreErr.has_already_reached_the_limit
    end

    row.labor.val = hf.rangeLimit(row.labor.val + amount, Config.laborLimit)
    row.labor.time = os.time()

    syncRequest(playerId)
    return true
end

-----------------------
--- AUTO LABOR INCREASE
-----------------------

--- Online játékosok, akiknek van betöltött meta + labor blokk (GetPlayers, nem teljes ECO.meta bejárás).
local function laborIncreaseCollectTargets()
    local ids = {}
    for _, sid in ipairs(GetPlayers()) do
        local playerId = tonumber(sid)
        if playerId and hf.isValidPlayerSource(playerId) then
            local meta = ECO.meta[playerId]
            if meta and meta.labor then
                ids[#ids + 1] = playerId
            end
        end
    end
    return ids
end

--- @param ids number[] játékos source lista
--- @param timeStamp number os.time a tickhez
--- @param fromIdx number első index az ids-ben (1-based)
--- @param chunkSize number <=0: mind egyben; >0: legfeljebb ennyi fő / hullám
--- @param onDone fun() következő periodikus `laborIncrease` ütemezése
local function laborIncreaseApplyChunks(ids, timeStamp, fromIdx, chunkSize, onDone)
    local n = #ids
    local limit = Config.laborLimit
    local step = Config.laborIncrease
    local endIdx = (chunkSize <= 0) and n or math.min(fromIdx + chunkSize - 1, n)

    for i = fromIdx, endIdx do
        local playerId = ids[i]
        local meta = ECO.meta[playerId]
        if meta and meta.labor then
            meta.labor.time = timeStamp
            if meta.labor.val < limit then
                meta.labor.val = hf.rangeLimit(meta.labor.val + step, limit)
                syncRequest(playerId)
            end
        end
    end

    if endIdx < n and chunkSize > 0 then
        SetTimeout(0, function()
            laborIncreaseApplyChunks(ids, timeStamp, endIdx + 1, chunkSize, onDone)
        end)
    else
        onDone()
    end
end

function laborIncrease()
    SetTimeout(Config.laborIncreaseTime * 60000, function()
        if not Config.systemMode.labor then
            laborIncrease()
            return
        end

        local timeStamp = os.time()
        local chunkSize = GetConvarInt('e_core:labor_tick_chunk', 0)
        if chunkSize < 0 then
            chunkSize = 0
        end

        local ids = laborIncreaseCollectTargets()
        if #ids == 0 then
            laborIncrease()
            return
        end

        laborIncreaseApplyChunks(ids, timeStamp, 1, chunkSize, laborIncrease)
    end)
end

if Config.systemMode.labor and
    tonumber(Config.laborIncreaseTime) and
    Config.laborIncreaseTime > 0 and

    tonumber(Config.laborIncrease) and
    Config.laborIncrease > 0 then
    laborIncrease()
end

-----------------
--- OFFLINE LABOR
-----------------
function addOfflineLabor(playerId)
    if not Config.systemMode.labor then
        return false
    end

    local row, err = laborPlayerRow(playerId)
    if not row then
        return false
    end

    local laborIncreaseOffline = tonumber(Config.laborIncreaseOffline)
    local laborIncreaseTime = tonumber(Config.laborIncreaseTime)

    if not laborIncreaseTime or laborIncreaseTime < 1 or
            not laborIncreaseOffline or laborIncreaseOffline < 1 then
        return false
    end

    local timeStamp = os.time()
    local increaseTime = laborIncreaseTime * 60
    local elapsedTime = timeStamp - row.labor.time

    if elapsedTime < increaseTime then
        return true
    end

    local multiplier = math.floor(elapsedTime / increaseTime)
    local offlineLabor = laborIncreaseOffline * multiplier

    row.labor.time = timeStamp
    row.labor.val = hf.rangeLimit(row.labor.val + offlineLabor, Config.laborLimit)
    return true
end
