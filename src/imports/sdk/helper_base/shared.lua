--- General framework-agnostic helper utilities: random/text, table handling, trim,
--- rounding, copying, and similar generic helpers.
--- Goal: shared, minimal helper toolkit for consumer scripts and e_core internals,
--- exposed through the same global `hf` table.
---
--- e_core-specific helpers (item definition normalization, registry waiting, MySQL wrapper,
--- startup logging, net rate limit, `moneyFormat`) live in `libs/helper_ecore.lua`.
--- That file is loaded immediately after this one in manifest order; after load,
--- `eCore.helper` still points to the full merged `hf` table (`bridge/main.lua`).

--- Rename map (old -> new)
--- hf.randomStr            → hf.randomAlpha
--- hf.randomInt            → hf.randomDigits      (returns string, not number)
--- hf.getSerialNumber      → hf.genSerial
--- hf.findingFirstMatch    → hf.hasCommonValue
--- hf.strToTable           → hf.wrap
--- hf.tableToStr           → hf.joinValues
--- hf.isPopulatedTable     → hf.hasEntries
--- hf.isPopulatedString    → hf.hasContent
--- hf.inTable              → hf.contains
--- hf.tableToVector        → hf.toVector
--- hf.removePrefix         → hf.stripPrefix
--- hf.numberFormat         → hf.formatNumber
--- hf.copy                 → removed (it was an alias of hf.shallowCopy)
--- hf.rangeLimit           → hf.clamp
--- hf.draw                 → hf.chance
--- hf.stringSplit          → hf.split
--- hf.getKeys              → hf.keys
--- hf.removeNonAlphaNumeric → hf.alphaNum

