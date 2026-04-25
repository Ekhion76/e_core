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
    loadMeta(xPlayer)
end)

--- Reserved root meta keys managed by lifecycle/save flow (`prepareMeta`, persistence).
--- They are read-only for `registerMeta` / `setMeta` and excluded from ability APIs.
--- Use `exports.e_core:*Labor*` for labor operations.
local META_SYSTEM_ROOT_KEYS = {
    login = true,
    logout = true,
    labor = true,
}

--- @return string|nil trimmed
--- @return string|nil err eCoreErr
local function meta_trim_non_empty_string(key)
    if type(key) ~= 'string' then
        return nil, eCoreErr.no_valid_meta_name
    end
    local trimmed = hf.trim(key)
    if trimmed == '' then
        return nil, eCoreErr.no_valid_meta_name
    end
    return trimmed, nil
end

--- Lookup key normalizer for read access (`getMeta` category mode).
--- Reserved keys like `labor` / `login` are allowed for reads.
local function meta_normalize_lookup_key(key)
    return meta_trim_non_empty_string(key)
end

--- Writable category normalizer for `registerMeta` / `setMeta`.
--- Reserved system root keys are rejected.
--- @return string|nil
--- @return string|nil err
local function meta_normalize_writable_category(key)
    local trimmed, err = meta_trim_non_empty_string(key)
    if not trimmed then
        return nil, err
    end
    if META_SYSTEM_ROOT_KEYS[trimmed] then
        return nil, eCoreErr.reserved_meta_category
    end
    return trimmed, nil
end

--- @param category string|nil
--- @param name string|nil
--- @return number resolved ability cap (profession-specific if configured, else Config.abilityLimit)
function resolveAbilityCap(category, name)
    local fallback = tonumber(Config.abilityLimit) or 0
    local progression = Config.progression
    if type(progression) ~= 'table' then
        return fallback
    end

    local byProfession = progression.maxByProfession
    if type(byProfession) ~= 'table' then
        return fallback
    end

    if type(category) ~= 'string' or type(name) ~= 'string' then
        return fallback
    end

    local ck = hf.trim(category)
    local nk = hf.trim(name)
    if ck == '' or nk == '' then
        return fallback
    end

    local bucket = byProfession[ck]
    if type(bucket) ~= 'table' then
        return fallback
    end

    local cap = tonumber(bucket[nk])
    if not cap or cap ~= cap then
        return fallback
    end

    if cap < 0 then
        cap = 0
    end

    return math.floor(cap)
end

--- @return table|nil row ECO.meta[playerId]
--- @return string|nil err eCoreErr
local function meta_require_player_row(playerId)
    if not tonumber(playerId) then
        return nil, eCoreErr.not_found_metadata
    end
    local row = ECO.meta[playerId]
    if type(row) ~= 'table' then
        return nil, eCoreErr.not_found_metadata
    end
    return row, nil
end

--- @param playerId number (source)
--- @param meta string Category key (for example: crafting, reputation).
--- @param value table Key-value payload (stored as a shallow copy).
--- @return boolean success
--- @return string|nil reason eCoreErr when success is false.
function setMeta(playerId, meta, value)
    local row, err = meta_require_player_row(playerId)
    if not row then
        return false, err
    end

    local metaKey, errn = meta_normalize_writable_category(meta)
    if not metaKey then
        return false, errn
    end

    if type(value) ~= 'table' then
        return false, eCoreErr.meta_value_must_be_table
    end

    row[metaKey] = hf.shallowCopy(value)
    if type(invalidateLaborQuoteCache) == 'function' then
        invalidateLaborQuoteCache(playerId)
    end
    syncRequest(playerId)

    return true
end

--- @param playerId number (source)
--- @param meta string|nil Optional category key (trimmed; reserved keys are readable).
--- @return boolean|table false, err | full meta table | category value (can be nil if key does not exist).
function getMeta(playerId, meta)
    local row, err = meta_require_player_row(playerId)
    if not row then
        return false, err
    end

    if meta == nil then
        return row
    end

    local mk, errk = meta_normalize_lookup_key(meta)
    if not mk then
        return false, errk
    end

    return row[mk]
