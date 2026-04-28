--- Pure shared helper module for import consumers.
--- No global writes; consumers should keep the returned table in a local variable.
local M = {}
local stringCharset = {}
local numberCharset = {}

for i = 48, 57 do
    numberCharset[#numberCharset + 1] = string.char(i)
end
for i = 65, 90 do
    stringCharset[#stringCharset + 1] = string.char(i)
end
for i = 97, 122 do
    stringCharset[#stringCharset + 1] = string.char(i)
end

---@param v any
---@return any
function M.trim(v)
    return type(v) == 'string' and v:match('^%s*(.-)%s*$') or v
end

---@param length number
---@return string
function M.randomAlpha(length)
    length = math.max(0, math.floor(tonumber(length) or 0))
    local result = {}
    for i = 1, length do
        result[i] = stringCharset[math.random(#stringCharset)]
    end
    return table.concat(result)
end

---@param length number
---@return string
function M.randomDigits(length)
    length = math.max(0, math.floor(tonumber(length) or 0))
    local result = {}
    for i = 1, length do
        result[i] = numberCharset[math.random(#numberCharset)]
    end
    return table.concat(result)
end

---@return string
function M.genSerial()
    return M.randomDigits(2) .. M.randomAlpha(3) .. M.randomDigits(1) .. M.randomAlpha(2) .. M.randomDigits(3) .. M.randomAlpha(4)
end

---@param v string|table
---@return table
function M.wrap(v)
    if type(v) == 'table' then
        return v
    end
    return { v }
end

---@param v any
---@return string
function M.joinValues(v)
    if type(v) ~= 'table' then
        return tostring(v)
    end
    if not next(v) then
        return ''
    end
    local parts = {}
    for _, value in pairs(v) do
        parts[#parts + 1] = tostring(value)
    end
    return table.concat(parts, ', ')
end

---@param t any
---@return boolean
function M.isTable(t)
    return type(t) == 'table'
end

---@param t any
---@return boolean
function M.hasEntries(t)
    return type(t) == 'table' and (next(t)) ~= nil
end

---@param t any
---@return boolean
function M.isEmptyTable(t)
    return type(t) == 'table' and next(t) == nil
end

---@param needs any
---@param t table
---@return boolean
function M.contains(needs, t)
    if type(t) == 'table' and next(t) then
        for _, v in pairs(t) do
            if v == needs then
                return true
            end
        end
    end
    return false
end

---@param num number
---@param numDecimalPlaces number|nil
---@return number
function M.round(num, numDecimalPlaces)
    if not numDecimalPlaces then
        return math.floor(num + 0.5)
    end
    local mul = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mul + 0.5) / mul
end

---@param t table
---@return table
function M.keys(t)
    local keys = {}
    for key in pairs(t) do
        keys[#keys + 1] = key
    end
    return keys
end

---@param inputString any
---@return string|nil
function M.alphaNum(inputString)
    if type(inputString) ~= "string" then
        return nil
    end
    return inputString:gsub("[^%w]", "")
end

---@param t table
---@return table|boolean
function M.shuffle(t)
    if type(t) ~= 'table' or not next(t) then
        return false
    end
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

return M
