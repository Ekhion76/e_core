local LABOR_QUOTE_CACHE_BY_PLAYER = {}
local labor = lib.require('src/runtime/labor/logic')
local meta = lib.require('src/runtime/meta/logic')

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function getNowMs()
    return GetGameTimer()
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param context table
--- @return any result
local function resolveQuoteTtlMs(context)
    local ttlMs = GetConvarInt('e_core:labor_quote_ttl_ms', 1500)
    if type(context) == 'table' and tonumber(context.ttlMs) then
        ttlMs = tonumber(context.ttlMs)
    end
    if ttlMs < 250 then
        ttlMs = 250
    elseif ttlMs > 5000 then
        ttlMs = 5000
    end
    return math.floor(ttlMs)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param context table
--- @return any result
local function buildQuoteCacheKey(context)
    if type(context) ~= 'table' then
        return '__default'
    end

    local actionKey = tostring(context.actionKey or '')
    local category = tostring(context.category or '')
    local name = tostring(context.name or '')
    local base = tonumber(context.baseLabor) or 0

    return table.concat({
        actionKey,
        category,
        name,
        tostring(math.floor(base * 1000) / 1000),
    }, '|')
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param payload table
--- @param isCacheHit boolean
--- @param ttlLeftMs any
--- @return any result
local function withCacheMetadata(payload, isCacheHit, ttlLeftMs)
    local quote = hf.deepCopy(payload)
    quote.cache = {
        hit = isCacheHit == true,
        ttlLeftMs = math.max(0, math.floor(tonumber(ttlLeftMs) or 0)),
    }
    return quote
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param playerId number
--- @param cacheKey any
--- @return any result
local function getCachedQuote(playerId, cacheKey)
    local playerCache = LABOR_QUOTE_CACHE_BY_PLAYER[playerId]
    if type(playerCache) ~= 'table' then
        return nil
    end

    local cacheEntry = playerCache[cacheKey]
    if type(cacheEntry) ~= 'table' then
        return nil
    end

    local nowMs = getNowMs()
    if nowMs >= cacheEntry.expiresAtMs then
        playerCache[cacheKey] = nil
        return nil
    end

    return withCacheMetadata(cacheEntry.payload, true, cacheEntry.expiresAtMs - nowMs)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param playerId number
--- @param cacheKey any
--- @param payload table
--- @param ttlMs any
--- @return any result
local function storeQuoteInCache(playerId, cacheKey, payload, ttlMs)
    local playerCache = LABOR_QUOTE_CACHE_BY_PLAYER[playerId]
    if type(playerCache) ~= 'table' then
        playerCache = {}
        LABOR_QUOTE_CACHE_BY_PLAYER[playerId] = playerCache
    end

    local nowMs = getNowMs()
    playerCache[cacheKey] = {
        payload = hf.deepCopy(payload),
        expiresAtMs = nowMs + ttlMs,
    }
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param playerId number
--- @return any result
local function invalidateLaborQuoteCache(playerId)
    playerId = tonumber(playerId)
    if not playerId then
        return
    end
    LABOR_QUOTE_CACHE_BY_PLAYER[playerId] = nil
end

--- @param playerId number source
--- @param context table|nil { baseLabor:number, category:string, name:string, actionKey:string, ttlMs:number }
--- @return boolean ok
--- @return table|string quote | eCoreErr
local function getLaborQuote(playerId, context)
    playerId = tonumber(playerId)
    if not playerId then
        return false, eCoreErr.not_found_metadata
    end

    if context ~= nil and type(context) ~= 'table' then
        return false, eCoreErr.invalid_item_data
    end
    context = context or {}

    local baseLabor = tonumber(context.baseLabor) or 0
    if baseLabor < 0 or baseLabor ~= baseLabor then
        return false, eCoreErr.not_valid_amount
    end

    local cacheKey = buildQuoteCacheKey(context)
    local cachedQuote = getCachedQuote(playerId, cacheKey)
    if cachedQuote then
        return true, cachedQuote
    end

    local okLabor, currentLabor = labor.getLabor(playerId)
    if not okLabor then
        return false, currentLabor
    end

    local proficiency = 0
    local category = context.category
    local name = context.name
    if type(category) == 'string' and type(name) == 'string' and category ~= '' and name ~= '' then
        local abilityValue, err = meta.getAbility(playerId, category, name)
        if abilityValue == false then
            return false, err
        end
        proficiency = tonumber(abilityValue) or 0
    end

    local discounts, discountErr = getDiscounts(proficiency)
    if discounts == false then
        return false, discountErr
    end

    local laborDiscount = tonumber(discounts.labor) or 0
    if laborDiscount < 0 then
        laborDiscount = 0
    elseif laborDiscount > 100 then
        laborDiscount = 100
    end

    local effective = baseLabor * (1 - laborDiscount / 100)
    local paidLabor = math.max(0, math.ceil(effective))

    local payload = {
        ok = true,
        code = eCoreErr.ok,
        baseLabor = baseLabor,
        paidLabor = paidLabor,
        currentLabor = tonumber(currentLabor) or 0,
        proficiency = proficiency,
        level = tonumber(discounts.level) or getLevel(proficiency),
        discounts = hf.deepCopy(discounts),
        checks = {
            hasEnoughLabor = (tonumber(currentLabor) or 0) >= paidLabor,
        },
    }

    if type(category) == 'string' and type(name) == 'string' and category ~= '' and name ~= '' then
        local abilityCap = meta.resolveAbilityCap(category, name)
        payload.abilityCap = abilityCap
        payload.checks.isCapped = proficiency >= abilityCap
    else
        payload.abilityCap = tonumber(Config.abilityLimit) or 0
        payload.checks.isCapped = false
    end

    if not payload.checks.hasEnoughLabor then
        payload.code = eCoreErr.not_enough_labor
    end

    local ttlMs = resolveQuoteTtlMs(context)
    storeQuoteInCache(playerId, cacheKey, payload, ttlMs)

    return true, withCacheMetadata(payload, false, ttlMs)
end

return {
    getLaborQuote = getLaborQuote,
    invalidateLaborQuoteCache = invalidateLaborQuoteCache,
}