end

--- Fills missing keys while keeping existing keys untouched.
--- New categories store a shallow copy of `defaultValue`.
--- Only **string** keys from `defaultValue` are applied (numeric keys are intentionally ignored).
--- @param playerId number source
--- @param category string Category key (for example: harvesting).
--- @param defaultValue table|nil Defaults payload (nil becomes empty table).
--- @return boolean success
--- @return string|nil reason eCoreErr when success is false.
function registerMeta(playerId, category, defaultValue)
    local row, err = meta_require_player_row(playerId)
    if not row then
        return false, err
    end

    local ck, errc = meta_normalize_writable_category(category)
    if not ck then
        return false, errc
    end

    if defaultValue == nil then
        defaultValue = {}
    elseif type(defaultValue) ~= 'table' then
        return false, eCoreErr.meta_default_must_be_table
    end

    local slot = rawget(row, ck)
    if slot == nil then
        row[ck] = hf.shallowCopy(defaultValue)
        if type(invalidateLaborQuoteCache) == 'function' then
            invalidateLaborQuoteCache(playerId)
        end
        syncRequest(playerId)
        return true
    end

    if type(slot) ~= 'table' then
        return false, eCoreErr.meta_category_not_table
    end

    local dirty = false
    for k, v in pairs(defaultValue) do
        if type(k) == 'string' and rawget(slot, k) == nil then
            slot[k] = v
            dirty = true
        end
    end

    if dirty then
        if type(invalidateLaborQuoteCache) == 'function' then
            invalidateLaborQuoteCache(playerId)
        end
        syncRequest(playerId)
    end

    return true
end

--- @param playerId number (source)
--- @param category string Category key (for example: crafting).
--- @param name string Ability key (for example: weaponry).
--- @return boolean|number false, err | current ability value.
function getAbility(playerId, category, name)
    local row, err = meta_require_player_row(playerId)
    if not row then
        return false, err
    end

    local ck, errc = meta_normalize_lookup_key(category)
    if not ck then
        return false, errc
    end
    if META_SYSTEM_ROOT_KEYS[ck] then
        return false, eCoreErr.reserved_meta_category
    end

    local nk, errn = meta_trim_non_empty_string(name)
    if not nk then
        return false, errn
    end

    if not checkMetaExists(playerId, ck, nk) then
        return false, eCoreErr.not_found_metadata
    end

    return row[ck][nk]
end

--- @param playerId number (source)
--- @param category string
--- @param name string
--- @param value number|string Delta value to add.
--- @return boolean success
--- @return string|nil reason eCoreErr when success is false.
function addAbility(playerId, category, name, value)
    local row, err = meta_require_player_row(playerId)
    if not row then
        return false, err
    end

    local ck, errc = meta_normalize_lookup_key(category)
    if not ck then
        return false, errc
    end
    if META_SYSTEM_ROOT_KEYS[ck] then
        return false, eCoreErr.reserved_meta_category
    end

    local nk, errn = meta_trim_non_empty_string(name)
    if not nk then
        return false, errn
    end

    if not checkMetaExists(playerId, ck, nk) then
        return false, eCoreErr.not_found_metadata
    end

    local delta = tonumber(value)
    if not delta then
        return false, eCoreErr.not_valid_amount
    end

    local metaValue = row[ck][nk]
    local baseValue = metaValue
    local abilityCap = resolveAbilityCap(ck, nk)

    if metaValue >= abilityCap then
        return false, eCoreErr.has_already_reached_the_limit
    end

    metaValue = metaValue + delta

    local newValue = hf.rangeLimit(metaValue, abilityCap)

    if baseValue ~= newValue then
        row[ck][nk] = newValue
        messageIfLevelChange(playerId, ck, nk, baseValue, newValue)
        if type(invalidateLaborQuoteCache) == 'function' then
            invalidateLaborQuoteCache(playerId)
        end
        syncRequest(playerId)
    end

    return true
