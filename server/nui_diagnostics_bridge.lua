--- NUI -> server diagnostics admin bridge (`eCoreDiagnosticsApi`), guarded by `hf.webConsoleAccess`.
local hf = hf

--- Auto-generated annotation. Refine behavior details if needed.
--- @param value any
--- @return any result
local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

RegisterNetEvent('e_core:nuiDiagnosticsRpc', function(requestId, data)
    local src = source
    requestId = tostring(requestId or '')
    if requestId == '' then
        return
    end

    if not hf.netRateLimit(src, 'e_core:nuiDiagnosticsRpc', 200) then
        TriggerClientEvent(
            'e_core:nuiDiagnosticsRpcResult',
            src,
            requestId,
            { ok = false, code = eCoreErr.access_denied, message = 'Rate limit.' }
        )
        return
    end

    local okAccess, errAccess = hf.webConsoleAccess(src)
    if not okAccess then
        TriggerClientEvent(
            'e_core:nuiDiagnosticsRpcResult',
            src,
            requestId,
            { ok = false, code = eCoreErr.access_denied, message = errAccess or 'Nincs jogosultság.' }
        )
        return
    end

    data = type(data) == 'table' and data or {}
    local action = trim(data.action)
    local authPayload = { auth = { source = src } } --- admin exportok `auth.source`-t várnak
    local result

    if action == 'listTests' then
        result = diagnosticsAdminListTests(authPayload)
    elseif action == 'listRuns' then
        result = diagnosticsAdminListRuns(authPayload)
    elseif action == 'run' then
        local tests = data.tests
        if type(tests) ~= 'table' then
            result = {
                ok = false,
                code = eCoreErr.invalid_item_data,
                message = 'Hiányzó tests tömb.',
                data = {},
            }
        else
            result = diagnosticsAdminRun({
                auth = authPayload.auth,
                tests = tests,
                requestedBy = GetPlayerName(src) or 'player',
            })
        end
    elseif action == 'getRun' then
        result = diagnosticsAdminGetRun(trim(data.runId), authPayload)
    elseif action == 'cancelRun' then
        result = diagnosticsAdminCancelRun(trim(data.runId), authPayload)
    else
        result = {
            ok = false,
            code = eCoreErr.invalid_item_data,
            message = ('Ismeretlen diagnostics NUI action: %s'):format(action),
            data = {},
        }
    end

    TriggerClientEvent('e_core:nuiDiagnosticsRpcResult', src, requestId, result)
end)
