--- NUI diagnostics admin RPC (`src/web/src/lib/diagnostics.ts` → `eCoreDiagnosticsApi`).
local pending = {}
local seq = 0

RegisterNetEvent('e_core:nuiDiagnosticsRpcResult', function(requestId, result)
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
end)

RegisterNUICallback('eCoreDiagnosticsApi', function(data, cb)
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
        timeout = SetTimeout(120000, function()
            if pending[requestId] then
                pending[requestId] = nil
                done({ ok = false, code = 'timeout', message = 'Diagnostics NUI RPC timeout (120s).' })
            end
        end),
    }

    TriggerServerEvent('e_core:nuiDiagnosticsRpc', requestId, type(data) == 'table' and data or {})
end)
