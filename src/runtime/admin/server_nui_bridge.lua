--- Profession / level-profile admin bridge from in-game NUI (`eCoreAdminApi` callback), guarded by `hf.webConsoleAccess`.
--- Replaces legacy `SetHttpHandler` / `Config.adminHttp` flow (no external HTTP endpoint).
local hf = hf
local hfe = hfe

--- Auto-generated annotation. Refine behavior details if needed.
--- @param value any
--- @return any result
local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

--- @param data table|nil
--- @return table response in `admin_response` format.
local function dispatchNuiAdmin(src, data)
    data = type(data) == 'table' and data or {}
    local action = trim(data.action)
    local payload = type(data.payload) == 'table' and data.payload or {}

    if action == 'listProfessions' then
        return professionAdminList()
    end

    if action == 'listLevelProfiles' then
        return levelProfileAdminList()
    end

    if action == 'getProfessionDefaults' then
        local category = trim(payload.category)
        local ok, dataOrErr = getProfessionDefaults(category)
        if not ok then
            return {
                ok = false,
                code = dataOrErr,
                message = 'Profession defaults lekeres sikertelen.',
            }
        end
        return {
            ok = true,
            code = eCoreErr.ok,
            message = 'Profession defaults lekerve.',
            data = {
                category = category,
                defaults = dataOrErr,
            },
        }
    end

    if action == 'validateProfessionKeys' then
        local category = trim(payload.category)
        local keys = {}
        if type(payload.keys) == 'table' then
            for _, key in ipairs(payload.keys) do
                local k = trim(key)
                if k ~= '' then
                    keys[#keys + 1] = k
                end
            end
        end
        local ok, dataOrErr = validateProfessionKeys(category, keys)
        if not ok then
            return {
                ok = false,
                code = dataOrErr,
                message = 'Profession key validacio sikertelen.',
            }
        end
        return {
            ok = true,
            code = eCoreErr.ok,
            message = 'Profession key validacio kesz.',
            data = dataOrErr,
        }
    end

    if action == 'getProfessionProfile' then
        local category = trim(payload.category)
        local name = trim(payload.name)
        local ok, dataOrErr = getProfessionLevelProfile(category, name)
        if not ok then
            return {
                ok = false,
                code = dataOrErr,
                message = 'Profession profile lekeres sikertelen.',
            }
        end
        return {
            ok = true,
            code = eCoreErr.ok,
            message = 'Profession profile lekerve.',
            data = {
                category = category,
                name = name,
                profile = dataOrErr,
            },
        }
    end

    if action == 'createProfession' then
        return professionAdminCreate(payload)
    end

    if action == 'updateProfession' then
        local category = trim(payload.category)
        local name = trim(payload.name)
        local body = type(payload.body) == 'table' and payload.body or {}
        return professionAdminUpdate(category, name, body)
    end

    if action == 'deleteProfession' then
        local category = trim(payload.category)
        local name = trim(payload.name)
        return professionAdminDelete(category, name)
    end

    if action == 'createLevelProfile' then
        return levelProfileAdminCreate(payload)
    end

    if action == 'updateLevelProfile' then
        local profileKey = trim(payload.profileKey)
        local body = type(payload.body) == 'table' and payload.body or {}
        return levelProfileAdminUpdate(profileKey, body)
    end

    if action == 'deleteLevelProfile' then
        local profileKey = trim(payload.profileKey)
        return levelProfileAdminDelete(profileKey)
    end

    if action == 'getInventorySamples' then
        return adminNuiGetInventorySamples(src, payload)
    end

    if action == 'getDeniedAuditConfig' then
        return e_core_get_denied_audit_admin_snapshot()
    end

    if action == 'listDeniedAudit' then
        local p = type(payload) == 'table' and payload or {}
        p.auth = { source = src }
        return adminDeniedAuditList(p)
    end

    if action == 'purgeDeniedAudit' then
        local p = type(payload) == 'table' and payload or {}
        p.auth = { source = src }
        return adminDeniedAuditPurge(p)
    end

    return {
        ok = false,
        code = eCoreErr.invalid_item_data,
        message = ('Ismeretlen NUI admin action: %s'):format(action),
    }
end

RegisterNetEvent('e_core:nuiAdminRpc', function(requestId, data)
    local src = source
    requestId = tostring(requestId or '')
    if requestId == '' then
        return
    end

    if not hf.netRateLimit(src, 'e_core:nuiAdminRpc', 250) then
        TriggerClientEvent(
            'e_core:nuiAdminRpcResult',
            src,
            requestId,
            { ok = false, code = eCoreErr.access_denied, message = 'Rate limit.' }
        )
        return
    end

    local okAccess, errAccess = hfe.webConsoleAccess(src)
    if not okAccess then
        TriggerClientEvent(
            'e_core:nuiAdminRpcResult',
            src,
            requestId,
            { ok = false, code = eCoreErr.access_denied, message = errAccess or 'Nincs jogosultság.' }
        )
        return
    end

    local result = dispatchNuiAdmin(src, data)
    TriggerClientEvent('e_core:nuiAdminRpcResult', src, requestId, result)
end)
