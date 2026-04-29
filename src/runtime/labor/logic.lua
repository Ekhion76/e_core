--- Labor domain (server): pure module API (no event/thread registration).
--- Side effects (timers) must live in `init.lua`.

local M = {}
local meta = lib.require('src/runtime/meta/logic')
local hf = lib.require('src/imports/sdk/helper_base/shared')
local quoteApi = nil

--- Lazily resolves quote API to avoid load-time circular require.
--- @return table
local function quote()
    if not quoteApi then
        quoteApi = lib.require('src/runtime/quote/logic')
    end
    return quoteApi
end

--- Checks whether labor subsystem is enabled.
--- @return boolean ok True when labor operations are allowed.
--- @return string|nil err eCoreErr value when system is disabled.
local function requireLaborEnabled()
    if not Config.systemMode.labor then
        return false, eCoreErr.feature_disabled
    end
    return true, nil
end

--- Resolves player meta row that contains the labor block.
--- @param playerId number Player source id.
--- @return table|nil row PlayerMetaStore row for `playerId`.
--- @return string|nil err eCoreErr when metadata/labor is missing.
local function playerRow(playerId)
    local row = tonumber(playerId) and PlayerMetaStore.get(playerId) or nil
    if not row or not row.labor then
        return nil, eCoreErr.not_found_metadata
    end
    return row, nil
end

--- @param playerId number (source)
--- @return boolean ok Success flag.
--- @return number|string second Labor points on success (can be 0); eCoreErr string on failure.
function M.getLabor(playerId)
    local ok, err = requireLaborEnabled()
    if not ok then
        return false, err
    end

    local row, err2 = playerRow(playerId)
    if not row then
        return false, err2
    end
    return true, row.labor.val
end

--- @param playerId number (source)
--- @param amount number of labor points
--- @return boolean ok Success flag.
--- @return string|nil err eCoreErr on failure.
function M.setLabor(playerId, amount)
    amount = tonumber(amount)

    local ok, err = requireLaborEnabled()
    if not ok then
        return false, err
    end

    local row, err2 = playerRow(playerId)
    if not row then
        return false, err2
    end

    if amount == nil or amount < 0 or amount ~= amount then
        return false, eCoreErr.not_valid_amount
    end

    row.labor.val = hf.clamp(amount, Config.laborLimit)
    row.labor.time = os.time()
    quote().invalidateLaborQuoteCache(playerId)

    meta.syncRequest(playerId)
    return true
end

--- @param playerId number (source)
--- @param amount number of labor points to be removed
--- @return boolean ok Success flag.
--- @return string|nil err eCoreErr on failure.
function M.removeLabor(playerId, amount)
    local ok, err = requireLaborEnabled()
    if not ok then
        return false, err
    end

    local row, err2 = playerRow(playerId)
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

    row.labor.val = hf.clamp(row.labor.val - amount, Config.laborLimit)
    row.labor.time = os.time()
    quote().invalidateLaborQuoteCache(playerId)

    meta.syncRequest(playerId)
    return true
end

--- @param playerId number (source)
--- @param amount number of labor points to be added
--- @return boolean ok Success flag.
--- @return string|nil err eCoreErr on failure.
function M.addLabor(playerId, amount)
    local ok, err = requireLaborEnabled()
    if not ok then
        return false, err
    end

    local row, err2 = playerRow(playerId)
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

    row.labor.val = hf.clamp(row.labor.val + amount, Config.laborLimit)
    row.labor.time = os.time()
    quote().invalidateLaborQuoteCache(playerId)

    meta.syncRequest(playerId)
    return true
end

--- Collects online player ids that currently have loaded `meta.labor`.
--- Uses `GetPlayers()` to avoid scanning all in-memory meta rows.
--- @return number[] ids
function M.collectOnlineTargets()
    local ids = {}
    for _, sid in ipairs(GetPlayers()) do
        local playerId = tonumber(sid)
        if playerId and hf.isValidPlayerSource(playerId) then
            local meta = PlayerMetaStore.get(playerId)
            if meta and meta.labor then
                ids[#ids + 1] = playerId
            end
        end
    end
    return ids
end

--- Applies one labor increase tick in chunks and schedules follow-up chunks if needed.
--- @param ids number[] Player source id list.
--- @param timeStamp number Tick timestamp (`os.time()`).
--- @param fromIdx number First index inside ids (1-based).
--- @param chunkSize number <=0 means all at once; >0 means max players per chunk.
--- @param onDone fun() Callback that schedules next periodic cycle (provided by init).
function M.applyIncreaseChunks(ids, timeStamp, fromIdx, chunkSize, onDone)
    local n = #ids
    local limit = Config.laborLimit
    local step = Config.laborIncrease
    local endIdx = (chunkSize <= 0) and n or math.min(fromIdx + chunkSize - 1, n)

    for i = fromIdx, endIdx do
        local playerId = ids[i]
        local meta = PlayerMetaStore.get(playerId)
        if meta and meta.labor then
            meta.labor.time = timeStamp
            if meta.labor.val < limit then
                meta.labor.val = hf.clamp(meta.labor.val + step, limit)
                quote().invalidateLaborQuoteCache(playerId)
                meta.syncRequest(playerId)
            end
        end
    end

    if endIdx < n and chunkSize > 0 then
        SetTimeout(0, function()
            M.applyIncreaseChunks(ids, timeStamp, endIdx + 1, chunkSize, onDone)
        end)
    else
        onDone()
    end
end

--- Applies offline labor regeneration based on elapsed time since last labor timestamp.
--- @param playerId number Player source id.
--- @return boolean ok True when operation completed/ignored successfully, false on validation failure.
function M.addOfflineLabor(playerId)
    if not Config.systemMode.labor then
        return false, eCoreErr.feature_disabled
    end

    local row, err = playerRow(playerId)
    if not row then
        return false, err
    end

    local laborIncreaseOffline = tonumber(Config.laborIncreaseOffline)
    local laborIncreaseTime = tonumber(Config.laborIncreaseTime)

    if not laborIncreaseTime or laborIncreaseTime < 1 or
        not laborIncreaseOffline or laborIncreaseOffline < 1 then
        return false, eCoreErr.not_valid_amount
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
    row.labor.val = hf.clamp(row.labor.val + offlineLabor, Config.laborLimit)
    quote().invalidateLaborQuoteCache(playerId)
    return true
end

return M
