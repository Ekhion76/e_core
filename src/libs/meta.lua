local hf = hf

--- Auto-generated annotation. Refine behavior details if needed.
--- @param playerId number
--- @param category any
--- @param name string
--- @return any result
function checkMetaExists(playerId, category, name)

    if not tonumber(playerId) or type(ECO.meta[playerId]) ~= 'table' then

        return false
    end

    if type(category) ~= 'string' or type(ECO.meta[playerId][category]) ~= 'table' then

        return false
    end

    if type(name) ~= 'string' or not tonumber(ECO.meta[playerId][category][name]) then

        return false
    end

    return true
end

--- @param value number of points achieved in profession
--- @return number returns the player's level achieved in the profession
function getLevel(value)

    local levels = Config.levels

    if not hf.isPopulatedTable(levels) or not tonumber(value) or value < 1 then

        return 0
    end

    for i = 1, #levels do

        if levels[i].limit and levels[i].limit > value then

            --local p = levels[i - 1] or { limit = 0 }
            --local c = levels[i]
            --local progress = (value - p.limit) / (c.limit - p.limit)

            return i - 1
        end
    end

    return #levels - 1
end

--- Detects level-step index change by mapping both values through `getLevel` (Config.levels).
--- @return boolean changed True when resolved level index differs.
--- @return number|nil baseLevel
--- @return number|nil newLevel
function checkLevelChange(baseValue, newValue)
    if not hf.isPopulatedTable(Config.levels) then
        return false
    end

    local b = tonumber(baseValue)
    local n = tonumber(newValue)
    if b == nil or n == nil then
        return false
    end

    local baseLevel = getLevel(b)
    local newLevel = getLevel(n)
    if baseLevel == newLevel then
        return false
    end

    return true, baseLevel, newLevel
end

--- Server-only notifier for client NUI (`e_core:levelChange`).
--- This file is shared, so `IsDuplicityVersion()` guard is mandatory.
function messageIfLevelChange(playerId, category, name, baseValue, newValue)
    if not IsDuplicityVersion() then
        return
    end
    if not hf.isValidPlayerSource(playerId) then
        return
    end
    if type(category) ~= 'string' or type(name) ~= 'string' then
        return
    end

    local changed, baseLevel, newLevel = checkLevelChange(baseValue, newValue)
    if not changed then
        return
    end

    TriggerClientEvent('e_core:levelChange', playerId, {
        category = category,
        name = name,
        baseLevel = baseLevel,
        newLevel = newLevel,
    })
end

--- @param value number of points achieved in profession
--- @return table returns the discounts corresponding to the level
function getDiscounts(value)

    value = tonumber(value) or 0
    local levels = Config.levels

    if not hf.isPopulatedTable(levels) then

        return false, eCoreErr.not_levels_data
    end

    local discount = {}
    local numberOfLevels = #levels

    if value < levels[1].limit then

        discount = hf.shallowCopy(levels[1])
        discount.level = 0
        discount.progress = value > 0 and math.floor(value / levels[1].limit * 100) or 0

        return discount
    end

    for i = 2, numberOfLevels do

        local c = levels[i] -- current

        if c.limit and c.limit > value then

            local p = levels[i - 1] -- previous
            local progress = (value - p.limit) / (c.limit - p.limit)

            for k in pairs(c) do

                discount[k] = math.floor(p[k] + (c[k] - p[k]) * progress)
            end

            discount.limit = levels[i].limit
            discount.progress = math.floor(progress * 100)
            discount.level = i - 1

            return discount
        end
    end

    discount = hf.shallowCopy(levels[numberOfLevels])
    discount.level = numberOfLevels - 1
    discount.progress = 100

    return discount
end
