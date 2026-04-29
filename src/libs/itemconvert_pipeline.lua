--- Centralized item-convert pipeline with profile-based field mapping.
--- Purpose: keep inventory overrides thin and make diagnostics mandatory.
local hf = lib.require('src/imports/sdk/helper_base/shared')

hf.__itemConvertPipeline = hf.__itemConvertPipeline or {}

local pipeline = hf.__itemConvertPipeline
pipeline.profiles = pipeline.profiles or {}

local function toNonEmptyString(value)
    if type(value) == 'string' and value ~= '' then
        return value
    end
    if value == nil then
        return nil
    end
    local text = tostring(value)
    return text ~= '' and text or nil
end

local function callMapper(mapper, ...)
    if type(mapper) ~= 'function' then
        return nil
    end
    local ok, value = pcall(mapper, ...)
    if ok then
        return value
    end
    return nil
end

local function qbImageResolver(nameLower, rawName, data)
    local candidate = toNonEmptyString(rawName) or nameLower
    local qbItems = QBCore and QBCore.Shared and QBCore.Shared.Items
    local qbRow = qbItems and qbItems[candidate] or nil
    local image = qbRow and qbRow.image or nil
    if type(image) == 'string' and image:match('^.+%.%w+$') then
        return image
    end
    if type(data) == 'table' and type(data.image) == 'string' and data.image ~= '' then
        return data.image
    end
    return candidate .. '.png'
end

local defaultProfile = {
    source = 'default',
    getName = function(itemKey, data)
        return type(itemKey) == 'string' and itemKey or (type(data) == 'table' and data.name) or itemKey
    end,
    getLabel = function(nameLower, data, itemKey, rawName)
        if type(data) == 'table' and type(data.label) == 'string' and data.label ~= '' then
            return data.label
        end
        return toNonEmptyString(rawName) or toNonEmptyString(itemKey) or nameLower
    end,
    getWeight = function(_, data)
        return type(data) == 'table' and data.weight or nil
    end,
    isUnique = function(_, data)
        return type(data) == 'table' and data.unique == true
    end,
    isWeapon = function(_, data)
        if type(data) ~= 'table' then
            return false
        end
        return data.type == 'weapon' or data.weapon == true
    end,
    getImage = function(nameLower)
        return nameLower .. '.png'
    end,
    getAmmo = function(_, data)
        if type(data) ~= 'table' then
            return nil
        end
        return data.ammo or data.ammoname
    end,
}

