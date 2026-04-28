local HUD_LAYOUT_META_KEY = 'hudLayout'
local HUD_LAYOUT_VERSION = 1

local ALLOWED_ANCHORS = {
    ['top-left'] = true,
    ['top-right'] = true,
    ['bottom-left'] = true,
    ['bottom-right'] = true,
    ['center'] = true,
}

--- @param n any
--- @param min number
--- @param max number
--- @return number|nil
local function toFiniteRange(n, min, max)
    local v = tonumber(n)
    if v == nil or v ~= v then
        return nil
    end
    if v < min then
        return min
    end
    if v > max then
        return max
    end
    return v
end

--- @param raw table|nil
--- @param fallback table|nil
--- @return table|nil
local function sanitizePosition(raw, fallback)
    if type(raw) ~= 'table' then
        raw = fallback
    end
    if type(raw) ~= 'table' then
        return nil
    end

    local x = toFiniteRange(raw.x, 0.0, 1.0)
    local y = toFiniteRange(raw.y, 0.0, 1.0)
    if x == nil or y == nil then
        return nil
    end

    local anchor = type(raw.anchor) == 'string' and hf.trim(raw.anchor) or ''
    if anchor == '' then
        anchor = (type(fallback) == 'table' and type(fallback.anchor) == 'string') and fallback.anchor or 'top-left'
    end
    if not ALLOWED_ANCHORS[anchor] then
        anchor = 'top-left'
    end

    local width = toFiniteRange(raw.w, 0.01, 1.0) or (type(fallback) == 'table' and toFiniteRange(fallback.w, 0.01, 1.0)) or 0.2
    local height = toFiniteRange(raw.h, 0.01, 1.0) or (type(fallback) == 'table' and toFiniteRange(fallback.h, 0.01, 1.0)) or 0.1

    return {
        x = x,
        y = y,
        w = width,
        h = height,
        anchor = anchor,
    }
end

--- @param layout table|nil
--- @return table
local function sanitizeLayout(layout)
    local source = type(layout) == 'table' and layout or {}
    local sourceElements = type(source.elements) == 'table' and source.elements or {}
    local elements = {}

    for elementId, rawPos in pairs(sourceElements) do
        if type(elementId) == 'string' then
            local id = hf.trim(elementId)
            if id ~= '' then
                local pos = sanitizePosition(rawPos, nil)
                if pos then
                    elements[id] = pos
                end
            end
        end
    end

    return {
        v = HUD_LAYOUT_VERSION,
        elements = elements,
    }
end

--- @param playerId number
--- @param layout table|nil
--- @return boolean
local function applyHudLayout(playerId, layout)
    local row = PlayerMetaStore.get(playerId)
    if type(row) ~= 'table' then
        return false
    end
    row[HUD_LAYOUT_META_KEY] = sanitizeLayout(layout)
    PlayerMetaStore.queueSync(playerId)
    return true
end

--- Handles persistent HUD layout commits coming from client edit mode.
--- @param payload table|nil Expected `{ v = number, elements = table<string, table> }`.
--- @return nil
RegisterServerEvent('e_core:hud:commit', function(payload)
    local playerId = source
    if not hf.isValidPlayerSource(playerId) then
        return
    end
    local cooldown = GetConvarInt('e_core:hud_commit_rate_ms', 350)
    if cooldown < 100 then
        cooldown = 100
    end
    if not hf.netRateLimit(playerId, 'e_core:hud:commit', cooldown) then
        return
    end
    if type(payload) ~= 'table' then
        return
    end
    if type(payload.elements) ~= 'table' then
        return
    end

    local xPlayer = eCore:getPlayer(playerId)
    if not xPlayer then
        return
    end

    local merged = applyHudLayout(playerId, payload)
    if not merged then
        return
    end

    local row = PlayerMetaStore.get(playerId)
    if type(row) ~= 'table' then
        return
    end
    TriggerClientEvent('e_core:hud:applied', playerId, row[HUD_LAYOUT_META_KEY])
end)

