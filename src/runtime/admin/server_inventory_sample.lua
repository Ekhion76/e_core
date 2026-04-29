--- Admin NUI: raw inventory row samples for `Config.fields` mapping (bridge + optional ox_inventory).
--- Used by `nui_admin_bridge.lua` action `getInventorySamples`.
local hf = lib.require('src/imports/sdk/helper_base/shared')

--- @param t table
--- @return boolean
local function rowLooksLikeInventoryItem(t)
    if type(t) ~= 'table' then
        return false
    end
    local nm = t.name or t.item
    return type(nm) == 'string' and nm ~= ''
end

--- @param t table
--- @return number|nil
local function rowQuantity(t)
    local q = tonumber(t.count) or tonumber(t.amount) or tonumber(t.quantity)
    return q
end

--- Shallow / bounded deep copy for JSON (no functions, no userdata, cycle-safe).
--- @param value any
--- @param depth number
--- @param maxDepth number
--- @param seen table|nil
--- @return any
local function sanitiseForJson(value, depth, maxDepth, seen)
    depth = depth or 0
    maxDepth = maxDepth or 6
    seen = seen or {}
    local ty = type(value)
    if ty == 'nil' or ty == 'boolean' or ty == 'number' then
        return value
    end
    if ty == 'string' then
        if #value > 240 then
            return value:sub(1, 240) .. '…'
        end
        return value
    end
    if ty ~= 'table' then
        return tostring(value)
    end
    if depth >= maxDepth then
        return '<<max_depth>>'
    end
    if seen[value] then
        return '<<cycle>>'
    end
    seen[value] = true
    local out = {}
    local n = 0
    for k, v in pairs(value) do
        n = n + 1
        if n > 64 then
            out['_truncated'] = true
            break
        end
        local okKey = k
        if type(k) ~= 'string' and type(k) ~= 'number' then
            okKey = '__' .. tostring(k)
        end
        out[okKey] = sanitiseForJson(v, depth + 1, maxDepth, seen)
    end
    seen[value] = nil
    return out
end

