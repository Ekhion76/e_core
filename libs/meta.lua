local hf = hf

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

function checkLevelChange(baseValue, newValue)

    local levels = Config.levels

    if not hf.isPopulatedTable(levels) or not tonumber(baseValue) or not tonumber(newValue) then

        return false
    end

    local baseLevel = getLevel(baseValue)
    local newLevel = getLevel(newValue)

    if baseLevel == newLevel then

        return false
    end

    return true, baseLevel, newLevel
end

function messageIfLevelChange(playerId, category, name, baseValue, newValue)

    local change, baseLevel, newLevel = checkLevelChange(baseValue, newValue)

    if change then

        TriggerClientEvent('e_core:levelChange', playerId, {
            category = category,
            name = name,
            baseLevel = baseLevel,
            newLevel = newLevel
        })
    end
end

--- @param value number of points achieved in profession
--- @return table returns the discounts corresponding to the level
function getDiscounts(value)

    value = tonumber(value) or 0
    local levels = Config.levels

    if not hf.isPopulatedTable(levels) then

        return false, 'not_levels_data'
    end

    local discount = {}
    local numberOfLevels = #levels

    if value < levels[1].limit then

        discount = hf.copy(levels[1])
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

    discount = hf.copy(levels[numberOfLevels])
    discount.level = numberOfLevels - 1
    discount.progress = 100

    return discount
end