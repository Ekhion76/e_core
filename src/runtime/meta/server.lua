local M = {}
local quoteApi = nil
local hf = lib.require('src/imports/sdk/helper_base/shared')

--- Lazily resolves quote API to avoid load-time circular require.
--- @return table
local function quote()
    if not quoteApi then
        quoteApi = lib.require('src/runtime/quote/logic')
    end
    return quoteApi
end

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
function M.resolveAbilityCap(category, name)
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

--- @return table|nil row PlayerMetaStore row for `playerId`
--- @return string|nil err eCoreErr
local function meta_require_player_row(playerId)
    if not tonumber(playerId) then
        return nil, eCoreErr.not_found_metadata
    end
    local row = PlayerMetaStore.get(playerId)
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
function M.setMeta(playerId, meta, value)
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
    quote().invalidateLaborQuoteCache(playerId)
    M.syncRequest(playerId)

    return true
end

--- @param playerId number (source)
--- @param meta string|nil Optional category key (trimmed; reserved keys are readable).
--- @return boolean|table false, err | full meta table | category value (can be nil if key does not exist).
function M.getMeta(playerId, meta)
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
function M.registerMeta(playerId, category, defaultValue)
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
        quote().invalidateLaborQuoteCache(playerId)
        M.syncRequest(playerId)
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
        quote().invalidateLaborQuoteCache(playerId)
        M.syncRequest(playerId)
    end

    return true
end

--- @param playerId number (source)
--- @param category string Category key (for example: crafting).
--- @param name string Ability key (for example: weaponry).
--- @return boolean|number false, err | current ability value.
function M.getAbility(playerId, category, name)
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
function M.addAbility(playerId, category, name, value)
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
    local abilityCap = M.resolveAbilityCap(ck, nk)

    if metaValue >= abilityCap then
        return false, eCoreErr.has_already_reached_the_limit
    end

    metaValue = metaValue + delta

    local newValue = hf.clamp(metaValue, abilityCap)

    if baseValue ~= newValue then
        row[ck][nk] = newValue
        messageIfLevelChange(playerId, ck, nk, baseValue, newValue)
        quote().invalidateLaborQuoteCache(playerId)
        M.syncRequest(playerId)
    end

    return true
end

--- @param playerId number (source)
--- @param category string
--- @param name string
--- @param value number|string Delta value to subtract.
--- @return boolean success
--- @return string|nil reason eCoreErr when success is false.
function M.removeAbility(playerId, category, name, value)
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
    local abilityCap = M.resolveAbilityCap(ck, nk)

    metaValue = metaValue - delta

    local newValue = hf.clamp(metaValue, abilityCap)

    if baseValue ~= newValue then
        row[ck][nk] = newValue
        messageIfLevelChange(playerId, ck, nk, baseValue, newValue)
        quote().invalidateLaborQuoteCache(playerId)
        M.syncRequest(playerId)
    end

    return true
end

--- @param playerId number (source)
--- @param category string
--- @param name string
--- @param value number|string Absolute value to set.
--- @return boolean success
--- @return string|nil reason eCoreErr when success is false.
function M.setAbility(playerId, category, name, value)
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
    local abilityCap = M.resolveAbilityCap(ck, nk)
    local newValue = hf.clamp(numValue, abilityCap)

    if baseValue ~= newValue then
        row[ck][nk] = newValue
        messageIfLevelChange(playerId, ck, nk, baseValue, newValue)
        quote.invalidateLaborQuoteCache(playerId)
        M.syncRequest(playerId)
    end

    return true
end

--- Queues meta sync for player and flushes batched sync events in next tick.
--- @param playerId number
--- @return nil
function M.syncRequest(playerId)
    PlayerMetaStore.queueSync(playerId)
end

--- Initializes runtime meta structure for a player from persisted payload.
--- @param playerId number
--- @param meta table
--- @return nil
function M.prepareMeta(playerId, meta)
    if type(meta) ~= 'table' then
        meta = {}
    end

    PlayerMetaStore.setPlayerMeta(playerId, meta)
    local row = PlayerMetaStore.get(playerId)
    if not row then
        return
    end

    row['login'] = os.time()
    row['logout'] = meta['logout'] or 0
    row['labor'] = meta['labor'] or { val = Config.defaultLabor, time = os.time() }
    local hudLayout = meta['hudLayout']
    if type(hudLayout) ~= 'table' then
        hudLayout = {}
    end
    if type(hudLayout.elements) ~= 'table' then
        hudLayout.elements = {}
    end
    hudLayout.v = tonumber(hudLayout.v) or 1
    row['hudLayout'] = hudLayout

    local val = row['labor'].val
    row['labor'].val = (tonumber(val) and val == val) and tonumber(val) or 0

    if hf.hasEntries(Config.metaFields) then
        for metaCategory, defaultValue in pairs(Config.metaFields) do
            row[metaCategory] = row[metaCategory] or defaultValue
        end
    end
end

--- Persists player metadata if save cooldown allows it.
--- @param playerId number
--- @param event string
--- @return nil
function M.saveRequest(playerId, event)
    local db = lib.require('src/runtime/db/logic')
    local xPlayer = eCore:getPlayer(playerId)

    if xPlayer and PlayerMetaStore.get(playerId) then
        local time = os.time()
        local last = PlayerMetaStore.getLastSave(playerId) or 0

        if time - last > 1 then
            local row = PlayerMetaStore.get(playerId)
            if row then
                row['logout'] = time
            end
            PlayerMetaStore.setLastSave(playerId, time)
            db.saveMeta(xPlayer, true)
            hf.cLog(xPlayer.name .. ' ' .. event, 'saving metadata...', 1)
        end
    end
end

return M
