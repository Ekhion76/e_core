--- Shared utility chunk for legacy consumer scripts.

function print_r(value)
    if type(value) ~= 'table' then
        print(value)
        return
    end
    for k, v in pairs(value) do
        print(('[%s] = %s'):format(tostring(k), tostring(v)))
    end
end

function getDistance(coords1, coords2)
    if not coords1 or not coords2 then
        return 0.0
    end
    local dx = (coords1.x or 0.0) - (coords2.x or 0.0)
    local dy = (coords1.y or 0.0) - (coords2.y or 0.0)
    local dz = (coords1.z or 0.0) - (coords2.z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function inTable(tab, value)
    if type(tab) ~= 'table' then
        return false
    end
    for _, v in pairs(tab) do
        if v == value then
            return true
        end
    end
    return false
end
