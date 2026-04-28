--- Pure profession level curve math, JSON decode, and admin payload resolution (no DB).
--- Consumed by `src/server/professions.lua` for level profile CRUD and registry read model.
eCoreProfessionLevels = eCoreProfessionLevels or {}

local LEVEL_MODIFIERS = { 'labor', 'time', 'price', 'chance', 'speed' }

--- Clamp a number to an inclusive range.
--- @param value number
--- @param minValue number
--- @param maxValue number
--- @return number
local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

--- Easing factor for easy-generator milestones (`linear`, `soft`, `aggressive`).
--- @param index number 1-based milestone index
--- @param total number Milestone count (>= 1)
--- @param curveType string
--- @return number Factor in [0, 1] (or 1 when total <= 1)
local function easing_factor(index, total, curveType)
    if total <= 1 then
        return 1
    end

    local t = (index - 1) / (total - 1)
    if curveType == 'aggressive' then
        return t * t
    end
    if curveType == 'soft' then
        return math.sqrt(t)
    end
    return t
end

--- Build a levels array from easy-generator settings (milestones + max caps + curve).
--- @param settings table Expected keys: `milestones` (>=2), `maxPoints` (>0), `curveType` (`linear`|`soft`|`aggressive`), `max` table with modifier keys capped 0–100.
--- @return boolean ok
--- @return table|string levels Array of `{ limit, labor, time, price, chance, speed }` rows, or `eCoreErr` code when not ok.
local function generate_easy_levels(settings)
    if type(settings) ~= 'table' then
        return false, eCoreErr.invalid_item_data
    end

    local milestones = math.floor(tonumber(settings.milestones) or 0)
    local maxPoints = math.floor(tonumber(settings.maxPoints) or 0)
    if milestones < 2 or maxPoints <= 0 then
        return false, eCoreErr.invalid_item_data
    end

    local curveType = tostring(settings.curveType or 'linear')
    if curveType ~= 'linear' and curveType ~= 'soft' and curveType ~= 'aggressive' then
        return false, eCoreErr.invalid_item_data
    end

    local max = {}
    for _, key in ipairs(LEVEL_MODIFIERS) do
        local parsed = tonumber((settings.max or {})[key] or 0)
        if parsed == nil then
            return false, eCoreErr.not_valid_amount
        end
        max[key] = clamp(math.floor(parsed), 0, 100)
    end

    local levels = {}
    for i = 1, milestones do
        local f = easing_factor(i, milestones, curveType)
        local row = {
            limit = math.floor((maxPoints * i) / milestones),
        }
        for _, key in ipairs(LEVEL_MODIFIERS) do
            row[key] = math.floor(max[key] * f)
        end
        levels[#levels + 1] = row
    end

    return true, levels
end

--- Normalize a levels array: strictly increasing `limit`, modifiers 0–100 integers.
--- @param levels table Array of rows: each `{ limit=number|nil (last row may omit), labor?, time?, price?, chance?, speed? }`.
--- @return boolean ok
--- @return table|string normalized Rows with all modifier keys set, or `eCoreErr` code when not ok.
function eCoreProfessionLevels.normalize_levels_table(levels)
    if type(levels) ~= 'table' or #levels == 0 then
        return false, eCoreErr.not_levels_data
    end

    local normalized = {}
    local previousLimit = -1
    for idx, row in ipairs(levels) do
        if type(row) ~= 'table' then
            return false, eCoreErr.invalid_item_data
        end

        local limit = row.limit
        if limit == nil and idx == #levels then
            limit = previousLimit + 1
        end
        limit = tonumber(limit)
        if not limit then
            return false, eCoreErr.not_valid_amount
        end
        limit = math.floor(limit)
        if limit <= previousLimit then
            return false, eCoreErr.not_levels_data
        end
        previousLimit = limit

        local normalizedRow = { limit = limit }
        for _, key in ipairs(LEVEL_MODIFIERS) do
            local value = tonumber(row[key] or 0)
            if value == nil then
                return false, eCoreErr.not_valid_amount
            end
            value = math.floor(value)
            if value < 0 or value > 100 then
                return false, eCoreErr.not_valid_amount
            end
            normalizedRow[key] = value
        end
        normalized[#normalized + 1] = normalizedRow
    end

    return true, normalized
end

--- Decode `levels_json` from DB; invalid or empty input yields `{}` (never throws).
--- @param levelsJson string|nil JSON array string or empty.
--- @return table decoded Array-like table (possibly empty) on success; `{}` if not decodable.
function eCoreProfessionLevels.decode_levels_json(levelsJson)
    if type(levelsJson) ~= 'string' or levelsJson == '' then
        return {}
    end
    local ok, decoded = pcall(json.decode, levelsJson)
    if not ok or type(decoded) ~= 'table' then
        return {}
    end
    return decoded
end

--- Resolve levels from admin payload: `easyGenerator`, explicit `levels`, or normalized `fallbackLevels`.
--- @param payload table Must be a table; optional `easyGenerator`, optional `levels`.
--- @param fallbackLevels table|nil Used when neither `easyGenerator` nor `levels` is set on `payload`.
--- @return boolean ok
--- @return table|string levels Normalized rows, or `eCoreErr` code when not ok.
function eCoreProfessionLevels.resolve_profile_levels_from_payload(payload, fallbackLevels)
    if payload.easyGenerator ~= nil then
        return generate_easy_levels(payload.easyGenerator)
    end

    if payload.levels ~= nil then
        return eCoreProfessionLevels.normalize_levels_table(payload.levels)
    end

    if fallbackLevels ~= nil then
        return eCoreProfessionLevels.normalize_levels_table(fallbackLevels)
    end

    return false, eCoreErr.not_levels_data
end

--- Normalize level profile mode string for storage.
--- @param mode any
--- @return string|nil `easy` or `advanced`, or nil if invalid or nil input.
function eCoreProfessionLevels.normalize_profile_mode(mode)
    if mode == nil then
        return nil
    end
    local m = tostring(mode)
    if m ~= 'easy' and m ~= 'advanced' then
        return nil
    end
    return m
end

--- Modifier keys applied to every generated/normalized level row (read-only list for callers/tests).
eCoreProfessionLevels.MODIFIERS = LEVEL_MODIFIERS