--- @param inv table
--- @return string[]
local function topLevelKeysSample(inv)
    if type(inv) ~= 'table' then
        return {}
    end
    local keys = {}
    for k in pairs(inv) do
        if type(k) == 'string' then
            keys[#keys + 1] = k
        elseif type(k) == 'number' then
            keys[#keys + 1] = tostring(k)
        end
    end
    table.sort(keys)
    while #keys > 48 do
        table.remove(keys)
    end
    return keys
end

--- Collect up to `maxN` candidate item rows from a bridge-style inventory table.
--- @param inv table
--- @param maxN number
--- @return table[]
local function collectBridgeSamples(inv, maxN)
    maxN = maxN or 3
    local candidates = {}
    if type(inv) ~= 'table' then
        return candidates
    end
    local seen = {}
    --- @param t table
    local function add(t)
        if type(t) ~= 'table' or seen[t] or not rowLooksLikeInventoryItem(t) then
            return
        end
        seen[t] = true
        candidates[#candidates + 1] = t
    end

    for i = 1, #inv do
        add(inv[i])
        if #candidates >= maxN * 8 then
            break
        end
    end
    if #candidates < maxN * 4 then
        for _, v in pairs(inv) do
            add(v)
            if #candidates >= maxN * 8 then
                break
            end
        end
    end

    table.sort(candidates, function(a, b)
        local qa, qb = rowQuantity(a) or 0, rowQuantity(b) or 0
        local ap, bp = qa > 0, qb > 0
        if ap ~= bp then
            return ap
        end
        return tostring(a.name or a.item) < tostring(b.name or b.item)
    end)

    local out = {}
    for i = 1, math.min(maxN, #candidates) do
        out[i] = candidates[i]
    end
    return out
end

--- @param playerSrc number
--- @param maxN number
--- @return table[]
local function collectOxItemSamples(playerSrc, maxN)
    maxN = maxN or 3
    local out = {}
    if GetResourceState('ox_inventory') ~= 'started' then
        return out
    end
    local ok, inv = pcall(function()
        return exports.ox_inventory:GetInventory(playerSrc)
    end)
    if not ok or type(inv) ~= 'table' or type(inv.items) ~= 'table' then
        return out
    end
    local seen = {}
    for _, row in pairs(inv.items) do
        if type(row) == 'table' and rowLooksLikeInventoryItem(row) and not seen[row] then
            seen[row] = true
            out[#out + 1] = row
            if #out >= maxN * 6 then
                break
            end
        end
    end
    table.sort(out, function(a, b)
        local qa, qb = rowQuantity(a) or 0, rowQuantity(b) or 0
        return qa > qb
    end)
    while #out > maxN do
        table.remove(out)
    end
    return out
end

--- @param samples table[]
--- @return string[]
local function encodeSampleJson(samples)
    local lines = {}
    for i = 1, #samples do
        local safe = sanitiseForJson(samples[i], 0, 6, {})
        local ok, enc = pcall(json.encode, safe)
        lines[i] = ok and enc or ('{"encode_error":true,"detail":' .. json.encode(tostring(enc)) .. '}')
    end
    return lines
end

--- Build admin response: bridge `eCore:getInventory` samples + optional ox raw slots.
--- Used from `nui_admin_bridge` (`getInventorySamples` action). Sanitises nested tables for JSON (depth/entry limits).
--- @param adminSrc number NUI caller server id; used as default `targetSource` when payload omits it.
--- @param payload table|nil Optional fields: `targetSource` (number) — must be an online player id.
--- @return table Response `{ ok, code, message?, data? }` matching other admin NUI handlers (`eCoreErr` codes).
function adminNuiGetInventorySamples(adminSrc, payload)
    payload = type(payload) == 'table' and payload or {}
    if _ECORE_INIT_FAILED or type(eCore) ~= 'table' or type(eCore.getInventory) ~= 'function' then
        return {
            ok = false,
            code = eCoreErr.not_ready,
            message = 'e_core bridge nem elerheto (IDLE vagy getInventory hianyzik).',
        }
    end

    local target = tonumber(payload.targetSource)
    if not target then
        target = adminSrc
    end
    target = math.floor(target)
    if not hf.isValidPlayerSource(target) then
        return {
            ok = false,
            code = eCoreErr.invalid_player,
            message = 'Cel jatekos (targetSource) nem elerheto.',
        }
    end

    local okInv, invOrErr = pcall(function()
        return eCore:getInventory(target)
    end)
    if not okInv then
        return {
            ok = false,
            code = eCoreErr.unknown_error,
            message = ('getInventory pcall hiba: %s'):format(tostring(invOrErr)),
        }
    end

    local inv = invOrErr
    if type(inv) ~= 'table' then
        inv = {}
    end

    local bridgeSamples = collectBridgeSamples(inv, 3)
    local bridgeSanitised = {}
    for i = 1, #bridgeSamples do
        bridgeSanitised[i] = sanitiseForJson(bridgeSamples[i], 0, 6, {})
    end
    local bridgeJson = encodeSampleJson(bridgeSamples)

    local oxRows = collectOxItemSamples(target, 3)
    local oxSanitised = {}
    for i = 1, #oxRows do
        oxSanitised[i] = sanitiseForJson(oxRows[i], 0, 6, {})
    end
    local oxJson = encodeSampleJson(oxRows)

    local oxMeta
    if GetResourceState('ox_inventory') == 'started' then
        local okOx, oxInv = pcall(function()
            return exports.ox_inventory:GetInventory(target)
        end)
        if okOx and type(oxInv) == 'table' then
            oxMeta = {
                weight = oxInv.weight,
                maxWeight = oxInv.maxWeight,
                slots = oxInv.slots,
            }
        end
    end

    local hint =
    'Hasznald a minta kulcsokat az overrides/**/config.lua Config.fields mezoben (count vs amount vs quantity).'
    if #bridgeSamples == 0 and #oxRows == 0 then
        hint = hint .. ' Ures inventory vagy nem ismert sorforma — tegyel targyat a cel jatekos zsebebe.'
    end

    return {
        ok = true,
        code = eCoreErr.ok,
        message = hint,
        data = {
            framework = FRAMEWORK,
            ecoreInitFailed = _ECORE_INIT_FAILED == true,
            targetSource = target,
            bridge = {
                topLevelKeys = topLevelKeysSample(inv),
                rowEstimate = type(inv) == 'table' and (function()
                    local c = 0
                    for _ in pairs(inv) do
                        c = c + 1
                    end
                    return c
                end)() or 0,
                sampleCount = #bridgeSamples,
                samples = bridgeSanitised,
                sampleJson = bridgeJson,
            },
            oxInventory = {
                resourceStarted = GetResourceState('ox_inventory') == 'started',
                sampleCount = #oxRows,
                samples = oxSanitised,
                sampleJson = oxJson,
                inventoryMeta = oxMeta,
            },
        },
    }
end
