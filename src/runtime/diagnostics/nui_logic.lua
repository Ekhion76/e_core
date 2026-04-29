--- NUI -> server diagnostics admin bridge (`eCoreDiagnosticsApi`), guarded by `hf.webConsoleAccess`.
local hf = lib.require('src/imports/sdk/helper_base/shared')
local hfe = hfe
local diagnostics = lib.require('src/runtime/diagnostics/logic')

--- Auto-generated annotation. Refine behavior details if needed.
--- @param value any
--- @return any result
local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

--- Handles diagnostics NUI RPC request lifecycle and sends result payload.
--- @param src number Player source that initiated diagnostics RPC.
--- @param requestId string|number Request correlation id from client.
--- @param data table|nil Diagnostics RPC payload.
--- @return nil
local function onNuiDiagnosticsRpc(src, requestId, data)
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

    local okAccess, errAccess = hfe.webConsoleAccess(src)
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
        result = diagnostics.diagnosticsAdminListTests(authPayload)
    elseif action == 'listRuns' then
        result = diagnostics.diagnosticsAdminListRuns(authPayload)
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
            local runPayload = type(data) == 'table' and data or {}
            runPayload.auth = authPayload.auth
            runPayload.tests = tests
            runPayload.requestedBy = GetPlayerName(src) or 'player'
            result = diagnostics.diagnosticsAdminRun(runPayload)
        end
    elseif action == 'getRun' then
        result = diagnostics.diagnosticsAdminGetRun(trim(data.runId), authPayload)
    elseif action == 'cancelRun' then
        result = diagnostics.diagnosticsAdminCancelRun(trim(data.runId), authPayload)
    else
        result = {
            ok = false,
            code = eCoreErr.invalid_item_data,
            message = ('Ismeretlen diagnostics NUI action: %s'):format(action),
            data = {},
        }
    end

    TriggerClientEvent('e_core:nuiDiagnosticsRpcResult', src, requestId, result)
end

return {
    onNuiDiagnosticsRpc = onNuiDiagnosticsRpc,
}
