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
    local result = {}
    for i = 1, length do
        result[i] = hf.stringCharset[math.random(#hf.stringCharset)]
    end
    return table.concat(result)
end

function hf.randomInt(length)
    local result = {}
    for i = 1, length do
        result[i] = hf.numberCharset[math.random(#hf.numberCharset)]
    end
    return table.concat(result)
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

-- Gyakori item tábla elírások (pl. QBCore): ha nincs érvényes szabványos súlykulcs, de ezek közül van → ne 0-zzuk csendben, hanem convertItems kihagyja + log.
local MISSPELLED_WEIGHT_KEYS = {
    weigt = true,
    wieght = true,
    weigth = true,
    weght = true,
    weighjt = true,
    wight = true,
    weigtht = true,
}

--- @return string wKey
--- @return table weightKeys ordered list (same as normalizeRegisteredItemDef)
function hf.getRegisteredItemWeightKeyConfig()
    local wKey = 'weight'
    if type(Config) == 'table' and type(Config.fields) == 'table' and type(Config.fields.weight) == 'string' then
        wKey = Config.fields.weight
    end
    return wKey, { wKey, 'weight', 'Weight', 'itemWeight', 'item_weight', 'totalWeight' }
end

--- Van-e legalább egy elfogadott kulcsról olvasható nem negatív szám súly.
--- @param row table
--- @return boolean
function hf.hasResolvableStandardWeight(row)
    if type(row) ~= 'table' then
        return false
    end
    local _, weightKeys = hf.getRegisteredItemWeightKeyConfig()
    for _, k in ipairs(weightKeys) do
        local n = tonumber(row[k])
        if n and n >= 0 then
            return true
        end
    end
    return false
end

--- Ha nincs szabványos súly, de ismert elírású „weight” kulcs van → ne regisztráljuk (convertItems skip + indoklás).
--- @param row table
--- @return boolean ok ha folytatható a regisztráció
--- @return string|nil reason ha nem ok
function hf.itemDefinitionWeightGate(row)
    if type(row) ~= 'table' then
        return false, 'not_a_table'
    end
    if hf.hasResolvableStandardWeight(row) then
        return true
    end
    local wKey = hf.getRegisteredItemWeightKeyConfig()
    for k, v in pairs(row) do
        if type(k) == 'string' and MISSPELLED_WEIGHT_KEYS[k:lower()] then
            return false,
                ('invalid_weight_field:%s=%s (expected numeric key: %s)'):format(k, tostring(v), wKey)
        end
    end
    return true
end

--- REGISTERED_ITEMS / getItemWeight / canCarryItem egyeztetett mezői (bridge + override convertItems).
--- Rossz / hiányzó mezőnevek ellen: több súly- és lőszer-alias, string fallback, belső pcall + minimális fallback.
--- @param nameLower string már kisbetűs kulcs (pl. ox item kulcs)
--- @param row table a forrás item tábla (helyben módosul)
--- @return table row
function hf.normalizeRegisteredItemDef(nameLower, row)
    if type(row) ~= 'table' or type(nameLower) ~= 'string' or nameLower == '' then
        return row
    end

    local wKey, weightKeys = hf.getRegisteredItemWeightKeyConfig()

    local ok, err = pcall(function()
        row.name = nameLower

        local wNum
        for _, k in ipairs(weightKeys) do
            local n = tonumber(row[k])
            if n and n >= 0 then
                wNum = n
                break
            end
        end
        row[wKey] = wNum or 0

        local lab
        for _, k in ipairs({ 'label', 'formatName', 'title', 'Label', 'description' }) do
            local v = row[k]
            if type(v) == 'string' and v ~= '' then
                lab = v
                break
            end
            if type(v) == 'number' then
                lab = tostring(v)
                break
            end
        end
        row.label = (type(lab) == 'string' and lab ~= '') and lab or nameLower

        row.isUnique = row.isUnique == true
        row.isWeapon = row.isWeapon == true

        if type(row.image) ~= 'string' or row.image == '' then
            row.image = nameLower .. '.png'
        end

        local ammoStr
        for _, k in ipairs({
            'ammoname', 'ammoName', 'ammotype', 'ammoType', 'ammunition',
        }) do
            local v = row[k]
            if type(v) == 'string' and v ~= '' then
                ammoStr = v:lower()
                break
            end
        end
        row.ammoname = ammoStr
    end)

    if not ok then
        if cLog then
            cLog('eCore:normalizeRegisteredItemDef', { name = nameLower, err = tostring(err) }, 1)
        end
        row.name = nameLower
        row[wKey] = tonumber(row[wKey]) or tonumber(row.weight) or 0
        row.label = (type(row.label) == 'string' and row.label ~= '') and row.label or nameLower
        row.isUnique = row.isUnique == true
        row.isWeapon = row.isWeapon == true
        row.image = (type(row.image) == 'string' and row.image ~= '') and row.image or (nameLower .. '.png')
        row.ammoname = (type(row.ammoname) == 'string' and row.ammoname ~= '') and row.ammoname:lower() or nil
    end

    return row
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
    if needs and type(t) == 'table' and next(t) then
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

function hf.deepCopy(orig, copies)
    copies = copies or {}

    if type(orig) ~= 'table' then
        return orig
    elseif copies[orig] then
        return copies[orig] -- körkörös hivatkozás esetén visszatérés
    end

    local copy = {}
    copies[orig] = copy

    for k, v in next, orig, nil do
        copy[hf.deepCopy(k, copies)] = hf.deepCopy(v, copies)
    end

    setmetatable(copy, hf.deepCopy(getmetatable(orig), copies))

    return copy
end


function hf.rangeLimit(v, max)
    return v < 0 and 0 or v > max and max or v
end

function hf.draw(chance)
    chance = tonumber(chance) or 100
    if chance < 1 then return false end
    if chance >= 100 then return true end
    return math.random(100) <= chance
end

function hf.stringSplit(input, sep)
    sep = sep or "%s"
    local t = {}
    for str in input:gmatch("([^" .. sep .. "]+)") do
        t[#t + 1] = str
    end
    return t
end

function hf.getKeys(t)
    local keys = {}
    for key in pairs(t) do
        keys[#keys + 1] = key
    end
    return keys
end

function hf.removeNonAlphaNumeric(inputString)
    if type(inputString) ~= "string" or inputString == nil then
        return nil
    end
    return inputString:gsub("[^%w]", "")
end

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

--- Létező játékos forrás-e (szerver).
---@param src number
---@return boolean
function hf.isValidPlayerSource(src)
    if type(src) ~= 'number' or src < 1 then
        return false
    end
    local name = GetPlayerName(src)
    return name ~= nil and name ~= ''
end

--- Egyszerű rate limit játékos + kulcs szerint (szerver net eseményekhez).
---@param src number player source
---@param name string egyedi kulcs pl. eseménynév
---@param cooldownMs number
---@return boolean true ha mehet a hívás
function hf.netRateLimit(src, name, cooldownMs)
    if not hf.isValidPlayerSource(src) then
        return false
    end
    hf.__netRate = hf.__netRate or {}
    local k = tostring(src) .. '|' .. tostring(name)
    local now = GetGameTimer()
    local last = hf.__netRate[k] or 0
    if now - last < cooldownMs then
        return false
    end
    hf.__netRate[k] = now
    return true
end

--- Fills REGISTERED_ITEMS until eCore:getRegisteredItems() is non-empty or timeout.
--- Sets CORE_READY to true on success, false on timeout (nil while still waiting).
---@param logTag string cLog key (e.g. 'REGISTERED ITEMS')
---@return boolean success
function hf.awaitItemRegistryReady(logTag)
    local start = GetGameTimer()
    local timeout = GetConvarInt('e_core:items_ready_timeout_ms', 120000)
    if timeout < 30000 then
        timeout = 30000
    end
    if timeout > 600000 then
        timeout = 600000
    end
    local pollMs = GetConvarInt('e_core:items_ready_poll_ms', 1000)
    if pollMs < 200 then
        pollMs = 200
    end
    if pollMs > 5000 then
        pollMs = 5000
    end

    local nextLogAt = 15000
    local attempt = 0

    while not hf.isPopulatedTable(REGISTERED_ITEMS) do
        attempt = attempt + 1
        REGISTERED_ITEMS = eCore:getRegisteredItems()

        local elapsed = GetGameTimer() - start
        if elapsed >= timeout then
            CORE_READY = false
            cLog(logTag,
                ('TIMEOUT after %d ms (%d polls). Item registry still empty; increase convar e_core:items_ready_timeout_ms (max 600000) if inventory starts late.'):format(
                    elapsed, attempt), 1)
            return false
        end

        if elapsed >= nextLogAt then
            cLog(logTag,
                ('still waiting for item registry (elapsed %d ms, poll %d, timeout %d ms)'):format(elapsed, attempt, timeout),
                2)
            local step = elapsed < 30000 and 15000 or 45000
            nextLogAt = elapsed + step
        end

        Wait(pollMs)
    end

    CORE_READY = true
    return true
end

--- Melyik inventory override aktív (shared override config.lua flagok).
---@return string
function hf.inventoryIntegrationLabel()
    local parts = {}
    if rawget(_G, 'OX_INVENTORY') == true then
        parts[#parts + 1] = 'ox_inventory'
    end
    if rawget(_G, 'QS_INVENTORY') == true then
        parts[#parts + 1] = 'qs-inventory'
    end
    if rawget(_G, 'AVP_GRID_INVENTORY') == true then
        parts[#parts + 1] = 'avp_grid_inventory'
    end
    if #parts == 0 then
        return 'framework'
    end
    return table.concat(parts, '+')
end

--- Egy soros indulási összegzés: verzió, keretrendszer, inventory réteg, item registry állapot.
---@param side string `server` vagy `client`
function hf.logEcoreStartupSummary(side)
    local ver = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?'
    local fw = tostring(FRAMEWORK or 'none')
    local inv = hf.inventoryIntegrationLabel()
    local items = CORE_READY == true and 'ready' or (CORE_READY == false and 'timeout' or 'pending')
    print(('[^2e_core^7] [%s] v%s | framework=%s | inventory=%s | items=%s'):format(side, ver, fw, inv, items))
end

--- oxmysql **.await** hívások: `pcall` + `cLog` hiba esetén. Csak **szerver** szálon hívd (`MySQL` globál).
---@param tag string napló címke (pl. `loadMeta:identifier`)
---@param fn fun(): any
---@return boolean ok
---@return any result ha ok; hibaérték ha nem ok
function hf.mysqlAwait(tag, fn)
    if rawget(_G, 'MySQL') == nil then
        cLog(('[e_core][MySQL] %s: MySQL globális hiányzik (nem szerver szál?)'):format(tag), 'error', 1)
        return false, 'mysql_missing'
    end
    local ok, res = pcall(fn)
    if not ok then
        cLog(('[e_core][MySQL] %s: %s'):format(tag, tostring(res)), 'error', 1)
        return false, res
    end
    return true, res
end