end

--- @param playerId number (source)
--- @param category string
--- @param name string
--- @param value number|string Delta value to subtract.
--- @return boolean success
--- @return string|nil reason eCoreErr when success is false.
function removeAbility(playerId, category, name, value)
    local row, err = meta_require_player_row(playerId)
    if not row then
        return false, err
    end

    local ck, errc = meta_normalize_lookup_key(category)
    if not ck then
        return false, errc
    end
    if META_SYSTEM_ROOT_KEYS[ck] then
        return false, eCoreErr.reserved_meta_category
    end

    local nk, errn = meta_trim_non_empty_string(name)
    if not nk then
        return false, errn
    end

    if not checkMetaExists(playerId, ck, nk) then
        return false, eCoreErr.not_found_metadata
    end

    local delta = tonumber(value)
    if not delta then
        return false, eCoreErr.not_valid_amount
    end

    local metaValue = row[ck][nk]
    local baseValue = metaValue
    local abilityCap = resolveAbilityCap(ck, nk)

    metaValue = metaValue - delta

    local newValue = hf.rangeLimit(metaValue, abilityCap)

    if baseValue ~= newValue then
        row[ck][nk] = newValue
        messageIfLevelChange(playerId, ck, nk, baseValue, newValue)
        if type(invalidateLaborQuoteCache) == 'function' then
            invalidateLaborQuoteCache(playerId)
        end
        syncRequest(playerId)
    end

    return true
end

--- @param playerId number (source)
--- @param category string
--- @param name string
--- @param value number|string Absolute value to set.
--- @return boolean success
--- @return string|nil reason eCoreErr when success is false.
function setAbility(playerId, category, name, value)
    local row, err = meta_require_player_row(playerId)
    if not row then
        return false, err
    end

    local ck, errc = meta_normalize_lookup_key(category)
    if not ck then
        return false, errc
    end
    if META_SYSTEM_ROOT_KEYS[ck] then
        return false, eCoreErr.reserved_meta_category
    end

    local nk, errn = meta_trim_non_empty_string(name)
    if not nk then
        return false, errn
    end

    if not checkMetaExists(playerId, ck, nk) then
        return false, eCoreErr.not_found_metadata
    end

    local numValue = tonumber(value)
    if not numValue then
        return false, eCoreErr.not_valid_amount
    end

    local metaValue = row[ck][nk]
    local baseValue = metaValue
    local abilityCap = resolveAbilityCap(ck, nk)
    local newValue = hf.rangeLimit(numValue, abilityCap)

    if baseValue ~= newValue then
        row[ck][nk] = newValue
        messageIfLevelChange(playerId, ck, nk, baseValue, newValue)
        if type(invalidateLaborQuoteCache) == 'function' then
            invalidateLaborQuoteCache(playerId)
        end
        syncRequest(playerId)
    end

    return true
end

--- Queues meta sync for player and flushes batched sync events in next tick.
--- @param playerId number
--- @return nil
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

--- Initializes runtime meta structure for a player from persisted payload.
--- @param playerId number
--- @param meta table
--- @return nil
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
--- Server-side bridge events only (TriggerEvent). Do not expose as RegisterServerEvent,
--- otherwise clients could inject forged xPlayer payloads.
AddEventHandler('e_core:playerLoaded', function(xPlayer)
    if not xPlayer or not xPlayer.source then
        return
    end
    loadMeta(xPlayer)
end)

--- Persists player metadata if save cooldown allows it.
--- @param playerId number
--- @param event string
--- @return nil
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

--- Periodic save loop (10-minute interval).
--- @return nil
local function scheduledSave()
    SetTimeout(60000 * 10, function()
        saveAllMeta()
        scheduledSave()
    end)
end

scheduledSave()