pipeline.profiles.default = pipeline.profiles.default or defaultProfile
pipeline.profiles.esx = pipeline.profiles.esx or {
    source = 'esx',
    getName = function(itemKey, data)
        return type(itemKey) == 'string' and itemKey or (type(data) == 'table' and data.name) or itemKey
    end,
    getLabel = function(nameLower, data, itemKey, rawName)
        if type(data) == 'table' and type(data.label) == 'string' and data.label ~= '' then
            return data.label
        end
        return toNonEmptyString(rawName) or toNonEmptyString(itemKey) or nameLower
    end,
    getWeight = function(_, data)
        return type(data) == 'table' and data.weight or nil
    end,
    isUnique = function(_, data)
        return type(data) == 'table' and data.unique == true
    end,
    isWeapon = function(_, data)
        return type(data) == 'table' and data.type == 'weapon'
    end,
    getImage = function(nameLower)
        return nameLower .. '.png'
    end,
    getAmmo = function(_, data)
        return type(data) == 'table' and data.ammo or nil
    end,
}
pipeline.profiles.qb = pipeline.profiles.qb or {
    source = 'qb',
    getName = function(itemKey, data)
        return type(itemKey) == 'string' and itemKey or (type(data) == 'table' and data.name) or itemKey
    end,
    getLabel = function(nameLower, data, itemKey)
        if type(data) == 'table' and type(data.label) == 'string' and data.label ~= '' then
            return data.label:gsub("'", "\\'")
        end
        if type(data) == 'table' and type(data.name) == 'string' and data.name ~= '' then
            return data.name
        end
        return toNonEmptyString(itemKey) or nameLower
    end,
    getWeight = function(_, data)
        return type(data) == 'table' and data.weight or nil
    end,
    isUnique = function(_, data)
        return type(data) == 'table' and data.unique == true
    end,
    isWeapon = function(_, data)
        return type(data) == 'table' and data.type == 'weapon'
    end,
    getImage = function(nameLower, rawName, data)
        return qbImageResolver(nameLower, rawName, data)
    end,
    getAmmo = function(_, data)
        return type(data) == 'table' and data.ammo or nil
    end,
}
pipeline.profiles.ox = pipeline.profiles.ox or {
    source = 'ox',
    getName = function(itemKey)
        return itemKey
    end,
    getLabel = function(nameLower, data, itemKey)
        if type(data) == 'table' and type(data.label) == 'string' and data.label ~= '' then
            return data.label
        end
        return toNonEmptyString(itemKey) or nameLower
    end,
    getWeight = function(_, data)
        return type(data) == 'table' and data.weight or nil
    end,
    isUnique = function(_, data)
        return type(data) == 'table' and data.stack == false
    end,
    isWeapon = function(_, data)
        return type(data) == 'table' and data.weapon == true
    end,
    getImage = function(nameLower, rawName, data)
        if type(data) == 'table' and type(data.client) == 'table' and type(data.client.image) == 'string' then
            local m = string.match(data.client.image, "([^/]+%.[%w]+)")
            if m then
                return m
            end
        end
        return qbImageResolver(nameLower, rawName, data)
    end,
    getAmmo = function(_, data)
        return type(data) == 'table' and data.ammo or nil
    end,
}
pipeline.profiles.qs = pipeline.profiles.qs or {
    source = 'qs',
    getName = function(itemKey)
        return itemKey
    end,
    getLabel = function(nameLower, data, itemKey)
        if type(data) == 'table' and type(data.label) == 'string' and data.label ~= '' then
            return data.label
        end
        return toNonEmptyString(itemKey) or nameLower
    end,
    getWeight = function(_, data)
        return type(data) == 'table' and data.weight or nil
    end,
    isUnique = function(_, data)
        return type(data) == 'table' and data.unique == true
    end,
    isWeapon = function(nameLower, data)
        if type(data) ~= 'table' then
            return false
        end
        return not data.useable and string.find(nameLower, "^weapon_") ~= nil
    end,
    getImage = function(nameLower, rawName, data)
        return qbImageResolver(nameLower, rawName, data)
    end,
    getAmmo = function(_, data)
        return type(data) == 'table' and data.ammo or nil
    end,
}
pipeline.profiles.avp = pipeline.profiles.avp or {
    source = 'avp',
    getName = function(itemKey)
        return itemKey
    end,
    getLabel = function(nameLower, data, itemKey)
        if type(data) == 'table' and type(data.formatName) == 'string' and data.formatName ~= '' then
            return data.formatName
        end
        return toNonEmptyString(itemKey) or nameLower
    end,
    getWeight = function(_, data)
        return type(data) == 'table' and data.weight or nil
    end,
    isUnique = function(_, data)
        return type(data) == 'table' and not data.isStackable
    end,
    isWeapon = function(_, data)
        return type(data) == 'table' and data.isWeapon == true
    end,
    getImage = function(nameLower)
        return nameLower .. '.png'
    end,
    getAmmo = function(_, data)
        return type(data) == 'table' and data.weaponAmmoType or nil
    end,
}

--- Registers or updates one item-convert profile.
--- @param profileName string
--- @param profile table
--- @return boolean ok
--- @return string|nil reason
function hf.registerItemConvertProfile(profileName, profile)
    if type(profileName) ~= 'string' or profileName == '' then
        return false, 'invalid_profile_name'
    end
    if type(profile) ~= 'table' then
        return false, 'invalid_profile_table'
    end
    pipeline.profiles[profileName] = profile
    return true, nil
end

--- Warns once when an override keeps custom `eCore:convertItems`.
--- @param sourceTag string
function hf.itemConvertWarnCustomConvertItems(sourceTag)
    pipeline.warned = pipeline.warned or {}
    local key = tostring(sourceTag or 'itemconvert')
    if pipeline.warned[key] == true then
        return
    end
    local fn = type(eCore) == 'table' and eCore.convertItems or nil
    if type(fn) ~= 'function' then
        return
    end
    local info = debug and debug.getinfo and debug.getinfo(fn, 'S') or nil
    local src = info and tostring(info.source or '') or ''
    local isOverrideSource = src:find('/overrides/', 1, true) ~= nil or src:find('\\overrides\\', 1, true) ~= nil
    if not isOverrideSource then
        return
    end
    pipeline.warned[key] = true
    hf.cLog(
        ('[e_core][itemconvert] custom override convertItems detected (%s). Recommended migration: use hf.convertItemsWithProfile(...) in getRegisteredItems only.')
        :format(
            key
        ),
        'warning',
        1
    )
end

