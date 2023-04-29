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

function hf.randomStr(length)
    if length <= 0 then
        return ''
    end
    return hf.randomStr(length - 1) .. hf.stringCharset[math.random(1, #hf.stringCharset)]
end

function hf.randomInt(length)
    if length <= 0 then
        return ''
    end
    return hf.randomInt(length - 1) .. hf.numberCharset[math.random(1, #hf.numberCharset)]
end

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

function hf.isTable(t)

    return type(t) == 'table'
end

function hf.isPopulatedTable(t)

    return type(t) == 'table' and (next(t)) ~= nil
end

function hf.isPopulatedString(s)

    if type(s) ~= 'string' then

        return false
    end

    return string.gsub(s, '^%s*(.-)%s*$', '%1') ~= ''
end

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

function hf.inTable(needs, t)

    if needs ~= nil and type(t) == 'table' and next(t) then

        for _, v in pairs(t) do

            if v == needs then
                return true
            end
        end
    end

    return false
end

function hf.trim(v)

    return type(v) == 'string' and (string.gsub(v, '^%s*(.-)%s*$', '%1')) or v
end

function hf.round(num, numDecimalPlaces)
    if not numDecimalPlaces then
        return math.floor(num + 0.5)
    end
    local mul = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mul + 0.5) / mul
end

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

function hf.removePrefix(str, prefix)

    return (str:sub(0, #prefix) == prefix) and str:sub(#prefix + 1) or str
end

function hf.numberFormat(number)

    if not tonumber(number) then
        return number
    end

    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1 ")
    return minus .. int:reverse():gsub("^ ", "") .. fraction
end

function hf.moneyFormat(amount)

    if Config.currency.suffix then

        return ('%s%s'):format(hf.numberFormat(amount), Config.currency.symbol)
    else

        return ('%s%s'):format(Config.currency.symbol, hf.numberFormat(amount))
    end
end

function hf.copy(t)

    local temp

    if type(t) == 'table' then

        temp = {}

        for k, v in pairs(t) do
            temp[k] = v
        end
    else

        temp = t
    end

    return temp
end

function hf.draw(chance)

    chance = tonumber(chance)

    if not chance or chance > 99 then

        return true
    end

    if chance < 1 then

        chance = 1
    end

    math.randomseed(math.floor(os.clock() * 100000 * math.random(10000)))
    math.random();
    math.random();
    math.random();

    local box = {}

    for i = 1, 100 do
        box[i] = chance > 0
        chance = chance - 1
    end

    for i = #box, 2, -1 do
        local j = math.random(i)
        box[i], box[j] = box[j], box[i]
    end

    return box[math.random(#box)]
end