local M = {

--- Recursively prints table/function values to console for debug sessions.
--- @param t table|function|any Value to dump.
--- @return nil
function M.print_r(t)
    local visited = {}

    local function walk(val, indent)
        local id = tostring(val)

        if visited[id] then
            print(indent .. "* " .. id)
            return
        end

        if type(val) ~= "table" then
            print(indent .. id)
            return
        end

        visited[id] = true

        for k, v in pairs(val) do
            local key_str  = tostring(k)
            local child_indent = indent .. string.rep(" ", #key_str + 8)

            if type(v) == "table" then
                print(indent .. "[" .. key_str .. "] => " .. tostring(val) .. " {")
                walk(v, child_indent)
                print(indent .. string.rep(" ", #key_str + 6) .. "}")
            else
                print(indent .. "[" .. key_str .. "] => " .. tostring(v))
            end
        end
    end

    walk(t, "  ")
end


local debugLevelOverride = nil

--- Overrides logger verbosity for this helper module.
--- `nil` clears override and falls back to `Config.debugLevel` when available.
--- @param level number|nil
--- @return nil
function M.setDebugLevel(level)
    if level == nil then
        debugLevelOverride = nil
        return
    end
    local n = tonumber(level)
    if not n or n ~= n then
        debugLevelOverride = nil
        return
    end
    debugLevelOverride = math.max(0, math.floor(n))
end

-- TODO: Debuglevel átadása problémára megoldás kell
--- Returns effective logger verbosity.
--- Priority: module override -> `Config.debugLevel` -> 0.
--- @return number
function M.getDebugLevel()
    if debugLevelOverride ~= nil then
        return debugLevelOverride
    end
    local cfg = rawget(_G, 'Config')
    local n = type(cfg) == 'table' and tonumber(cfg.debugLevel) or nil
    if not n or n ~= n then
        return 0
    end
    return math.max(0, math.floor(n))
end

M.numberCharset = {}
M.stringCharset = {}

for i = 48, 57 do
    M.numberCharset[#M.numberCharset + 1] = string.char(i)
end
for i = 65, 90 do
    M.stringCharset[#M.stringCharset + 1] = string.char(i)
end
for i = 97, 122 do
    M.stringCharset[#M.stringCharset + 1] = string.char(i)
end

---returns a random alphabetic string of the given length
---@param length number
---@return string
function M.randomAlpha(length)
    length = math.max(0, math.floor(tonumber(length) or 0))
    local result = {}
    for i = 1, length do
        result[i] = M.stringCharset[math.random(#M.stringCharset)]
    end
    return table.concat(result)
end

---returns a random digit string of the given length (returns string, not number)
---@param length number
---@return string
function M.randomDigits(length)
    length = math.max(0, math.floor(tonumber(length) or 0))
    local result = {}
    for i = 1, length do
        result[i] = M.numberCharset[math.random(#M.numberCharset)]
    end
    return table.concat(result)
end

---generates a random serial number string
---@return string
function M.genSerial()
    return M.randomDigits(2) ..
        M.randomAlpha(3) ..
        M.randomDigits(1) ..
        M.randomAlpha(2) ..
        M.randomDigits(3) ..
        M.randomAlpha(4)
end

---returns true if the two tables share at least one common value
---@param t1 table
---@param t2 table
---@return boolean
function M.hasCommonValue(t1, t2)
    if not t1 or not t2 then
        return false
    end

    t1 = M.wrap(t1)
    t2 = M.wrap(t2)

    if M.isEmptyTable(t1) or M.isEmptyTable(t2) then
        return false
    end

    -- Build a membership lookup first, then scan the other side once (O(n+m)).
    local lookup = {}
    for _, v in pairs(t2) do
        lookup[v] = true
    end

    for _, v in pairs(t1) do
        if lookup[v] then
            return true
        end
    end

    return false
end

---wraps a non-table value into a single-element table; tables are returned as-is
---@param v string|table
---@return table
function M.wrap(v)
    if type(v) == 'table' then
        return v
    end

    return { v }
end

---joins table values into a comma-separated string; non-tables are returned as-is
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

---returns true if t is a table with at least one entry
---@param t any
---@return boolean
function M.hasEntries(t)
    return type(t) == 'table' and (next(t)) ~= nil
end

---returns true if s is a string containing at least one non-whitespace character
---@param s any
---@return boolean
function M.hasContent(s)
    return type(s) == 'string' and s:match('%S') ~= nil
end

--- Checks whether player source currently exists (server-side).
---@param src number|string
---@return boolean
function M.isValidPlayerSource(src)
    src = tonumber(src)
    if src == nil or src < 1 then
        return false
    end
    local name = GetPlayerName(src)
    return name ~= nil and name ~= ''
end

---returns true if t is a table without any entries
---@param t any
---@return boolean
function M.isEmptyTable(t)
    return type(t) == 'table' and next(t) == nil
end

---returns true if needs is found among the values of t
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

---trims leading and trailing whitespace from a string; non-strings are returned as-is
---@param v any
---@return any
function M.trim(v)
    return type(v) == 'string' and v:match('^%s*(.-)%s*$') or v
end

---rounds num to numDecimalPlaces decimal places; rounds to integer if omitted
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

---linearly interpolates between a and b using t in [0..1]
---@param a number
---@param b number
---@param t number
---@return number
function M.lerp(a, b, t)
    local na = tonumber(a) or 0
    local nb = tonumber(b) or 0
    local nt = tonumber(t)
    if nt == nil then
        nt = 0
    elseif nt < 0 then
        nt = 0
    elseif nt > 1 then
        nt = 1
    end
    return na + (nb - na) * nt
end

---converts a table with x/y/z(/w) fields to a vector; returns false if coords are missing
---@param t any
---@return vector|boolean
function M.toVector(t)
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

---removes the given prefix from str if present; otherwise returns str unchanged
---@param str string
---@param prefix string
---@return string
function M.stripPrefix(str, prefix)
    return (str:sub(1, #prefix) == prefix) and str:sub(#prefix + 1) or str
end

---formats a number with space-separated thousands groups
---@param number any
---@return any
function M.formatNumber(number)
    if not tonumber(number) then
        return number
    end

    local _, _, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1 ")
    return minus .. int:reverse():gsub("^ ", "") .. fraction
end

---shallow table copy via pairs; non-table input is returned unchanged
---@param t any
---@return any
function M.shallowCopy(t)
    if type(t) ~= 'table' then
        return t
    end
    local out = {}
    for k, v in pairs(t) do
        out[k] = v
    end
    return out
end

---deep copy with cyclic reference handling
---@param orig any
---@param copies table|nil
---@return any
function M.deepCopy(orig, copies)
    copies = copies or {}

    if type(orig) ~= 'table' then
        return orig
    elseif copies[orig] then
        return copies[orig]
    end

    local copy = {}
    copies[orig] = copy

    for k, v in next, orig, nil do
        copy[M.deepCopy(k, copies)] = M.deepCopy(v, copies)
    end

    setmetatable(copy, M.deepCopy(getmetatable(orig), copies))

    return copy
end

---clamps v between 0 and max
---@param v number
---@param max number
---@return number
function M.clamp(v, max)
    local nv = tonumber(v) or 0
    local nmax = tonumber(max) or 0
    if nmax < 0 then
        nmax = 0
    end
    return nv < 0 and 0 or nv > nmax and nmax or nv
end

---returns true with the given percentage chance (0–100); always false below 1, always true at 100+
---@param chance number
---@return boolean
function M.chance(chance)
    chance = tonumber(chance) or 100
    if chance < 1 then return false end
    if chance >= 100 then return true end
    return math.random(100) <= chance
end

---splits input string by sep (default: whitespace); returns a table of tokens
---@param input string
---@param sep string|nil
---@return table tokens
function M.split(input, sep)
    if type(input) ~= 'string' then
        return {}
    end

    local out = {}
    if sep == nil then
        for token in input:gmatch('%S+') do
            out[#out + 1] = token
        end
        return out
    end

    sep = tostring(sep)
    if sep == '' then
        out[1] = input
        return out
    end

    -- Plain delimiter scan to avoid Lua pattern edge-cases in separators.
    local startPos = 1
    while true do
        local hitStart, hitEnd = string.find(input, sep, startPos, true)
        if not hitStart then
            local tail = string.sub(input, startPos)
            if tail ~= '' then
                out[#out + 1] = tail
            end
            break
        end
        if hitStart > startPos then
            out[#out + 1] = string.sub(input, startPos, hitStart - 1)
        end
        startPos = hitEnd + 1
        if startPos > #input then
            break
        end
    end

    return out
end

---returns true when v is within inclusive [minValue, maxValue] range
---@param v number
---@param minValue number
---@param maxValue number
---@return boolean
function M.inRange(v, minValue, maxValue)
    local nv = tonumber(v)
    local nmin = tonumber(minValue)
    local nmax = tonumber(maxValue)
    if not nv or not nmin or not nmax then
        return false
    end
    if nmin > nmax then
        nmin, nmax = nmax, nmin
    end
    return nv >= nmin and nv <= nmax
end

---executes fn protected by pcall and returns ok, resultOrError
---@param fn function
---@return boolean ok
---@return any resultOrError
function M.try(fn)
    if type(fn) ~= 'function' then
        return false, 'invalid_function'
    end
    return pcall(fn)
end

---returns true when distance between vectors is <= radius
---@param v1 vector3|vector4
---@param v2 vector3|vector4
---@param radius number
---@return boolean
function M.isNearby(v1, v2, radius)
    local r = tonumber(radius)
    if not r or r < 0 then
        return false
    end
    local ok, distance = pcall(function()
        return #(v1 - v2)
    end)
    return ok and distance <= r or false
end

---maps table values through fn(value, key)
---@param t table
---@param fn function
---@return table mapped
function M.map(t, fn)
    if type(t) ~= 'table' or type(fn) ~= 'function' then
        return {}
    end
    local out = {}
    for k, v in pairs(t) do
        out[k] = fn(v, k)
    end
    return out
end

---filters table values by predicate fn(value, key)
---@param t table
---@param fn function
---@return table filtered
function M.filter(t, fn)
    if type(t) ~= 'table' or type(fn) ~= 'function' then
        return {}
    end
    local out = {}
    -- Keep array shape for list-like input; keep keys for map-like input.
    local isArray = #t > 0
    for k, v in pairs(t) do
        if fn(v, k) then
            if isArray then
                out[#out + 1] = v
            else
                out[k] = v
            end
        end
    end
    return out
end

---finds first value matching predicate fn(value, key)
---@param t table
---@param fn function
---@return any value
---@return any key
function M.find(t, fn)
    if type(t) ~= 'table' or type(fn) ~= 'function' then
        return nil, nil
    end
    for k, v in pairs(t) do
        if fn(v, k) then
            return v, k
        end
    end
    return nil, nil
end

--- Debug console logger filtered by `Config.debugLevel`.
--- Supports compact severity mode when `v` is one of:
--- `error`, `warning`, `info`, `debug` and `level` is numeric.
--- @param k string|number|any Log key/title.
--- @param v any Value payload or severity string.
--- @param level number|nil Log verbosity level.
--- @return nil
function M.cLog(k, v, level)
    local currentLevel = M.getDebugLevel()
    if currentLevel < 1 then
        return
    end

    if level and level > currentLevel then
        return
    end

    local vType = type(v)
    local severityColor = {
        error = '^1',
        warning = '^3',
        info = '^2',
        debug = '^5',
    }
    if vType == 'string' and severityColor[v] and type(level) == 'number' then
        print(severityColor[v] .. '[' .. string.upper(v) .. ']^7', tostring(k), '^7')
        return
    end

    if vType == 'table' or vType == 'function' then
        print('^3DEBUG', k, '^4')
        M.print_r(v)
        print('^7')
    else
        if vType == 'boolean' then
            v = v and 'true' or 'false'
        end

        if v == nil then
            v = 'nil'
        end

        print('^3DEBUG', k, '->^4', v, '^7')
    end
end

--- Simple player+key rate limit (server net-event guard).
---@param src number|string player source
---@param name string unique key, e.g. event name
---@param cooldownMs number
---@return boolean true when call is allowed
function M.netRateLimit(src, name, cooldownMs)
    if not M.isValidPlayerSource(src) then
        return false
    end
    cooldownMs = tonumber(cooldownMs) or 0
    if cooldownMs < 0 then
        cooldownMs = 0
    end
    M.__netRate = M.__netRate or {}
    local k = tostring(src) .. '|' .. tostring(name)
    local now = GetGameTimer()
    local last = M.__netRate[k] or 0
    if now - last < cooldownMs then
        return false
    end
    M.__netRate[k] = now
    return true
end

---returns all keys of t as an array
---@param t table
---@return table
function M.keys(t)
    local keys = {}
    for key in pairs(t) do
        keys[#keys + 1] = key
    end
    return keys
end

---strips all non-alphanumeric characters from inputString; returns nil for non-strings
---@param inputString any
---@return string|nil
function M.alphaNum(inputString)
    if type(inputString) ~= "string" then
        return nil
    end
    return inputString:gsub("[^%w]", "")
end

---Fisher-Yates shuffle in-place; returns false for non-tables or empty tables
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