--- Converts an inventory item table through a profile-mapped pipeline.
--- Diagnostics and normalization always run in this flow.
--- @param items table|nil Raw inventory item map.
--- @param profileName string|nil Profile key (`esx`, `qb`, `ox`, `qs`, `avp`, ...).
--- @param options table|nil Optional `{ sourceTag, beforeEach, afterEach, debug }`.
--- @return table<string, {name: string, originalName: string, label: string, weight: number, isUnique: boolean, isWeapon: boolean, image: string, ammoname: string|nil, _source: string}>
function hf.convertItemsWithProfile(items, profileName, options)
    if not hf.hasEntries(items) then
        return {}
    end
    options = type(options) == 'table' and options or {}
    local profiles = pipeline.profiles or {}
    local selected = profiles[tostring(profileName or '')]
    local usingFallback = false
    if type(selected) ~= 'table' then
        selected = profiles.default or defaultProfile
        usingFallback = true
    end
    local sourceTag = tostring(options.sourceTag or (selected.source and (selected.source .. '.convertItems')) or
    'itemconvert')
    local sourceName = tostring(selected.source or profileName or 'default')
    local beforeEach = options.beforeEach
    local afterEach = options.afterEach
    local debugEnabled = options.debug == true

    local tmp = {}
    local rowCount = 0
    if hf.itemConvertDiagStartRun then
        for _ in pairs(items) do rowCount = rowCount + 1 end
        hf.itemConvertDiagStartRun(sourceTag, rowCount)
    end

    if usingFallback and hf.itemConvertDiagRecord then
        hf.itemConvertDiagRecord({
            source = sourceTag,
            code = 'unknown_profile_fallback',
            severity = 'warning',
            item = tostring(profileName or ''),
            reason = 'Unknown profile name, using default item-convert profile.',
        })
    end

    for item, data in pairs(items) do
        local okConv, errConv = pcall(function()
            if type(data) ~= 'table' then
                if hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = sourceTag,
                        code = 'invalid_item_row',
                        severity = 'warning',
                        item = tostring(item),
                        reason = ('Expected table row, got %s'):format(type(data)),
                    })
                end
                return
            end

            local raw = callMapper(selected.getName, item, data)
            raw = toNonEmptyString(raw)
            if raw == nil or raw == '' then
                if hf.itemConvertDiagRecord then
                    hf.itemConvertDiagRecord({
                        source = sourceTag,
                        code = 'invalid_item_key',
                        severity = 'warning',
                        item = tostring(item),
                        reason = 'Missing item key and profile.getName result',
                    })
                end
                return
            end

            local name = raw:lower()
            if tmp[name] ~= nil and hf.itemConvertDiagRecord then
                hf.itemConvertDiagRecord({
                    source = sourceTag,
                    code = 'duplicate_lower_key',
                    severity = 'warning',
                    item = name,
                    reason = ('Duplicate lower-case key during convert (raw key=%s)'):format(tostring(item)),
                })
            end

            if type(beforeEach) == 'function' then
                pcall(beforeEach, item, data, {
                    name = name,
                    originalName = raw,
                    sourceTag = sourceTag,
                    profileName = profileName,
                })
            end

            local row = {
                name = name,
                originalName = raw,
                label = callMapper(selected.getLabel, name, data, item, raw) or raw,
                weight = tonumber(callMapper(selected.getWeight, name, data, item, raw)) or 0,
                isUnique = callMapper(selected.isUnique, name, data, item, raw) == true,
                isWeapon = callMapper(selected.isWeapon, name, data, item, raw) == true,
                image = callMapper(selected.getImage, name, raw, data, item),
                ammoname = callMapper(selected.getAmmo, name, data, item, raw),
                _source = sourceName,
            }
            hfe.normalizeRegisteredItemDef(name, row, { source = sourceTag })
            tmp[name] = row

            if type(afterEach) == 'function' then
                pcall(afterEach, row, item, data, {
                    sourceTag = sourceTag,
                    profileName = profileName,
                })
            end

            if debugEnabled then
                hf.cLog(
                ('[e_core][itemconvert] converted %s via profile %s'):format(name, tostring(profileName or 'default')), 2)
            end
        end)
        if not okConv then
            hf.cLog(('eCore:convertItems(%s)'):format(sourceName), { err = tostring(errConv), item = tostring(item) }, 1)
            if hf.itemConvertDiagRecord then
                hf.itemConvertDiagRecord({
                    source = sourceTag,
                    code = 'convert_row_error',
                    severity = 'error',
                    item = tostring(item),
                    reason = tostring(errConv),
                })
            end
        end
    end

    if hf.itemConvertDiagFinishRun then
        hf.itemConvertDiagFinishRun()
    end
    return tmp
end
