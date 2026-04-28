--- NUI -> server bridge for profession / level-profile admin (`registry.ts` -> `eCoreAdminApi`).
local pending = {}
local seq = 0

--- Handles admin RPC result event and resolves pending callback.
--- @param requestId string|number
--- @param result table|nil
--- @return nil
local function onNuiAdminRpcResult(requestId, result)
    requestId = tostring(requestId or '')
    local entry = pending[requestId]
    if not entry then
        return
    end
    pending[requestId] = nil
    if entry.timeout then
        ClearTimeout(entry.timeout)
    end
    if entry.cb then
        entry.cb(result)
    end
end

--- Handles NUI admin API callback and forwards request to server RPC.
--- @param data table|nil
--- @param cb function
--- @return nil
local function onNuiAdminApi(data, cb)
    seq = seq + 1
    local requestId = ('%d-%d'):format(seq, GetGameTimer())
    local finished = false
    --- Auto-generated annotation. Refine behavior details if needed.
    --- @param payload table
    --- @return any result
    local function done(payload)
        if finished then
            return
        end
        finished = true
        cb(payload)
    end

    pending[requestId] = {
        cb = done,
        timeout = SetTimeout(60000, function()
            if pending[requestId] then
                pending[requestId] = nil
                done({ ok = false, code = 'timeout', message = 'NUI admin RPC timeout (60s).' })
            end
        end),
    }

    TriggerServerEvent('e_core:nuiAdminRpc', requestId, type(data) == 'table' and data or {})
end

return {
    onNuiAdminRpcResult = onNuiAdminRpcResult,
    onNuiAdminApi = onNuiAdminApi,
}
