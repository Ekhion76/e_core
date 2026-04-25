--- General framework-agnostic helper utilities: random/text, table handling, trim,
--- rounding, copying, and similar generic helpers.
--- Goal: shared, minimal helper toolkit for consumer scripts and e_core internals,
--- exposed through the same global `hf` table.
---
--- e_core-specific helpers (item definition normalization, registry waiting, MySQL wrapper,
--- startup logging, net rate limit, `moneyFormat`) live in `libs/helper_ecore.lua`.
--- That file is loaded immediately after this one in manifest order; after load,
--- `eCore.helper` still points to the full merged `hf` table (`bridge/main.lua`).

hf = {}
hf.stringCharset = {}
hf.numberCharset = {}

for i = 48, 57 do
    hf.numberCharset[#hf.numberCharset + 1] = string.char(i)
end
for i = 65, 90 do
    hf.stringCharset[#hf.stringCharset + 1] = string.char(i)
end
for i = 97, 122 do
    hf.stringCharset[#hf.stringCharset + 1] = string.char(i)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param length any
--- @return any result
function hf.randomStr(length)
    local result = {}
    for i = 1, length do
        result[i] = hf.stringCharset[math.random(#hf.stringCharset)]
    end
    return table.concat(result)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param length any
--- @return any result
function hf.randomInt(length)
    local result = {}
    for i = 1, length do
        result[i] = hf.numberCharset[math.random(#hf.numberCharset)]
    end
    return table.concat(result)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function hf.getSerialNumber()
    return tostring(
        hf.randomInt(2) ..
        hf.randomStr(3) ..
        hf.randomInt(1) ..
        hf.randomStr(2) ..
        hf.randomInt(3) ..
        hf.randomStr(4))
end

---searches for the first match between the values of two tables
---@param t1 table
---@param t2 table
---@return boolean
function hf.findingFirstMatch(t1, t2)
    if not t1 or not t2 then
        return false
    end

    if hf.isEmpty(t1) or hf.isEmpty(t2) then
        return false
    end

    t1 = hf.strToTable(t1)
    t2 = hf.strToTable(t2)

    for _, v1 in pairs(t1) do
        for _, v2 in pairs(t2) do
            if v1 == v2 then
                return true
            end
        end
    end

    return false
end

---returns the text as a table
---@param v string
---@return table
function hf.strToTable(v)
    if type(v) == 'table' then
        return v
    end

    return { v }
end

---returns the values of the table separated by commas
---@param v table
---@return string
function hf.tableToStr(v)
    if type(v) ~= 'table' then
        return v
    end

    return table.concat(v, ", ")
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param t any
--- @return any result
function hf.isTable(t)
    return type(t) == 'table'
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param t any
--- @return any result
function hf.isPopulatedTable(t)
    return type(t) == 'table' and (next(t)) ~= nil
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param s any
--- @return any result
function hf.isPopulatedString(s)
    if type(s) ~= 'string' then
        return false
    end

    return string.gsub(s, '^%s*(.-)%s*$', '%1') ~= ''
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param v any
--- @return any result
function hf.isEmpty(v)
    if v == nil then
        return true
    end

    local tType = type(v)

    if tType == 'boolean' or tType == 'function' or tType == 'number' then
        return false
    end

    if tType == 'table' then
        return (next(v)) == nil
    end

    if tType == 'string' then
        return string.gsub(v, '^%s*(.-)%s*$', '%1') == ''
    end

    return true
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param needs any
--- @param t any
--- @return any result
function hf.inTable(needs, t)
    if needs and type(t) == 'table' and next(t) then
        for _, v in pairs(t) do
            if v == needs then
                return true
            end
        end
    end

    return false
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param v any
--- @return any result
function hf.trim(v)
    return type(v) == 'string' and (string.gsub(v, '^%s*(.-)%s*$', '%1')) or v
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param num any
--- @param numDecimalPlaces any
--- @return any result
function hf.round(num, numDecimalPlaces)
    if not numDecimalPlaces then
        return math.floor(num + 0.5)
    end
    local mul = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mul + 0.5) / mul
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param t any
--- @return any result
function hf.tableToVector(t)
    if type(t) ~= 'table' then
        return t
    end

    local x = tonumber(t.x)
    local y = tonumber(t.y)
    local z = tonumber(t.z)
    local w = tonumber(t.w)

    if not x or not y or not z then
        return false
    end

    return w and vec(x, y, z, w) or vec(x, y, z)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param str any
--- @param prefix any
--- @return any result
function hf.removePrefix(str, prefix)
    return (str:sub(0, #prefix) == prefix) and str:sub(#prefix + 1) or str
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param number any
--- @return any result
function hf.numberFormat(number)
    if not tonumber(number) then
        return number
    end

    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1 ")
    return minus .. int:reverse():gsub("^ ", "") .. fraction
end

--- Shallow table copy via `pairs`; non-table input is returned unchanged.
--- Environment-agnostic alternative to `table.clone`.
function hf.shallowCopy(t)
    if type(t) ~= 'table' then
        return t
    end
    local out = {}
    for k, v in pairs(t) do
        out[k] = v
    end
    return out
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param t any
--- @return any result
function hf.copy(t)
    return hf.shallowCopy(t)
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param orig any
--- @param copies any
--- @return any result
function hf.deepCopy(orig, copies)
    copies = copies or {}

    if type(orig) ~= 'table' then
        return orig
    elseif copies[orig] then
        return copies[orig] -- return existing copy for cyclic references
    end

    local copy = {}
    copies[orig] = copy

    for k, v in next, orig, nil do
        copy[hf.deepCopy(k, copies)] = hf.deepCopy(v, copies)
    end

    setmetatable(copy, hf.deepCopy(getmetatable(orig), copies))

    return copy
end


--- Auto-generated annotation. Refine behavior details if needed.
--- @param v any
--- @param max any
--- @return any result
function hf.rangeLimit(v, max)
    return v < 0 and 0 or v > max and max or v
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param chance any
--- @return any result
function hf.draw(chance)
    chance = tonumber(chance) or 100
    if chance < 1 then return false end
    if chance >= 100 then return true end
    return math.random(100) <= chance
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param input any
--- @param sep any
--- @return any result
function hf.stringSplit(input, sep)
    sep = sep or "%s"
    local t = {}
    for str in input:gmatch("([^" .. sep .. "]+)") do
        t[#t + 1] = str
    end
    return t
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param t any
--- @return any result
function hf.getKeys(t)
    local keys = {}
    for key in pairs(t) do
        keys[#keys + 1] = key
    end
    return keys
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param inputString any
--- @return any result
function hf.removeNonAlphaNumeric(inputString)
    if type(inputString) ~= "string" or inputString == nil then
        return nil
    end
    return inputString:gsub("[^%w]", "")
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param t any
--- @return any result
function hf.shuffle(t)
    if type(t) ~= 'table' or not next(t) then
        return false
    end

    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end
