--- NUI → szerver bridge profession / level-profile adminhoz (`registry.ts` → `eCoreAdminApi`).
local pending = {}
local seq = 0

RegisterNetEvent('e_core:nuiAdminRpcResult', function(requestId, result)
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

RegisterNUICallback('eCoreAdminApi', function(data, cb)
    seq = seq + 1
    local requestId = ('%d-%d'):format(seq, GetGameTimer())
    local finished = false
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
end)
